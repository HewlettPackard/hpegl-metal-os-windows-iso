# (C) Copyright 2024-2025 Hewlett Packard Enterprise Development LP

# This function will test the user-defined password from user-data to confirm if it
# meets default Windows password complexity requirements. These rules have been documented at:
# https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
function Test-Password {
  $Errors = @()
  $Password = $($(Select-String -Path .\glm-user-data.template.dos -Pattern 'passwd').Line).Split(" ")[-1]
  If (-Not($Password -cmatch '[a-z]')) {
    $Errors += "  Password does not contain at least one lower-case letter (a-z)."
  }
  If (-Not($Password -cmatch '[A-Z]')) {
    $Errors += "  Password does not contain at least one upper-case letter (A-Z)."
  }
  If (-Not($Password -match '\d')) {
    $Errors += "  Password does not contain at least one digit (0-9)."
  }
  If (-Not($Password -match '[!@#%\^&\$]')) {
    $Errors += "  Password does not contain at least one special symbol (!@#%^&$)."
  }
  If ($Password.Substring(0, [Math]::Min($Password.Length, 1)) -match '[!@#%\^&\$]') {
    $Errors += "  Password cannot start with a special symbol (!@#%^&$)."
  }
  If ($Password.Length -lt 8) {
    $Errors += "  Password is not at least 8 characters."
  }
  If ($Errors.Length -gt 0) {
    Write-Host "User-defined password is not complex enough. Please edit glm-user-data.template.dos and update the passwd line."
    Write-host "Please see the message(s) below:"
    $Errors
    Exit 1
  }
}

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
description: ${ServiceDescription} This requires portal version v0.24.116 or later. If running on an MR storage controller, the controller requires firmware version 52.26.3 or later.
timeout: 10000
approach: vmedia
assumed_boot_method: na
origin: Custom
no_switch_lag: true
files:
  - path: Win${WindowsServerVersion}.iso
    file_size: $IsoFileSize
    display_url: WindowsBYOI
    secure_url: ${IsoUrl}/Win${WindowsServerVersion}.iso
    download_timeout: 3000
    signature: $IsoHash
    algorithm: sha256sum
    expand: false
    skip_ssl_verify: false
info:
  - encoding: base64
    templating: go-text-template
    templating_input: hostdef-v4
    target: vmedia-floppy
    path: /Autounattend.xml
    contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/Autounattend.xml")))
  - encoding: base64
    templating: go-text-template
    templating_input: hostdef-v4
    target: vmedia-floppy
    path: /cloudbaseinit-setup.ps1
    contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm-cloudbaseinit-setup.ps1.template.dos")))
  - encoding: base64
    templating: go-text-template
    templating_input: hostdef-v4
    target: vmedia-floppy
    path: /windowsexporter-setup.ps1
    contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm-windowsexporter-setup.ps1.template.dos")))
  - encoding: base64
    templating: go-text-template
    templating_input: hostdef-v4
    target: vmedia-floppy
    path: /meta-data
    contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm-meta-data.template.dos")))
  - encoding: base64
    templating: go-text-template
    templating_input: hostdef-v4
    target: vmedia-floppy
    path: /network-config
    contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm-network-config.template.dos")))
  - encoding: base64
    templating: go-text-template
    templating_input: hostdef-v4
    target: vmedia-floppy
    path: /user-data
    contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm-user-data.template.dos")))
  - encoding: base64
    templating: go-text-template
    templating_input: hostdef-v4
    target: vmedia-floppy
    path: /SetupComplete.cmd
    contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/SetupComplete.cmd")))
  - encoding: base64
    templating: go-text-template
    templating_input: hostdef-v4
    target: vmedia-floppy
    path: /glm_finisher.ps1
    contents: $([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CurrentPath/glm_finisher.ps1.template.dos")))
user_defined_steps:
  imgprep_steps:
    - operation: Boot Service OS
      description: Powers on and boots machine into Service OS
    - operation: Set RAID AutoConfig
      description: Set RAID AutoConfig
      parameters:
        - name: AutoConfig Mode
          value: none
          description: 'AutoConfig mode for MR controllers, one of these values: none,
            JBOD. JBOD will present unconfigured drives to operating system. none will
            present only configured logical volumes to operating system.'
          type: String
project_use: true
hoster_use: true
"@

  return $ServiceYaml
}
