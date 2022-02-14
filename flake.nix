{
  description = "The WASM package for prisma-fmt";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        inherit (pkgs) wasm-bindgen-cli rustPlatform nodejs;
      in
      {
        defaultPackage = rustPlatform.buildRustPackage {
          name = "prisma-fmt-wasm";
          # https://nix.dev/anti-patterns/language#reproducibility-referencing-top-level-directory-with
          src = builtins.path { path = ./.; name = "prisma-fmt-wasm"; };

          cargoLock = {
            lockFile = ./Cargo.lock;
            outputHashes = {
              "datamodel-0.1.0" = builtins.readFile ./datamodel-0.1.0.sha256sum;
            };
          };

          nativeBuildInputs = [ rust wasm-bindgen-cli nodejs ];

          buildPhase = ''
            RUST_BACKTRACE=1

            cargo build --release --target=wasm32-unknown-unknown

            echo 'Creating out dir...'
            mkdir -p $out/src;

            echo 'Copying package.json...'
            cp ./package.json $out/;

            echo 'Copying README.md...'
            cp README.md $out/;

            echo 'Generating node module...'
            wasm-bindgen \
              --target nodejs \
              --out-dir $out/src \
              target/wasm32-unknown-unknown/release/prisma_fmt_build.wasm;
          '';
          checkPhase = "bash ./check.sh";
          installPhase = "echo 'Install phase: skipped'";
        };

        packages = {
          cargo = {
            type = "app";
            program = "${rust}/bin/cargo";
          };
          # Takes the new package version as first and only argument, and updates package.json
          updateNpmPackageVersion = pkgs.writeShellScriptBin "updateNpmPackageVersion" ''
            ${pkgs.jq}/bin/jq ".version = \"$1\"" package.json > /tmp/package.json
            rm package.json
            cp /tmp/package.json package.json
          '';
          npm = {
            type = "app";
            program = "${nodejs}/bin/npm";
          };
          wasm-bindgen = {
            type = "app";
            program = "${wasm-bindgen-cli}/bin/wasm-bindgen";
          };
          syncWasmBindgenVersions = pkgs.writeShellScriptBin "updateWasmBindgenVersion" ''
            echo 'Syncing wasm-bindgen version in crate with that of the installed CLI...'
            sed -i "s/^wasm-bindgen\ =.*$/wasm-bindgen = \"=${wasm-bindgen-cli.version}\"/" Cargo.toml
            cargo update --package wasm-bindgen
          '';
          # Updates:
          # - the wasm-bindgen version in Cargo.toml
          # - Cargo.lock
          # - datamodel-0.1.0.sha256sum
          updateLocks = pkgs.writeShellScriptBin "updateLocks" ''
            export DATAMODEL_CHECKSUM_FILE=datamodel-0.1.0.sha256sum

            nix run .#syncWasmBindgenVersions

            echo 'Running cargo update...'
            nix run .#cargo update

            if [[ $enginesHash != "" ]]; then
              nix run .#cargo update -p datamodel --precise $enginesHash
            fi

            echo 'Setting up fake checksum so the build can fail and output the new hash...'
            echo 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=' > \
              $DATAMODEL_CHECKSUM_FILE

            echo "Computing and inserting new datamodel checksum..."
            export DATAMODEL_CHECKSUM=`nix build 2>&1 1>&2 | awk '/got:/ {print $2}'`

            echo "Installing new datamodel checksum ($DATAMODEL_CHECKSUM)..."
            echo "$DATAMODEL_CHECKSUM" > $DATAMODEL_CHECKSUM_FILE
          '';
        };
      });
}
