{
  description = "The WASM package for prisma-fmt";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      with builtins;
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain;
        buildRustPackage = pkgs.rustPlatform.buildRustPackage;
        wasm-bindgen-cli = pkgs.wasm-bindgen-cli;
      in
      {
        defaultPackage = buildRustPackage {
          name = "prisma-fmt-wasm";
          src = ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
            outputHashes = {
              "datamodel-0.1.0" = builtins.readFile ./datamodel-0.1.0.sha256sum;
            };
          };

          buildPhase = ''
            PATH=${rust}/bin:${pkgs.nodejs}/bin:$PATH:${wasm-bindgen-cli}/bin
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
          checkPhase = "bash ${./check.sh}";
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
            program = "${pkgs.nodePackages.npm}/bin/npm";
          };
          wasm-bindgen = {
            type = "app";
            program = "${wasm-bindgen-cli}/bin/wasm-bindgen";
          };
          # TODO: Replace writeShellScriptBin with writeShellApplication once it's released.
          updateLocks = pkgs.writeShellScriptBin "updateLocks" ''
            export DATAMODEL_CHECKSUM_FILE=datamodel-0.1.0.sha256sum

            echo 'Syncing wasm-bindgen version in crate with that of the installed CLI...'
            sed -i "s/^wasm-bindgen\ =.*$/wasm-bindgen = \"=${wasm-bindgen-cli.version}\"/" Cargo.toml

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

            echo "Installing new datamodel checksum: $DATAMODEL_CHECKSUM"
            echo "$DATAMODEL_CHECKSUM" > $DATAMODEL_CHECKSUM_FILE
          '';
        };
      });
}
