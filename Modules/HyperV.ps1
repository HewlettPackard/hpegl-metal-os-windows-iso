# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
function Start-TestVM {
    param (
        $CurrentPath,
        $WindowsServerVersion
    )
    # Create Hyper-V VM to test ISO
    New-VM -Name "Test" -Generation 2 -MemoryStartupBytes 2GB -NewVHDPath "$CurrentPath\Windows.vhdx" -NewVHDSizeBytes 40GB
    $DVD = Add-VMDvdDrive -VMName "Test" -Path "$CurrentPath\Win${WindowsServerVersion}.iso" -Passthru
    Set-VMFirmware -VMName "Test" -FirstBootDevice $DVD
    Set-VM -Name "Test" -AutomaticCheckpointsEnabled $false -CheckpointType Disabled
    Set-VMComPort -VMName "Test" -Path "\\.\pipe\test-com2" -Number 2
    Start-VM -Name "Test"
    Write-Host 'Starting VM. In another terminal, as Administrator, run "putty.exe -serial \\.\pipe\test-com2 -sercfg 115200" to attach to EMS console.'
    Read-Host -Prompt "Press Enter to destroy VM..."
    Stop-VM -Name "Test" -TurnOff -Force
    Remove-VM -Name "Test" -Force
    Remove-Item -Path "Windows.vhdx" -Force

}