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
        inherit (pkgs) wasm-bindgen-cli rustPlatform nodejs coreutils jq;
        inherit (builtins) path readFile replaceStrings;
      in
      {
        packages.default = rustPlatform.buildRustPackage {
          name = "prisma-fmt-wasm";
          # https://nix.dev/anti-patterns/language#reproducibility-referencing-top-level-directory-with
          src = path { path = ./.; name = "prisma-fmt-wasm"; };

          cargoLock = {
            lockFile = ./Cargo.lock;
            outputHashes = { "datamodel-0.1.0" = readFile ./datamodel-0.1.0.sha256sum; };
          };

          nativeBuildInputs = [ rust wasm-bindgen-cli nodejs ];

          buildPhase = readFile ./scripts/build.sh;
          checkPhase = readFile ./scripts/check.sh;
          installPhase = "echo 'Install phase: skipped'";
        };

        packages = {
          updateNpmPackageVersion = pkgs.writeShellApplication {
            name = "updateNpmPackageVersion";
            runtimeInputs = [ jq ];
            text = readFile ./scripts/updateNpmPackageVersion.sh;
          };
          syncWasmBindgenVersions = let template = readFile ./scripts/syncWasmBindgenVersions.sh; in
            pkgs.writeShellApplication {
              name = "syncWasmBindgenVersions";
              runtimeInputs = [ coreutils ];
              text = replaceStrings [ "$WASM_BINDGEN_VERSION" ] [ wasm-bindgen-cli.version ] template;
            };
          updateLocks = pkgs.writeShellApplication {
            name = "updateLocks";
            runtimeInputs = [ rust coreutils ];
            text = readFile ./scripts/updateLocks.sh;
          };
        };
      });
}
