# Updates:
# - Cargo.lock
# - datamodel-0.1.0.sha256sum
set -euxo pipefail
export DATAMODEL_CHECKSUM_FILE=datamodel-0.1.0.sha256sum

echo 'Running cargo update...'
cargo update

if [[ ${enginesHash:?} != "" ]]; then
  cargo update -p datamodel --precise "$enginesHash"
fi

echo 'Setting up fake checksum so the build can fail and output the new hash...'
echo 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=' > \
  $DATAMODEL_CHECKSUM_FILE

echo "Computing and inserting new datamodel checksum..."
DATAMODEL_CHECKSUM=$(nix build 2>&1 1>&2 | awk '/got:/ {print $2}')
export DATAMODEL_CHECKSUM

echo "Installing new datamodel checksum ($DATAMODEL_CHECKSUM)..."
echo "$DATAMODEL_CHECKSUM" > $DATAMODEL_CHECKSUM_FILE
