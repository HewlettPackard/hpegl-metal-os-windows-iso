<!-- (C) Copyright 2024 Hewlett Packard Enterprise Development LP -->

# Requirements for Hosting BYOI files

This file will describe some of the requirements enforced for the web server hosting the final BYOI ISO file

## Secure Web Server

HPE Bare Metal requires the ISO file be hosted on an SSL-enabled web server (HTTPS). This web server's SSL
certificate must be issued by a common, public trusted Certificate Authority.

Starting with Bare Metal v0.24.143, this SSL certificate validation can be skipped for an individual file. This
can be useful for internal web servers that use either a self-signed, or private CA issued SSL certificate.
In the `files` section of the yml file, add `skip_ssl_verify: true` so the section looks like:
```
files:
- path: Win2019.iso
  file_size: 5787441152
  display_url: WindowsBYOI
  secure_url: https://www.company.com/dir/Win2019.iso
  skip_ssl_verify: true
  download_timeout: 3000
  signature: f1244db14f6c59ff8687a333cbb67d71f18234062baeea9e3d4a6c02d0d6dc93
  algorithm: sha256sum
  expand: false
```

## Accessibility

This web server must be accessible from the On-Prem controller. This web server can be internal in the
customer network or on the public internet (ex: AWS S3, Azure Blob Storage).

## Target webserver specification

This webserver URL prefix should be specified in `Config\Config.ps1` so the output yml file will contain the
correct `secure_url`. If you need to change the location the ISO should be downloaded from, you can modify the
`secure_url` line of the yml file without needing to rebuild the entire ISO.

## Further reading

Specific webserver configuration is beyond the scope of this document. Please see the vendor webserver
product documentation on how to create an SSL-enabled webserver to host your ISO file. Below is a
non-exhaustive list:
* Public Hosting
  * https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html
  * https://learn.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-portal
* Private Hosting
  * https://learn.microsoft.com/en-us/iis/manage/configuring-security/how-to-set-up-ssl-on-iis
  * https://httpd.apache.org/docs/2.4/ssl/ssl_howto.html
  * https://nginx.org/en/docs/http/configuring_https_servers.html
