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
            cp ${./package.json} $out/package.json;

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
            WASM_BINDGEN_CLI_VERSION=`nix run .#wasm-bindgen -- --version | awk '/wasm-bindgen/ {print $2}'`
            sed -i "s/^wasm-bindgen\ =.*$/wasm-bindgen = \"=$WASM_BINDGEN_CLI_VERSION\"/" Cargo.toml

            echo 'Running cargo update...'
            nix run .#cargo update

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
