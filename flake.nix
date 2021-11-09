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
        fakeSha256 = pkgs.lib.fakeSha256;
      in
      {
        defaultPackage = buildRustPackage {
          name = "prisma-fmt-wasm";
          src = ./.;

          buildInputs = [ pkgs.nodejs ];
          cargoLock = {
            lockFile = ./Cargo.lock;
            outputHashes = {
              "datamodel-0.1.0" = "sha256-x78DlMwedW0wfcBwBgDeUugYilCs1cxIMTtRBdFnAfg=";
            };
          };

          buildPhase = ''
            PATH=${rust}/bin:${pkgs.nodejs}/bin:$PATH

            cargo build --release --target=wasm32-unknown-unknown

            echo 'creating out dir...'
            mkdir -p $out/src;

            echo 'copying package.json...'
            cp ${./package.json} $out/package.json;

            echo 'generating node module...'
            RUST_BACKTRACE=1 ${wasm-bindgen-cli}/bin/wasm-bindgen \
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
        };
      });
}
