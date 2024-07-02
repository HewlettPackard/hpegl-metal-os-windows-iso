<#
.SYNOPSIS
    Script to create a Windows image for Bare Metal deployments
.NOTES
    (C) Copyright 2024 Hewlett Packard Enterprise Development LP
.PARAMETER WindowsServerVersion
    Windows Server Version. Supported values are 2019 or 2022.
.PARAMETER Unattended
    Run in unattended mode. Rebuild ISO and Upload without prompting.
    Make sure you supply both remaining command-line parameters as well as proper settings in Config\Config.ps1.
.PARAMETER AdministratorPassword
    When running unattended, the password for the Administrator account to encode in Autounattend.xml
    This needs to be a SecureString format. You can generate SecureString from Plain Text by:
    $(ConvertTo-SecureString 'PlainTextPasswrd' -AsPlainText -Force)
    NOTE: This password is only availble during install. After first boot, when CloudBase-Init runs, the
          Administrator account is renamed to GreenLakeAdmin and the password is randomized
.PARAMETER PortalUserName
    User name for the Bare Metal portal to use for uploading the built service
.PARAMETER PortalPassword
    When running unattended, the password for the Bare Metal portal user specified in PortalUserName
    This needs to be a SecureString format. You can generate SecureString from Plain Text by:
    $(ConvertTo-SecureString 'PlainTextPasswrd' -AsPlainText -Force)
.PARAMETER BootIndex
    Index number of Boot image to use. Overrides what is set in Config.ps1
.PARAMETER InstallIndex
    Index number of Install image to use. Overrides what is set in Config.ps1
.EXAMPLE
    .\Main.ps1 -WindowsServerVersion 2019
.EXAMPLE
    .\Main.ps1 -WindowsServerVersion 2022 -AdministratorPassword $(ConvertTo-SecureString 'PlainTextPassword' -AsPlainText -Force) -PortalUserName 'user@company.com' -PortalPassword $(ConvertTo-SecureString 'PlainTextPassword' -AsPlainText -Force) -BootIndex 2 -InstallIndex 4 -Unattended
#>


param (
    [Parameter(Mandatory = $true, HelpMessage = "Windows Server Version. Supported values are 2019 or 2022.")]
    [ValidateSet("2019", "2022")]
    [string]$WindowsServerVersion,

    [Parameter()]
    [switch]$Unattended,

    [Parameter()]
    [securestring]$AdministratorPassword,

    [Parameter()]
    [string]$PortalUserName,

    [Parameter()]
    [securestring]$PortalPassword,

    [Parameter()]
    [string]$BootIndex,

    [Parameter()]
    [string]$InstallIndex
)

# Mount-WindowsImage requires Administrator so make sure we run this script as such.
#Requires -RunAsAdministrator

if ($Unattended) {
    $ErrorActionPreference = 'Ignore'
}
else {
    # Ask to continue on error
    $ErrorActionPreference = "Inquire"
}

# Load Config
. .\Config\Config.ps1

# Load Modules
. .\Modules\Adk.ps1
. .\Modules\Drivers.ps1
. .\Modules\HyperV.ps1
. .\Modules\Images.ps1
. .\Modules\Transfer.ps1
. .\Modules\Yaml.ps1

# If we didn't get Index preferences on the command-line, use what is in Config
if ($null -eq $BootIndex) {
    $BootIndex = $global:config.BootIndex
}
if ($null -eq $InstallIndex) {
    $InstallIndex = $global:config.InstallIndex
}

# We don't want to store any default password in the repository.
# Ask for the password interactivly and store it in a secure manny within this script.
# Later, we will convert the secure credential to something that can be stored in the Autounattend.xml
# NOTE: This password is only used during install. Once CloudBase-Init runs and renames the Administrator
#       account to GreenLakeAdmin, the password is randomized and you need to use SSH to login.
if ($null -eq $AdministratorPassword) {
    $AdministratorCredentials = Get-Credential -Message "Default Administrator password will be base64 encoded in final Autounattend.xml" -User "Administrator"
}
else {
    $AdministratorCredentials = New-Object System.Management.Automation.PSCredential ("Administrator", $AdministratorPassword)
}


switch ($WindowsServerVersion) {
    "2022" { 
        $ImagePath = $global:config.Win22ImagePath
        $ImageUrl = $global:config.Win22ImageUrl
        $LofPath = $global:config.Win22LofPath
        $LofUrl = $global:config.Win22LofUrl
    }
    "2019" { 
        $ImagePath = $global:config.Win19ImagePath
        $ImageUrl = $global:config.Win19ImageUrl
        $LofPath = $global:config.Win10FodPath
        $LofUrl = $global:config.Win10FodUrl
    }
    Default {}
}

$CurrentPath = (Get-Location).Path
$ADKPath = Get-AdkPath
$OscdimgPath = "${ADKPath}Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
if (![System.IO.FIle]::Exists("$OscdimgPath\oscdimg.exe")) {
    Write-Error "oscdimg.exe not found. See Get-ADK.ps1 and Install-ADK.ps1."
}

$MountReturn = Mount-Images -LofPath $LofPath -LofUrl $LofUrl -ImagePath $ImagePath -ImageUrl $ImageUrl -BootIndex $BootIndex -InstallIndex $InstallIndex -WindowsServerVersion $WindowsServerVersion
# Get Index of install.wim that was selected
$InstallIndex = ($MountReturn)[-1]
# Get Name of image from install.wim that was selected - this will be used as the Metal Service Name
$InstallName = ($MountReturn)[-2]
$InstallDescription = ($MountReturn)[-3]

Write-Progress -Activity "Edit ISO" -PercentComplete 50 -Status "Modify files"

# Download utilities
New-Item -Name 'iso_files\sources\$OEM$\$1\downloads' -ItemType Directory -Force
Start-BitsTransfer -Description "CloudBase Setup" -Source "https://github.com/cloudbase/cloudbase-init/releases/download/1.1.4/CloudbaseInitSetup_1_1_4_x64.msi" -Destination 'iso_files\sources\$OEM$\$1\downloads\cloudbaseinitsetup.msi'
Start-BitsTransfer -Description "Prometheus Windows Node Exporter" -Source "https://github.com/prometheus-community/windows_exporter/releases/download/v0.25.1/windows_exporter-0.25.1-amd64.msi" -Destination 'iso_files\sources\$OEM$\$1\downloads\windowsexporter.msi'
$EncodedAdministratorPassword = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($(ConvertFrom-SecureString -SecureString $AdministratorCredentials.Password -AsPlainText) + "AdministratorPassword"))
(Get-Content "Autounattend-${WindowsServerVersion}.xml").Replace('INSTALLINDEX', $InstallIndex).Replace('ADMINISTRATORPASSWORD', $EncodedAdministratorPassword) | Set-Content "$CurrentPath\Autounattend.xml"
# Set the ISO to enable EMS
Write-Progress -Activity "Edit ISO" -PercentComplete 50 -Status "Enabling EMS"
bcdedit /store "iso_files\efi\microsoft\boot\bcd" /ems '{default}' on
bcdedit /store "iso_files\efi\microsoft\boot\bcd" /emssettings EMSPORT:2 EMSBAUDRATE:115200
bcdedit /store "iso_files\efi\microsoft\boot\bcd" /set '{bootmgr}' bootems yes
bcdedit /store "boot\Windows\Boot\DVD\EFI\BCD" /ems '{default}' on
bcdedit /store "boot\Windows\Boot\DVD\EFI\BCD" /emssettings EMSPORT:2 EMSBAUDRATE:115200
bcdedit /store "boot\Windows\Boot\DVD\EFI\BCD" /set '{bootmgr}' bootems yes
bcdedit /store "install\Windows\Boot\DVD\EFI\BCD" /ems '{default}' on
bcdedit /store "install\Windows\Boot\DVD\EFI\BCD" /emssettings EMSPORT:2 EMSBAUDRATE:115200
bcdedit /store "install\Windows\Boot\DVD\EFI\BCD" /set '{bootmgr}' bootems yes
# Add boot and install drivers
Add-BootDrivers -WindowsServerVersion ${WindowsServerVersion} -CurrentPath ${CurrentPath}
Add-InstallDrivers -WindowsServerVersion ${WindowsServerVersion} -CurrentPath ${CurrentPath}
# Make any other changes here before we start repacking the ISO


# All changes are done.
if (!$Unattended) {
    $Continue = Read-Host -Prompt "Rebuild ISO? [Y/N]"
    if ($Continue -ieq "N") {
        Dismount-Wims -Apply $false
        Remove-Item "iso_files" -Recurse -Force
        Remove-Item "Autounattend.xml" -Force
        Exit
    }
}

Dismount-Wims -Apply $true

New-WindowsISO -OscdimgPath $OscdimgPath -CurrentPath $CurrentPath -IsoFileName "Win${WindowsServerVersion}.iso"
New-WindowsService -CurrentPath $CurrentPath -IsoFileName "Win${WindowsServerVersion}.iso" -WindowsServerVersion $WindowsServerVersion -IsoUrl $Global:config.IsoUrl -ServiceName $InstallName -ServiceDescription $InstallDescription

if (!$Unattended) {
    $Continue = Read-Host -Prompt "Upload File? [Y/N]"
}
if ($Unattended -or $Continue -ieq "Y") {
    Send-File -FileName "$CurrentPath\Win${WindowsServerVersion}.iso" -HostIP $Global:config.SshIp -UserName $Global:config.SshUsername -DestinationPath $Global:config.RemotePath+"/Win${WindowsServerVersion}.iso" -TransferType $Global:config.TransferType
    Send-File -FileName "$CurrentPath\Win${WindowsServerVersion}.yml" -HostIP $Global:config.SshIp -UserName $Global:config.SshUsername -DestinationPath $Global:config.RemotePath+"/Win${WindowsServerVersion}.yml" -TransferType $Global:config.TransferType
    if ($null -eq $PortalUserName -or $null -eq $PortalPassword) {
        if (!$Unattended) {
            $Credentials = Get-Credential -Message "Metal Portal Credentials"
        }
    }
    else {
        $Credentials = New-Object System.Management.Automation.PSCredential ($PortalUserName, $PortalPassword)
    }
    if (!($null -eq $Credentials)) {
        Send-ToMetal -PortalUrl $Global:config.MetalPortal -UserName $Credentials.UserName -Password $Credentials.Password -Role $Global:config.MetalRole -Team $Global:config.MetalHoster -ResourceType "services" -YamlFile "$CurrentPath\Win${WindowsServerVersion}.yml" -WindowsServerVersion $WindowsServerVersion -ServiceName $InstallName
    }
}

if (!$Unattended) {
    $Continue = Read-Host -Prompt "Create VM? [Y/N]"
    if ($Continue -ieq "Y") {
        Start-TestVM -CurrentPath $CurrentPath -WindowsServerVersion ${WindowsServerVersion}
    }
}
