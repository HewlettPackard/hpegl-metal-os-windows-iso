# (C) Copyright 2024 Hewlett Packard Enterprise Development LP

# A simple powershell script to grab both ADK files needed for iso creation
# **Links provided by the URI may not exist in the future, as Microsoft changes their site**
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2243390" -OutFile "adksetup.exe"
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2243391" -OutFile "adkwinpesetup.exe"


