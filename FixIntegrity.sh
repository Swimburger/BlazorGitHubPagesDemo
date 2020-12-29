#!/bin/bash
# make sure you're in the wwwroot folder of the published application
jsFile=$(<service-worker-assets.js)
# remove JavaScript from contents so it can be interpreted as JSON
json=$(echo "$jsFile" | sed "s/self.assetsManifest = //g" | sed "s/;//g")
# grab the assets JSON array
assets=$(echo "$json" | jq '.assets[]' -c)
for asset in $assets
do
  oldHash=$(echo "$asset" | jq '.hash')
  #remove leading and trailing quotes
  oldHash="${oldHash:1:-1}"
  path=$(echo "$asset" | jq '.url')
  #remove leading and trailing quotes
  path="${path:1:-1}"
  newHash="sha256-$(openssl dgst -sha256 -binary $path | openssl base64 -A)"
  
  if [ $oldHash != $newHash ]; then
    # escape slashes for json
    oldHash=$(echo "$oldHash" | sed 's;/;\\/;g')
    newHash=$(echo "$newHash" | sed 's;/;\\/;g')
    echo "Updating hash for $path from $oldHash to $newHash"
    # escape slashes second time for sed
    oldHash=$(echo "$oldHash" | sed 's;/;\\/;g')
    jsFile=$(echo -n "$jsFile" | sed "s;$oldHash;$newHash;g")
  fi
done

echo -n "$jsFile" > service-worker-assets.js