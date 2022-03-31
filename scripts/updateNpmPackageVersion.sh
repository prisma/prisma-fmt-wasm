# Takes the new package version as first and only argument, and updates package.json
jq ".version = \"$1\"" package.json > /tmp/package.json
rm package.json
cp /tmp/package.json package.json
