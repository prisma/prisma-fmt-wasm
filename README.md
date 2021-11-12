# @prisma/prisma-fmt-wasm

This repository only contains the build logic. All the functionality is
implemented in [prisma-engines](https://github.com/prisma/prisma-engines/).

## Components

- The GitHub Actions workflow that is the reason for this repository: https://github.com/prisma/prisma-fmt-wasm/blob/main/.github/workflows/publish-prisma-fmt-wasm.yml
    - It is triggered from the https://github.com/prisma/engines-wrapper publish action.
- The [Rust source code](https://github.com/prisma/prisma-fmt-wasm/tree/main/src) for the wasm module
  - It's a very thin wrapper reexporting logic implemented in prisma-engines.
- The [nix build definition](https://github.com/prisma/prisma-fmt-wasm/blob/main/flake.nix)
    - It gives us a fully reproducible, thoroughly described build process and environment. The alternative would be a bash script with installs through `rustup`, `cargo install` and `apt`, with underspecified system dependencies and best-effort version pinning.
    - You can read more about nix on [nix.dev](https://nix.dev/) and the [official website](https://nixos.org/).
