# make sure you're in the wwwroot folder of the published application
$JsFileContent = Get-Content -Path service-worker-assets.js -Raw
# remove JavaScript from contents so it can be interpreted as JSON
$Json = $JsFileContent.Replace("self.assetsManifest = ", "").Replace(";", "") | ConvertFrom-Json
# grab the assets JSON array
$Assets = $Json.assets
foreach ($Asset in $Assets) {
  $OldHash = $Asset.hash
  $Path = $Asset.url
  
  $Signature = Get-FileHash -Path $Path -Algorithm SHA256
  $SignatureBytes = [byte[]] -split ($Signature.Hash -replace '..', '0x$& ')
  $SignatureBase64 = [System.Convert]::ToBase64String($SignatureBytes)
  $NewHash = "sha256-$SignatureBase64"
  
  If ($OldHash -ne $NewHash) {
    Write-Host "Updating hash for $Path from $OldHash to $NewHash"
    # slashes are escaped in the js-file, but PowerShell unescapes them automatically,
    # we need to re-escape them
    $OldHash = $OldHash.Replace("/", "\/")
    $NewHash = $NewHash.Replace("/", "\/")
    $JsFileContent = $JsFileContent.Replace("""$OldHash""", """$NewHash""")
  }
}

Set-Content -Path service-worker-assets.js -Value $JsFileContent -NoNewline