#!/usr/bin/env bash

# Check that the build worked.

set -euo pipefail

echo -n '1. The final wasm file is not empty:'

EXPECTED_FINAL_WASM_FILE_PATH="$out/src/prisma_fmt_build_bg.wasm";
WASM_FILE_SIZE=`wc -c $EXPECTED_FINAL_WASM_FILE_PATH | sed 's/ .*$//'`

if [[ $WASM_FILE_SIZE == '0' ]]; then
    echo "Check phase failed: expected a non empty EXPECTED_FINAL_WASM_FILE_PAT"
    exit 1
fi

echo ' ok.'

# ~_~_~_~ #

echo '2. We can call the module directly and get back a valid result.'

VERSION_FROM_MODULE=`node -e "const prismaFmt = require('$out'); console.log(prismaFmt.version())"`

echo "VERSION_FROM_MODULE=$VERSION_FROM_MODULE"

if [[ $VERSION_FROM_MODULE != 'wasm' ]]; then
    echo "Check phase failed: expected the module version to be 'wasm', but got $VERSION_FROM_MODULE"
    exit 1
fi

echo ' ok.'
