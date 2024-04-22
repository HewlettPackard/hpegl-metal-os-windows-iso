# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
function Mount-Images {
    param (
        $LofPath,
        $LofUrl,
        $ImagePath,
        $ImageUrl,
        $BootIndex,
        $InstallIndex,
        $WindowsServerVersion
    )

    Write-Progress -Activity "Edit ISO" -PercentComplete 1 -Status "Mounting Windows ISO"
    if (![System.IO.File]::Exists($ImagePath)) {
        Start-BitsTransfer -Source $ImageUrl -Destination $ImagePath -DisplayName "Downloading Windows ISO" -Description "$ImageUrl"
        $CleanupDownloads = $true
    }
    Mount-DiskImage -ImagePath $ImagePath
    $MountedPath = (Get-DiskImage -DevicePath (Get-DiskImage -ImagePath $ImagePath).DevicePath | Get-Volume).DriveLetter + ":\"
    Write-Progress -Activity "Edit ISO" -PercentComplete 10 -Status "Extracting Windows ISO (Est 3min)"
    Copy-Item -Path "$MountedPath" -Destination "iso_files" -Recurse -Force
    Dismount-DiskImage -DevicePath (Get-DiskImage -ImagePath $ImagePath).DevicePath
    if ($CleanupDownloads -eq $true) {
        Remove-Item $ImagePath
        $CleanupDownloads = $false
    }

    # Boot image should be "Microsoft Windows Setup (amd64)" and not "Microsoft Windows PE (amd64)"
    if ($null -eq $BootIndex) {
        Get-WindowsImage -ImagePath "iso_files\sources\boot.wim" | Format-Table -Property ImageIndex, ImageName | Out-Host
        $BootIndex = Read-Host "Enter ImageIndex number corresponding to the ""Microsoft Windows Setup (x64/amd64)"" image you want to modify"
    }
    # Make sure the /IMAGE/NAME and ProductKey you have in Autounattend.xml matches the edition you are modifying
    #  Or use /IMAGE/INDEX
    if ($null -eq $InstallIndex) {
        Get-WindowsImage -ImagePath "iso_files\sources\install.wim" | Format-Table -Property ImageIndex, ImageName | Out-Host
        $InstallIndex = Read-Host "Enter ImageIndex number corresponding to the edition you want to modify. Note: This must match the edition in your Autounattend.xml."
    }

    Write-Progress -Activity "Edit ISO" -PercentComplete 25 -Status "Mounting boot.wim"
    New-Item -Name "boot" -ItemType Directory
    # Need to remove the Read-Only attribute or Mount without -ReadOnly will fail
    Set-ItemProperty "iso_files\sources\boot.wim" -Name IsReadOnly -Value $false
    Mount-WindowsImage -ImagePath "iso_files\sources\boot.wim" -Path "boot" -Index $BootIndex

    Write-Progress -Activity "Edit ISO" -PercentComplete 30 -Status "Mounting install.wim"
    $InstallName = (Get-WindowsImage -ImagePath "iso_files\sources\install.wim" -Index $InstallIndex).ImageName
    $InstallDescription = (Get-WindowsImage -ImagePath "iso_files\sources\install.wim" -Index $InstallIndex).ImageDescription
    New-Item -Name "install" -ItemType Directory
    # Need to remove the Read-Only attribute or Mount without -ReadOnly will fail
    Set-ItemProperty "iso_files\sources\install.wim" -Name IsReadOnly -Value $false
    Mount-WindowsImage -ImagePath "iso_files\sources\install.wim" -Path "install" -Index $InstallIndex

    Write-Progress -Activity "Edit ISO" -PercentComplete 40 -Status "Extracting OpenSSH packages from LOF ISO"
    if (![System.IO.File]::Exists($LofPath)) {
        Start-BitsTransfer -Source $LofUrl -Destination $LofPath -DisplayName "Downloading LOF ISO" -Description "$LofUrl"
        $CleanupDownloads = $true
    }
    Mount-DiskImage -ImagePath $LofPath
    $MountedPath = (Get-DiskImage -DevicePath (Get-DiskImage -ImagePath $LofPath).DevicePath | Get-Volume).DriveLetter + ":\"
    switch ($WindowsServerVersion) {
        "2022" { 
            Export-WindowsCapabilitySource -Path install -Source "$MountedPath\LanguagesAndOptionalFeatures\" -Target 'iso_files\sources\$OEM$\$1\repository' -Name OpenSSH.Server~~~~0.0.1.0
        }
        "2019" { 
            Export-WindowsCapabilitySource -Path install -Source "$MountedPath\" -Target 'iso_files\sources\$OEM$\$1\repository' -Name OpenSSH.Server~~~~0.0.1.0
            Export-WindowsCapabilitySource -Path install -Source "$MountedPath\" -Target 'iso_files\sources\$OEM$\$1\repository' -Name OpenSSH.Client~~~~0.0.1.0
        }
    }
    Dismount-DiskImage -DevicePath (Get-DiskImage -ImagePath $LofPath).DevicePath
    if ($CleanupDownloads -eq $true) {
        Remove-Item $LofPath
        $CleanupDownloads = $false
    }

    $InstallDescription
    $InstallName
    $InstallIndex
}

function Dismount-Wims {
    param (
        $Apply
    )
    Write-Progress -Activity "Edit ISO" -PercentComplete 60 -Status "Dismounting install.wim"
    if ($Apply) {
        Dismount-WindowsImage -Path "install" -Save
    }
    else {
        Dismount-WindowsImage -Path "install" -Discard
    }
    Remove-Item "install" -Recurse -Force
    Write-Progress -Activity "Edit ISO" -PercentComplete 70 -Status "Dismounting boot.wim"
    if ($Apply) {
        Dismount-WindowsImage -Path "boot" -Save
    }
    else {
        Dismount-WindowsImage -Path "boot" -Discard
    }
    Remove-Item "boot" -Recurse -Force
}

function New-WindowsISO {
    param (
        $OscdimgPath,
        $CurrentPath,
        $IsoFileName
    )
    Write-Progress -Activity "Edit ISO" -PercentComplete 80 -Status "Repacking ISO (Est 3min)"
    # Removing the bootfix.bin and using efisys_noprompt.bin in remastering will remove the
    #  "Press Enter to boot CD/DVD..." message when booting the ISO
    Remove-Item -Path "iso_files\boot\bootfix.bin" -Force -Confirm:$false
    $OscdimgProcess = Start-Process -FilePath "$OscdimgPath\oscdimg.exe" `
        -NoNewWindow -PassThru -Wait `
        -ArgumentList "-m", "-o", "-u2", "-udfver102", `
        "-bootdata:2#p0,e,b""$OscdimgPath\etfsboot.com""#pEF,e,b""$OscdimgPath\efisys_noprompt.bin""", `
        "$CurrentPath\iso_files", "$CurrentPath\$IsoFileName"
    if ($OscdimgProcess.ExitCode -ne 0) {
        return
    }
    Write-Progress -Activity "Edit ISO" -PercentComplete 95 -Status "Cleaning up"
    # Need to use -Force because most of the files have Read-Only set
    Remove-Item "iso_files" -Recurse -Force
    Write-Progress -Activity "Edit ISO" -Completed
}

function New-WindowsService {
    param (
        $CurrentPath,
        $IsoFileName,
        $WindowsServerVersion,
        $IsoUrl,
        $ServiceName,
        $ServiceDescription
    )
    $IsoHash = (Get-FileHash -Path "$CurrentPath\$IsoFileName" -Algorithm SHA256).Hash.ToLower()
    $IsoFileSize = (Get-Item "$CurrentPath\$IsoFileName").Length
    New-ServiceYaml -IsoHash $IsoHash -IsoFileSize $IsoFileSize -IsoFileName $IsoFileName -CurrentPath $CurrentPath -WindowsServerVersion $WindowsServerVersion -IsoUrl $IsoUrl -ServiceName $ServiceName -ServiceDescription $ServiceDescription | Out-File -FilePath "$CurrentPath\Win${WindowsServerVersion}.yml"
    Remove-Item "Autounattend.xml" -Force
}
