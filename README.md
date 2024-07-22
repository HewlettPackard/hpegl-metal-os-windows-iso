<!-- (C) Copyright 2024 Hewlett Packard Enterprise Development LP -->

# Microsoft Windows Server Bring Your Own Image (BYOI) for HPE Private Cloud Enterprise - Bare Metal

# Table of contents
* [Overview](#overview)
* [Windows Licensing](#windows-licensing)
* [Building the Windows image](#building-the-windows-image)
  * [Setup PowerShell 7 and other tools](#setup-powershell-7-and-other-tools)
  * [Downloading recipe repo from GitHub](#downloading-recipe-repo-from-github)
  * [Downloading a Windows ISO file](#downloading-a-windows-iso-file)
  * [Building the Bare Metal Windows image and service](#building-the-bare-metal-windows-image-and-service)
* [Customizing the Windows image](#customizing-the-windows-image)
  * [Modifying the way the image is built](#modifying-the-way-the-image-is-built)
  * [Default GreenLakeAdmin account password](#default-greenlakeadmin-password)
  * [Modifying the Windows Autounattend XML file](#modifying-the-windows-autounattend-xml-file)
  * [Customizing installed Windows packages](#customizing-installed-windows-packages)
  * [Modifying the cloud-init](#modifying-the-cloud-init)
* [Using the Windows service/image](#using-the-windows-serviceimage)
  * [Adding Windows service to the HPE GreenLake for PCE - Bare Metal](#adding-windows-service-to-the-hpe-greenlake-for-pce---bare-metal)
  * [Creating a Windows Host with Windows Service](#creating-a-windows-host-with-windows-service)


# Overview

This GitHub repository contains the script files, template files, and documentation for creating
a Windows service for HPE Bare Metal from Windows install .ISO file.
By building a custom image via this process, you can control the exact version of Windows that is
used and modify how Windows is installed via an Autounattend file. Once the build is done,
you can add your new service to the HPE Bare Metal Portal and deploy a host with that new image.

Default parameters, such as Windows 2019 and 2022 source ISO locations and target web server information
are specified in `Config\Config.ps1`. You should edit this file for your own environment.

# Windows Licensing

> [!NOTE]
> The default configuration will create an image using an evaluation version of Windows Server.
> These editions of Microsoft Windows will operate in evaluation mode for 90 days.  
> To use this Windows after the evaluation period, you must register for a Microsoft product license.

Before you begin, check to see that you have the correct evaluation 
License for the evaluation images.  If you aren't using an evaluation
Image, make sure that your license keys and your install media are 
correct.  License keys may not always work between different versions
of install media.  Should you need to change this, modify the corresponding
Autounattend-XXXX.yml file (where the XXXX is the version of the Server you wish
to modify) and change the License Key to that which suits your needs. You will 
find this file in the downloaded files from GitHub, which are referenced later
in this document.

# Building the Windows image
These are the high-level steps required to generate the Windows service:
* Get a Microsoft Windows Desktop and/or Server with 250GB of free disk space for the build
* Install PowerShell 7 or later
* Install the Microsoft Windows Assessment and Deployment Kit (Windows ADK)
* Install the Microsoft Windows Add-on (Windows ADK-PE)
* Install Git (Version Control tool)
* Set up a local file transfer/storage tool (E.g. Local Web Server with HTTPS support) that Bare Metal can reach over the network.
  * See [Hosting](Hosting.md) file for additional requirements on the web server.
* Downloading recipe repo from GitHub
* Downloading a Windows .ISO file (or letting the script download an eval version)
* Build the Bare Metal Windows image/service
 
> [!NOTE]
> * For Windows ADK and PE, please refer to https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install. ADK and PE is to assess the quality and performance of systems or components.
> * For PowerShell 7 or later, please refer to https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4.
> * For Git, please refer to https://git-scm.com/book/en/v2/Getting-Started-Installing-Git. For more information on it, go to https://gitforwindows.org.

These are the high-level steps required to use this built Bare Metal Windows service/image on Bare Metal:
* Copy the built Bare Metal Windows .ISO image to your web server.
* Add the Bare Metal Windows .YML service file to the appropriate HPE Bare Metal portal.
* Create a Bare Metal host using this OS image service.

## Setup PowerShell 7 and other tools

These instructions are designed to run on a Windows System with PowerShell 7
or later, and have been developed and tested on Windows 10 and 11, and should
work on other Windows systems that ADK, and ADK-PE will install. To get this
working, the following is needed:

* PowerShell 7 or later
* Windows ADK
* Windows ADK-PE

The Windows host must have enough free file system space so that images can
be easily generated,  (50-100GB).

The resulting Windows .ISO image file from the build needs to be uploaded
to a web server that the HPE Bare Metal On-Premises Controller can access
over the network.  More about this later.

The environment will need the Windows ADK and ADK-PE. There are several options
that may be useful for your future images in this package, so selecting those
packages may be helpful for those tasks, however, the default selections should
work fine (at the time of this writing).  


## Downloading recipe repo from GitHub

Download this recipe from GitHub for building HPE Bare Metal Windows by:

```
git clone https://github.com/HewlettPackard/hpegl-metal-os-windows-iso.git
```

## Downloading a Windows .ISO file

Currently, Server 2019 and Server 2022 are supported for this image,
and while you can download and use the Evaluation versions of each, you
may have to add additional drivers for additional hardware support, especially
after support may end from the older images. See the `Modules\Drivers.ps1` file
for adding more drivers for either the Boot or Install image.

This Windows test is working for the latest release of Windows Server 2019 and
Windows Server 2022, as of the time of this writing: 2024-05-04

## Building the Bare Metal Windows image and service

At this point, you should have a Windows Desktop installed with:
* Windows ADK installed
* Oscdimg installed
* a copy of this repo
* a standard Windows Full .ISO file

We are almost ready to do the build, but we need to know something
about your environment.  When the build is done, it will generate two
files:
* a Bare Metal modified Windows .ISO file that needs to be hosted on a web
  server.  It is assumed that you have (or can set up) a local web
  server that Bare Metal can reach over the network.  You will also need
  login credentials on this web server so that you can upload files.
* a Bare Metal service .YML file that will be used to add the Windows service to
  the HPE Bare Metal portal.  This .YML file will have a URL to the Bare Metal modified Windows
  .ISO file on the web server.

The build needs to know what URL can be used to download the
Bare Metal modified Windows .ISO file. We assume that the URL can be broken into
2 parts: \<image-url-prefix\>/\<baremetal-custom-windows-iso\>

If the image URL cannot be constructed with this simple mechanism
then you probably need to customize this script for a more complex URL
construction.

First and foremost, 'Get-Help .\Main.ps1 -Detailed', which will print the instructions for all the parameters
available to the program, which produces this output:

```
NAME
    .\Main.ps1

SYNOPSIS
    Script to create a Windows image for Bare Metal deployments


SYNTAX
    .\Main.ps1 [-WindowsServerVersion] <String> [-Unattended]
    [[-AdministratorPassword] <SecureString>] [[-PortalUserName] <String>] [[-PortalPassword] <SecureString>]
    [[-BootIndex] <String>] [[-InstallIndex] <String>] [<CommonParameters>]


DESCRIPTION


PARAMETERS
    -WindowsServerVersion <String>
        Windows Server Version. Supported values are 2019 or 2022.

    -Unattended [<SwitchParameter>]
        Run in unattended mode. Rebuild ISO and Upload without prompting.
        Make sure you supply both remaining command-line parameters as well as proper settings in Config\Config.ps1.

    -AdministratorPassword <SecureString>
        When running unattended, the password for the Administrator account to encode in Autounattend.xml
        This needs to be a SecureString format. You can generate SecureString from Plain Text by:
        $(ConvertTo-SecureString 'PlainTextPasswrd' -AsPlainText -Force)
        NOTE: This password is only availble during install. After first boot, when CloudBase-Init runs, the
              Administrator account is renamed to GreenLakeAdmin and the password is randomized

    -PortalUserName <String>
        User name for the Bare Metal portal to use for uploading the built service

    -PortalPassword <SecureString>
        When running unattended, the password for the Bare Metal portal user specified in PortalUserName
        This needs to be a SecureString format. You can generate SecureString from Plain Text by:
        $(ConvertTo-SecureString 'PlainTextPasswrd' -AsPlainText -Force)

    -BootIndex <String>
        Index number of Boot image to use. Overrides what is set in Config.ps1. This must match the Index number from
        the boot.wim of the source ISO that is the "Microsoft Windows Setup (amd64/x64)" entry, not the PXE entry.
        If left blank or $null, the script will prompt.

    -InstallIndex <String>
        Index number of Install image to use. Overrides what is set in Config.ps1. This must match the Index number from
        the install.wim of the source ISO that you want to install. If left blank or $null, the script will prompt.

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

    -------------------------- EXAMPLE 1 --------------------------

    PS > .\Main.ps1 -WindowsServerVersion 2019






    -------------------------- EXAMPLE 2 --------------------------

    PS > .\Main.ps1 -WindowsServerVersion 2022 -AdministratorPassword $(ConvertTo-SecureString 'PlainTextPassword'
    -AsPlainText -Force) -PortalUserName 'user@company.com' -PortalPassword $(ConvertTo-SecureString
    'PlainTextPassword' -AsPlainText -Force) -BootIndex 2 -InstallIndex 4 -Unattended






REMARKS
    To see the examples, type: "Get-Help .\Main.ps1 -Examples"
    For more information, type: "Get-Help .\Main.ps1 -Detailed"
    For technical information, type: "Get-Help .\Main.ps1 -Full"
```


At the end of the script run, it will output the following instructions for the next steps.  
Example:
```
+------------------------------------------------------------------------------+
| +------------------------------------------------------------------------+
| | Windows will operate in evaluation mode for 90 days.  To activate Windows, you will need to provide a valid product key.
| |
| | This build generated a new Bare Metal Windows service/image consisting of two files:
| | Win2019.iso
| | Win2019.yml
| |
| | To use this new service/image in HPE Bare Metal, follow these steps:
| | (1) Copy the new image file Win2019.iso to your web server so that it can be reached via: http://192.169.1.131/images/Win2019.iso
| | (2) Use the test program ".\Test.ps1" to test the image size and signature.
| | (3) Use the HPE Bare Metal Portal to create a new service using the
| |     new image.  Follow these steps:
| |     - Sign into the HPE GreenLake Central Bare Metal Portal.
| |     - Go to Dashboard.
| |     - Click on "HPE GreenLake for Private Cloud Enterprise - Manage your Private Cloud" tile
| |     - Select "Bare Metal" from "Private Cloud Services". This leads to Bare Metal service page
| |         - Click on the tab "OS/application Images"
| |         - Click on the button "Add OS/Application Image"
| |         - Upload Win2019.yml
| | (4) Create a Bare Metal host using this OS image service.
| +------------------------------------------------------------------------+
+------------------------------------------------------------------------------+
```

When a Windows host is created in the HPE Bare Metal portal, the Bare Metal On-Premises Controller
will pull down this Bare Metal modified Windows .ISO file. This may take a little bit of time
the first time that the On-Premises Controller downloads the ISO from the web server.

### Main.ps1 the main program

Main.ps1:
This is the top level program that will take a Windows install ISO and generate a Windows service.yml file
that can be imported as a Host imaging Service into the HPE Bare Metal Portal.

> [!NOTE]  
> The users of this program are expected to copy the
> \<baremetal-custom-windows-iso\> .iso file to your web server such that the file
> is available at this constructed URL:
> \<image-url-prefix\>/\<baremetal-custom-windows-iso\>

### Main.ps1 - Customize Windows.ISO for Bare Metal

This script will repack a Windows .ISO file for a Bare Metal Windows install service
that uses Virtual Media to get the installation started.

The following changes are being made to the Windows .ISO:
  1. The iso is mounted, and the correct WIM files are extracted 
  2. A target mount is created to then lay down the WIM files extracted previously.
  3. Changes are done on the target directory to remove the "press any
     key to continue prompt, to allow for unattended install"
  4. Drivers listed in Drivers.ps1 are added to their respective WIM files.
  5. The Target Wim and Iso are then unmounted.

# Customizing the Windows image

The Windows image/service can be customized by:
* Modifying the way the image is built
* Modifying the Windows autoinst file
* Modifying the cloud-init
* Adding in additional drivers in the Drivers.ps1 script

## Modifying the way the image is built
Here is a description of the files in this repo:

Filename     | Description
-------------| -----------
README.md | This documentation
Autounattend-2019.xml | Autounattend file that will be selected when you are building Windows Server 2019
Autounattend-2022.xml | Autounattend file that will be selected when you are building Windows Server 2022
Main.ps1 | Makes the necessary modifications to a new ISO, and then creates a YAML file for it to be used by Bare Metal.
Get-ADK.ps1 | A basic script to retrieve the Windows ADK and WinPE add-on packages
glm-cloudbaseinit-setup.ps1.template.dos | This is the cloud-init template file that Bare Metal will use to setup cloud-init to run on the 1st boot. This is where you can create more files in CloudBase-Init's LocalScripts directory to be executed after installation.
glm_finisher.ps1.template.dos | This is the Bare Metal finisher script that installs just before the final reboot.
glm-meta-data.template.dos | A go template file to be used for Bare Metal Consumption.
glm-network-config.template.dos | A go template file used to setup networking configuration for Bare Metal
glm-user-data.template.dos | A template file used to populate user date for Bare Metal. This is where you can specify more users to create and commands to run at the end of CloudBase-Init's execution.
Install-ADK.ps1 | A basic script to install ADK & ADK-PE
SetupComplete.cmd | A command that will run on the first official boot, installing things that need the complete OS to be installed. This is run before CloudBase-Init so users and networking is not set up yet
Test.ps1 | This is the PowerShell script to test that the uploaded ISO matches the definition


Feel free to modify these files to suit your specific needs.
General changes that you want to contribute back via a pull request are much appreciated.

## Default GreenLakeAdmin password

These scripts support one of two ways of securing the default GreenlakeAdmin account. This is the built-in Administrator account that has been renamed.

1. User defined password in the [user-data](glm-user-data.template.dos#L9) file.
   * This will enable a known password to be used for the GreenlakeAdmin account
   * This password should be set in clear text in the user-data file with the "passwd" property in the users section
   * This password must meet password complexity requirements of the Windows OS (default of minimum 10 characters with a mix of upper-case, lower-case, number, and symbol)
   * In addition, the CloudBase-Init configuration file must load [UserDataPlugin](glm-user-data.template.dos#L30) at some point after CreateUserPlugin but before LocalScriptPlugin
   * After the initial boot of Windows, and giving CloudBase-Init time to run, it will set this password and you will be able to use it to log in via RDP or Serial Console SAC
   * The CloudBase-Init LocalScripts will then set the CloudBase-Init service to Disabled so you can change that password post-deployment without CloudBase-Init setting it back to the defined value after reboot
1. Randomly generated password
   * If the password is not specified in the user-data file (or the password specified does not meet complexity requirements), then CloudBase-Init will set a random password for the GreenlakeAdmin user
   * With this setting, the UserDataPlugin is not needed
   * It is also not necessary to disable the CloudBase-Init service after initial boot, however there is no harm in keeping it disabled in this configuration

## Modifying the Windows Autounattend XML file

The Autounattend-XXXX.xml files are there to match whichever version of Windows you are trying to install. They share many things
between the two of them, but more importantly, the differences are only in the variants between the two which are incompatible.
This is also an excellent file to modify for features that are desirable, or to enhance the existing process to conform to things
your company may need.

## Customizing installed Windows packages
Changing the Windows image can be somewhat tricky.  There are several passes that are completed as the OS layers itself onto
the disk, so things may not be entirely available at specific passes, which complicates things further.  Typically, additions
are going to be made at the OOBE stage, around pass 7, but if you need things at the lower level (maybe at the disk partition level),
you may need to look for something in a much earlier pass.

Additional packages can also be added when cloud-init runs, which may be ideal for your needs.  At this stage, the network
should be established, as well as the operating system being fully installed.

If you want to add additional drivers to the initial Windows install, you can add them to `Modules\Drivers.ps1`. The default
configuration only installs the minimum drivers needed to install Windows with Ethernet networking.

## Modifying the cloud-init

This service uses cloud-init to customize the deployed image after a Windows Install.
The cloud-init template is saved in this repo as glm-cloud-init.template.  Customizations of this file are possible.

# Using the Windows service/image

## Adding Windows service to the HPE GreenLake for PCE - Bare Metal

When the build script completes successfully you will find the following
instructions there for how to add this image into your HPE Bare Metal
portal.  For example:

```
+------------------------------------------------------------------------------+
| +------------------------------------------------------------------------+
| | This build generated a new Bare Metal Windows service/image consisting of two files:
| | Win2019.iso
| | Win2019.yml
| |
| | The default Windows image will operate in evaluation mode for 90 days.
| | To activate Windows, you will need to provide a valid product key.
| |
| | To use this new service/image in HPE Bare Metal, follow these
| | steps:
| | (1) Copy the new image file Win2019.iso
| |     to your web server  so that it can be reached via:
| |     http://192.169.1.131/images/Win2019.iso
| | (2) Use a test program "Test.ps1" to test
| |     the image size and signature.
| | (3) Use the HPE Bare Metal Portal to create a new service using the
| |     new image.  Follow these steps:
| |     - Sign into the HPE GreenLake Central Bare Metal Portal.
| |     - Go to Dashboard.
| |     - Click on "HPE GreenLake for Private Cloud Enterprise – Manage your Private Cloud" tile
| |     - Select "Bare Metal" from "Private Cloud Services". This leads to Bare Metal service page
| |         - Click on the tab "OS/application Images"
| |         - Click on the button "Add OS/Application Image"
| |         - Upload Win2019.yml
| | (4) Create a Bare Metal host using this OS image service.
| +------------------------------------------------------------------------+
+------------------------------------------------------------------------------+
```

Follow the instructions as directed!

## Creating a Windows Host with Windows Service

> [!NOTE]
> Once an Operating System is added to Bare Metal and is used by a Compute Instance, it cannot be modified.
> If you need to make changes to an Operating System definition you must create a new Operating System
> definition that uses a different name. If you create a new Operating System definition, Compute Instances
> that use the old definition will be unaffected by the new definition.

### Host name requirements

Windows has limits on the length and contents of the Computer Name beyond what Bare Metal has.
Bare Metal uses the Host Name as the Computer Name. Verify that when naming the Host in Bare Metal,
the Name meets Windows requirements.
* No more than 15 characters
* Periods not allowed

See [Microsoft](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-computername) for a complete list.

### Triage of image deployment problems

The output of the Windows image will appear on the serial console, while it is being loaded.
Triage will usually happen with whatever did not complete correctly, as the Windows install
will typically stop at the error message directly.

### Login Credentials

This Bare Metal Windows recipe (by default) when deployed will:
* Rename the built-in Administrator account to GreenLakeAdmin
* The password for GreenLakeAdmin will be randomized
* The SSH Keys supplied in the Bare Metal Host creation are added to the GreenLakeAdmin
  user by the cloud-init file (see glm-user-data.template.dos).
* Install and Enable OpenSSHD
* Enable RDP
* install MPIO client
* install iSCSI client

To Set the GreenLakeAdmin user's password to something known:
* Log into the Windows Server using SSH and the key that matches what was configured for the Host
* Start "PowerShell.exe"
* Run the following commands
```
$Password = Read-Host -Prompt "Enter new password" -AsSecureString
$UserAccount = Get-LocalUser -Name "GreenLakeAdmin"
$UserAccount | Set-LocalUser -Password $Password
```

The implications of the default setup are:
* Access to the Windows server in both RDP as well as OpenSSH
* MPIO ability for remote storage products + expansion
* iSCSI for remote storage
* Access via SSH with shared secure keys supplied at boot

> [!NOTE]
> If you want to persist a known password after the built-in Administrator account is renamed
> to GreenlakeAdmin, you can modify `glm-user-data.template.dos` and add `passwd: <Your Clear Text Password>`
> to the `users` section under the appropriate user entry. However please note that password will be
> stored in clear text in the user-data file.

### Network Setup

Host network setup should happen automatically. To validate the installation,
you can validate the connectivity as your configured networks require.

### Storage Volume Support (iSCSI / FC)
If you add an iSCSI / Fibre Channel (FC) volume during the Bare Metal host creation,
it should show all the volumes under Windows Disk Management or diskpart.exe.

> [!NOTE]  
> Bare Metal does not automatically create a partition or filesystem on the storage volume.
> This needs to be set up manually by the user. You can do this via diskpart:
> ```
> DISKPART> list disk
> DISKPART> select disk #
> DISKPART> attributes disk clear readonly
> DISKPART> convert mbr
> DISKPART> create partition primary
> DISKPART> list volume
> DISKPART> select volume #
> DISKPART> format
> DISKPART> assign
> DISKPART> list volume
> ```

### Prometheus node_exporter

These instructions also add Prometheus node_exporter to the running system.
Node_exporter is needed for Bare Metal to collect telemetry information about
running Compute Instances for uptime calculation. If node_exporter is not running
on the Compute Instance, then Bare Metal will not be able to calculate uptime for it.
