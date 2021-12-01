# @prisma/prisma-fmt-wasm

[![Publish pipeline](https://github.com/prisma/prisma-fmt-wasm/actions/workflows/publish-prisma-fmt-wasm.yml/badge.svg)](https://github.com/prisma/prisma-fmt-wasm/actions/workflows/publish-prisma-fmt-wasm.yml)
[![npm package](https://img.shields.io/npm/v/@prisma/prisma-fmt-wasm/latest)](https://www.npmjs.com/package/@prisma/prisma-fmt-wasm)
[![install size](https://packagephobia.com/badge?p=@prisma/prisma-fmt-wasm)](https://packagephobia.com/result?p=@prisma/prisma-fmt-wasm)

This repository only contains build logic to package the `prisma-fmt` engine into a Node package as a WASM module. All the functionality is
implemented in [prisma-engines](https://github.com/prisma/prisma-engines/).

The published package is internal to Prisma. Its API will break without prior
warning.

## Example

```bash
node -e "const prismaFmt = require('@prisma/prisma-fmt-wasm'); console.log(prismaFmt.version())"
```

## Components

- The GitHub Actions workflow that is the reason for this repository: https://github.com/prisma/prisma-fmt-wasm/blob/main/.github/workflows/publish-prisma-fmt-wasm.yml
    - It is triggered from the https://github.com/prisma/engines-wrapper publish action.
- The [Rust source code](https://github.com/prisma/prisma-fmt-wasm/tree/main/src) for the wasm module
  - It's a very thin wrapper reexporting logic implemented in prisma-engines.
- The [nix build definition](https://github.com/prisma/prisma-fmt-wasm/blob/main/flake.nix)
    - It gives us a fully reproducible, thoroughly described build process and environment. The alternative would be a bash script with installs through `rustup`, `cargo install` and `apt`, with underspecified system dependencies and best-effort version pinning.
    - You can read more about nix on [nix.dev](https://nix.dev/) and the [official website](https://nixos.org/).
    - You can read more about `buildRustPackage` and how the prisma-engines dependency is pinned in [the nixpkgs docs](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md).
