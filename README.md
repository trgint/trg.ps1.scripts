
## Prepare a fresh Win2k8 server for sun433 install
```Powershell
Set-ExecutionPolicy RemoteSigned
(New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/trgint/trg.ps1.scripts/master/PrepareWin2k8-SunInstall.ps1","PrepareWin2k8-SunInstall.ps1")

.\PrepareWin2k8-SunInstall.ps1
```

## Unattended MSSQL2k8 
```Powershell
$base_url = "https://raw.githubusercontent.com/trgint/trg.ps1.scripts/master"
$wc = (New-Object System.Net.WebClient)
$wc.DownloadFile("$base_url/MSSQLConf.ini","MSSQLConf.ini")
$wc.DownloadFile("$base_url/MSSQLInstall.ps1","MSSQLInstall.ps1")

.\MSSQLInstall.ps1
```
