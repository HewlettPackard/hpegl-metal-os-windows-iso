# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
function Get-AdkPath {
    # Getting the installation folder; we should have a registry key
    if (!(Test-Path -Path "HKLM:\Software\WOW6432Node\Microsoft\Windows Kits\Installed Roots")) {
        Write-Error "No kits found. See Get-ADK.ps1 and Install-ADK.ps1."
    }
    else {
        # actual installation folder detection
        $Props = Get-ItemProperty -Path "HKLM:\Software\WOW6432Node\Microsoft\Windows Kits\Installed Roots"
        $ADKPath = $Props.KitsRoot10
        if ($ADKPath -eq "") {
            Write-Error "ADK 10 not found. See Get-ADK.ps1 and Install-ADK.ps1."
        }
    }
    return $ADKPath
}

function Get-AdkVersion {
    $app = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object {
        $_.DisplayName -eq "Windows Assessment and Deployment Kit"
    }
    return $app.DisplayVersion
}