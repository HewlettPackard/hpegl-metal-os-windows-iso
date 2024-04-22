# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
function New-ServiceYaml {
  param (
    $IsoHash,
    $IsoFileSize,
    $CurrentPath,
    $WindowsServerVersion,
    $IsoUrl,
    $ServiceName,
    $ServiceDescription
  )
  $ServiceYaml = @"
name: ${ServiceName}
type: deploy
svc_category: windows
svc_flavor: windows
svc_ver: "${WindowsServerVersion}"
description: ${ServiceDescription}
timeout: 6000
approach: vmedia
assumed_boot: na
files:
- path: Win${WindowsServerVersion}.iso
  file_size: $IsoFileSize
  display_url: WindowsBYOI
  secure_url: ${IsoUrl}/Win${WindowsServerVersion}.iso
  download_timeout: 3000
  signature: $IsoHash
  algorithm: sha256sum
  expand: false
info:
- encoding: base64
  templating: go-text-template
  templating_input: hostdef-v3
  target: vmedia-floppy
  path: /Autounattend.xml
  contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/Autounattend.xml")))
- encoding: base64
  templating: go-text-template
  templating_input: hostdef-v3
  target: vmedia-floppy
  path: /cloudbaseinit-setup.ps1
  contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm-cloudbaseinit-setup.ps1.template.dos")))
- encoding: base64
  templating: go-text-template
  templating_input: hostdef-v3
  target: vmedia-floppy
  path: /windowsexporter-setup.ps1
  contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm-windowsexporter-setup.ps1.template.dos")))
- encoding: base64
  templating: go-text-template
  templating_input: hostdef-v3
  target: vmedia-floppy
  path: /meta-data
  contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm-meta-data.template.dos")))
- encoding: base64
  templating: go-text-template
  templating_input: hostdef-v3
  target: vmedia-floppy
  path: /network-config
  contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm-network-config.template.dos")))
- encoding: base64
  templating: go-text-template
  templating_input: hostdef-v3
  target: vmedia-floppy
  path: /user-data
  contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm-user-data.template.dos")))
- encoding: base64
  templating: go-text-template
  templating_input: hostdef-v3
  target: vmedia-floppy
  path: /SetupComplete.cmd
  contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/SetupComplete.cmd")))
- encoding: base64
  templating: go-text-template
  templating_input: hostdef-v3
  target: vmedia-floppy
  path: /glm_finisher.ps1
  contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm_finisher.ps1.template.dos")))
project_use: true
hoster_use: true
"@

  return $ServiceYaml
}