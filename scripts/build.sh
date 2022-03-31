set -euxo pipefail

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
