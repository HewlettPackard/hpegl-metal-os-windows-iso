# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
$DownloadsPath = (New-Object -ComObject Shell.Application).Namespace('shell:Downloads').Self.Path

$global:config = @{
    # If you already know the ImageIndex number of the image in boot.wim.
    # If not provided (or '$null'), it will prompt
    BootIndex      = $null
    # If you already know the ImageIndex number of the image in install.wim.
    # If not provided (or '$null'), it will prompt
    InstallIndex   = $null

    # Windows Server 2019 Eval from https://go.microsoft.com/fwlink/p/?LinkID=2195167&clcid=0x409&culture=en-us&country=US
    Win19ImageUrl  = 'https://go.microsoft.com/fwlink/p/?LinkID=2195167&clcid=0x409&culture=en-us&country=US'
    Win19ImagePath = $DownloadsPath + "\17763.3650.221105-1748.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
    # Windows 10 FOD from MSDN. Note, need the Windows 1809 FOD to match with the Windows Server 2019 build we are using
    Win10FodUrl    = 'https://d1xrzz3jml13a5.cloudfront.net/assets/windows/en_windows_10_features_on_demand_part_1_version_1809_updated_sept_2018_x64_dvd_a68fa301.iso?Expires=2027462400&Signature=gLkfJX6rgd59K23qetFj9p94CJyN3XJtjeoREiiVPcYF8QH1Oii0JEP7jT9~1SRJTjS-Ic2EoxB7hqBNBMiAjXp7~HIRXQZWfQbsBJOSf5iGayL6FsabNU1U9NjwTU2IuQCEB4vnBGeODPBfej-y9ffD7bmaiePB3Knkrcr~ZTGuKWUP5J9SIjYu7zc~RGcZvKCiaOy0bXcKP9pdvYpeMOXFWUyWVjt98gs8IyPQrYtWN8vZbRqm1FJGq0~kTV1y126FN6BP82Qx4UDkZD~nO~kKvTISczrBXibmWcOlSSVyn0RjplmVwRoqDKrlB9pfSTQ2Wt50twtCil-y48vPUw__&Key-Pair-Id=K27J47UY2Q7IFN'
    Win10FodPath   = $DownloadsPath + "\en_windows_10_features_on_demand_part_1_version_1809_updated_sept_2018_x64_dvd_a68fa301.iso"
    # Windows Server 2022 Eval From https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US
    Win22ImageUrl  = 'https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US'
    Win22ImagePath = $DownloadsPath + "\20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
    # Windows Server 2022 LOF From https://go.microsoft.com/fwlink/p/?linkid=2195333
    Win22LofUrl    = 'https://go.microsoft.com/fwlink/p/?linkid=2195333'
    Win22LofPath   = $DownloadsPath + "\20348.1.210507-1500.fe_release_amd64fre_SERVER_LOF_PACKAGES_OEM.iso"

    TransferType   = "SSH"
    # IP address of web server to transfer ISO to (via SSH)
    SshIp          = "192.168.1.1"
    # Username for SSH transfer
    SshUsername    = "user"
    # Path on SSH server or AWS bucket to copy files to
    RemotePath     = "/var/www/html/images"
    # Bucket name if using AWS
    S3BucketName   = "S3BucketName"
    # Url on web server that On-Prem Controller has access to for ISO
    IsoUrl         = "https://www.company.com/images"

    # Url of Metal Operator Portal
    MetalPortal    = "https://metal.us1.greenlake-hpe.com"
    # Hoster on Portal to add Service to
    MetalHoster    = "TestHoster"
    # Role that your Portal user has access to that can add a Service to the Hoster
    MetalRole      = "hoster_owner"
}
