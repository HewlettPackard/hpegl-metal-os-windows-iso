# (C) Copyright 2024-2025 Hewlett Packard Enterprise Development LP
function Add-BootDrivers {
    param (
        $WindowsServerVersion,
        $CurrentPath
    )
    New-Item -Path "${CurrentPath}\BootDrivers" -ItemType Directory
    switch ($WindowsServerVersion) {
        "2019" {
            Start-BitsTransfer -Description "Smart Array Controller Driver v1010.84.0.1012" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p406765183/v237277/cp058432.exe" -Destination "${CurrentPath}\BootDrivers\cp058432.exe"
            Start-BitsTransfer -Description "MR Controller Driver v7.726.1.0" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p479737679/v233677/cp057467.exe" -Destination "${CurrentPath}\BootDrivers\cp057467.exe"
        }
        "2022" {
            Start-BitsTransfer -Description "Smart Array Controller Driver v1010.84.0.1012" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p406765183/v237277/cp058432.exe" -Destination "${CurrentPath}\BootDrivers\cp058432.exe"
            Start-BitsTransfer -Description "MR Controller Driver v7.726.1.0" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p1778542052/v233679/cp057468.exe" -Destination "${CurrentPath}\BootDrivers\cp057468.exe"
        }
        "2025" {
            Start-BitsTransfer -Description "Smart Array Controller Driver v1016.4.0.1031(B)" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p406765183/v257669/cp064181.exe" -Destination "${CurrentPath}\BootDrivers\cp064181.exe"
            # There are currently no MR controller drivers to download for Windows Server 2025
        }
    }

    #Extract all files
    Get-ChildItem "${CurrentPath}\BootDrivers" -Filter *.exe |
    ForEach-Object {
        New-Item -Path "${CurrentPath}\BootDrivers\$($_.BaseName)" -ItemType Directory
        Expand-Archive -Path $_.FullName -DestinationPath "${CurrentPath}\BootDrivers\$($_.BaseName)\" -Force
    }
    Add-WindowsDriver -Path "${CurrentPath}\boot" -Driver "${CurrentPath}\BootDrivers" -Recurse -ForceUnsigned
    Remove-Item -Path "${CurrentPath}\BootDrivers" -Recurse -Force
}

function Add-InstallDrivers {
    param (
        $WindowsServerVersion,
        $CurrentPath
    )
    New-Item -Path "${CurrentPath}\InstallDrivers" -ItemType Directory
    switch ($WindowsServerVersion) {
        "2019" { 
            Start-BitsTransfer -Description "Smart Array Controller Driver v1010.84.0.1012" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p406765183/v237277/cp058432.exe" -Destination "${CurrentPath}\InstallDrivers\cp058432.exe"
            Start-BitsTransfer -Description "MR Controller Driver v7.726.1.0" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p479737679/v233677/cp057467.exe" -Destination "${CurrentPath}\InstallDrivers\cp057467.exe"
            Start-BitsTransfer -Description "QLogic Storport Driver v9.4.9.21" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p341655060/v237816/cp058500.exe" -Destination "${CurrentPath}\InstallDrivers\cp058500.exe"
            Start-BitsTransfer -Description "Emulex Storport Driver v14.2.537.0" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p430440408/v223772/cp055592.exe" -Destination "${CurrentPath}\InstallDrivers\cp055592.exe"
            Start-BitsTransfer -Description "iLO5 Channel Interface Driver v4.7.1.0" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p151621290/v222648/cp055143.exe" -Destination "${CurrentPath}\InstallDrivers\cp055143.exe"
        }
        "2022" {
            Start-BitsTransfer -Description "Smart Array Controller Driver v1010.84.0.1012" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p406765183/v237277/cp058432.exe" -Destination "${CurrentPath}\InstallDrivers\cp058432.exe"
            Start-BitsTransfer -Description "MR Controller Driver v7.726.1.0" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p1778542052/v233679/cp057468.exe" -Destination "${CurrentPath}\InstallDrivers\cp057468.exe"
        }
        "2025" {
            Start-BitsTransfer -Description "Smart Array Controller Driver v1016.4.0.1031(B)" -Source "https://downloads.hpe.com/pub/softlib2/software1/sc-windows/p406765183/v257669/cp064181.exe" -Destination "${CurrentPath}\BootDrivers\cp064181.exe"
            # There are currently no MR controller drivers to download for Windows Server 2025
        }
    }

    #Extract all files
    Get-ChildItem "${CurrentPath}\InstallDrivers" -Filter *.exe |
    ForEach-Object {
        New-Item -Path "${CurrentPath}\InstallDrivers\$($_.BaseName)" -ItemType Directory
        Expand-Archive -Path $_.FullName -DestinationPath "${CurrentPath}\InstallDrivers\$($_.BaseName)\" -Force
    }
    Add-WindowsDriver -Path "${CurrentPath}\install" -Driver "${CurrentPath}\InstallDrivers" -Recurse -ForceUnsigned
    Remove-Item -Path "${CurrentPath}\InstallDrivers" -Recurse -Force
}