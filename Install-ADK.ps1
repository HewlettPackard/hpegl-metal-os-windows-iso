# (C) Copyright 2024 Hewlett Packard Enterprise Development LP

Start-Process -FilePath ".\adksetup.exe" -ArgumentList "/quiet /norestart /features + /ceip off " -Wait -Verb RunAs
Start-Process -FilePath ".\adkwinpesetup.exe" -ArgumentList "/quiet /norestart /features + " -Wait -Verb RunAs
