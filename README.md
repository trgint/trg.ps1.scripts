
```Powershell
Set-ExecutionPolicy RemoteSigned
(New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/trgint/trg.ps1.scripts/master/PrepareWin2k8-SunInstall.ps1","PrepareWin2k8-SunInstall.ps1")

.\PrepareWin2k8-SunInstall.ps1
```

Refer to wiki articles for details of the scripts