# Updates the checksums for the datamodel crate in:
# - Cargo.lock
# - datamodel-0.1.0.sha256sum
set -euxo pipefail
export DATAMODEL_CHECKSUM_FILE=datamodel-0.1.0.sha256sum
CARGO_HOME=$(mktemp -d)
export CARGO_HOME

if [[ ${enginesHash:?} != "" ]]; then
  echo "Updating to enginesHash=${enginesHash:?}"
  cargo update -p datamodel --precise "$enginesHash"
else
  echo "/! \ ERROR /!\ No enginesHash was passed in for this script to update to."
  exit 1
fi

echo 'Setting up fake checksum so the build can fail and output the new hash...'
echo 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=' > \
  $DATAMODEL_CHECKSUM_FILE

echo "Computing and inserting new datamodel checksum..."
DATAMODEL_CHECKSUM=$(nix build 2>&1 1>&2 | awk '/got:/ {print $2}' || true)
export DATAMODEL_CHECKSUM

echo "Installing new datamodel checksum ($DATAMODEL_CHECKSUM)..."
echo "$DATAMODEL_CHECKSUM" > $DATAMODEL_CHECKSUM_FILE
