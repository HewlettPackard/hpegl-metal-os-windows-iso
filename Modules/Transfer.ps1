# (C) Copyright 2024 Hewlett Packard Enterprise Development LP

# Setting up a new PSSession using SSH requires PowerShell 6 or later. Test in PowerShell 7.4.1.
# This does require special instructions on the SSH Server:
#  https://learn.microsoft.com/en-us/powershell/scripting/learn/remoting/ssh-remoting-in-powershell?view=powershell-7.4
# #Requires -Version 7

function Send-File {
    param (
        $FileName,
        $HostIP,
        $UserName,
        $DestinationPath,
        $TransferType
    )

    switch ($TransferType) {
        "SSH" { 
            Write-Host "Sending via SSH"
            # NOTE: The PSSession method is a bit slower than spawning scp. Keeping the PSSession method commented here
            #       in case the build system doesn't have scp installed
            #$SshSession = New-PSSession -HostName $HostIP -UserName $UserName -SSHTransport -Subsystem "powershell"
            #Copy-Item -Path $FileName -Destination $DestinationPath -ToSession $SshSession -Force
            #Remove-PSSession -Session $SshSession
            scp "${FileName}" "${UserName}@${HostIP}:${DestinationPath}"
        }
        "AWS S3" {
            Write-Host "Sending via AWS S3"
            if (!(Get-Module AWS.Tools.S3 -ListAvailable)) {
                Install-Module -Name AWS.Tools.S3 -Force
            }
            Write-S3Object -BucketName $global:config.S3BucketName -Key $DestinationPath -File $FileName
        }
        "None" { Write-Host "Skipping transfer" }
        default { Write-Error "Unknown TransferType ${TransferType}" }
    }
}

function Send-ToMetal {
    param (
        $PortalUrl,
        $UserName,
        [SecureString]$Password,
        $Role,
        $Team,
        $ResourceType,
        $YamlFile,
        $ServiceName
    )
    .\qctl.exe login --portal $PortalUrl --user $UserName --password $(ConvertFrom-SecureString -SecureString $Password -AsPlainText) --membership $Team --role $Role
    .\qctl.exe $ResourceType delete --name $ServiceName
    .\qctl.exe $ResourceType create --file $YamlFile
}