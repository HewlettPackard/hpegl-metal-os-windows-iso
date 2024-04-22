# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
param (
    # URL to download service definition from
    [Parameter(Position = 0, Mandatory = $true)]
    [string]
    $DownloadUrl
)

$ErrorActionPreference = 'Stop'

if (!(Get-Module powershell-yaml -ListAvailable)) {
    Install-Module powershell-yaml -Force
}
Write-Progress -Activity "Verify Service" -Status "Downloading Service Definition" -PercentComplete 1
Start-BitsTransfer -Source $DownloadUrl -Destination "Service.yml"
Write-Progress -Activity "Verify Service" -Status "Parsing Service Definition" -PercentComplete 5
$ServiceUrl = $(Get-Content -Path "Service.yml" | ConvertFrom-Yaml).files.secure_url
$ServiceFile = $(Get-Content -Path "Service.yml" | ConvertFrom-Yaml).files.path
$ServiceSignature = $(Get-Content -Path "Service.yml" | ConvertFrom-Yaml).files.signature
$ServiceAlgorithm = $(Get-Content -Path "Service.yml" | ConvertFrom-Yaml).files.algorithm
$ServiceSize = $(Get-Content -Path "Service.yml" | ConvertFrom-Yaml).files.file_size
Write-Progress -Activity "Verify Service" -Status "Downloading Service ISO" -PercentComplete 10
Start-BitsTransfer -Description "Download Service File" -Source $ServiceUrl -Destination $ServiceFile
Write-Progress -Activity "Verify Service" -Status "Generating hash of downloaded ISO" -PercentComplete 70
switch ($ServiceAlgorithm) {
    "sha256sum" { 
        $IsoHash = (Get-FileHash -Path "$ServiceFile" -Algorithm SHA256).Hash.ToLower()
    }
    "sha512sum" {
        $IsoHash = (Get-FileHash -Path "$ServiceFile" -Algorithm SHA512).Hash.ToLower()
    }
}
Write-Progress -Activity "Verify Service" -Status "Validating information" -PercentComplete 90
$IsoFileSize = (Get-Item "$ServiceFile").Length
# Do comparison below
if ($ServiceSignature -ne $IsoHash) {
    Write-Error "Signatures don't match $ServiceSignature != $IsoHash"
}
else {
    Write-Host "Signatures match" -ForegroundColor Green
}
if ($ServiceSize -ne $IsoFileSize) {
    Write-Error "File sizes don't match $ServiceSize != $IsoFileSize"
}
else {
    Write-Host "File sizes match" -ForegroundColor Green
}
Write-Progress -Activity "Verify Service" -Status "Cleaning Up" -PercentComplete 99
# Clean up
Remove-Item "$ServiceFile" -Force
Remove-Item "Service.yml" -Force
Write-Progress -Activity "Verify Service" -Completed