#WINDOWS SERVER 2008 - Local Groups

#ref: http://stackoverflow.com/questions/17616816/changing-user-properties-in-powershell
$cn = [ADSI]"WinNT://$($env:ComputerName)"

# Generate a password with 2 non-alphanumeric character.
$Length = 10
$Assembly = Add-Type -AssemblyName System.Web

Write-Host -ForegroundColor Green "Creating SUServices Group.."
$grpSUServices = $cn.Create("group", "SUServices")
$grpSUServices.SetInfo()
$grpSUServices.description = "SystemsUnion Services"
$grpSUServices.SetInfo()

Write-Host -ForegroundColor Green "Creating SUClients Group.."
$grpSUClients = $cn.Create("group", "SUClients")
$grpSUClients.SetInfo()
$grpSUClients.description = "SystemsUnion Clients"
$grpSUClients.SetInfo()

Write-Host -ForegroundColor Green "Creating svcInforAdmin local user.."
$RandomComplexPassword = [System.Web.Security.Membership]::GeneratePassword($Length,2)
$usrInforAdmin = $cn.Create("User","svcInforAdmin")
$usrInforAdmin.SetPassword($RandomComplexPassword)
$usrInforAdmin.SetInfo()
Write-Host -ForegroundColor Red "svcInforAdmin Random password: "+$RandomComplexPassword
#this has to be done in two steps or will fail
$usrInforAdmin.description="Service Account for Sun Services"
$usrInforAdmin.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
$usrInforAdmin.SetInfo()

Write-Host -ForegroundColor Green "Creating svcSunBak local user.."
$RandomComplexPassword = [System.Web.Security.Membership]::GeneratePassword($Length,2)
$usrInforAdmin = $cn.Create("User","svcSunBak")
$usrInforAdmin.SetPassword($RandomComplexPassword)
Write-Host -ForegroundColor Red "svcSunBak Random password: "+$RandomComplexPassword
$usrInforAdmin.SetInfo()
#this has to be done in two steps or will fail
$usrInforAdmin.description="Service Account for Sun Backups"
$usrInforAdmin.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
$usrInforAdmin.SetInfo()

Write-Host -ForegroundColor Green "Adding svcInforAdmin local user to SUServices Group.."
$grpSUServices.Add("WinNT://$($env:ComputerName)/svcInforAdmin")

Write-Host -ForegroundColor Green "Adding svcSunBak local user to SUClients & Backup Operator Groups.."
$grpSUClients.Add("WinNT://$($env:ComputerName)/svcSunBak")
$grpBackupOps = [ADSI]"WinNT://$($env:ComputerName)/""Backup Operators"",group"
$grpBackupOps.Add("WinNT://$($env:ComputerName)/svcSunBak")

#opening firewall ports
Write-Host -ForegroundColor Green "Opening Firewall ports... "
& cmd /C "netsh advfirewall firewall add rule name=""SunSystems & ePay (1433, 55000, 9000, 9001)"" dir=in protocol=tcp localport=1433,55000,9000,9001 action=allow"
$wc = New-Object System.Net.WebClient

#download & run 7zip installer
Write-Host -ForegroundColor Green "Downloading 7zip installer script... "
$wc.DownloadFile("http://www.7-zip.org/a/7z920-x64.msi","$env:TEMP\7z.msi")

Write-Host -ForegroundColor Green "Running 7zip installer script in background... "
& "$env:TEMP\7z.msi" "/passive"

#download & run npp installer
Write-Host -ForegroundColor Green "Downloading npp installer... "
$wc.DownloadFile("https://notepad-plus-plus.org/repository/6.x/6.8.1/npp.6.8.1.Installer.exe","$env:TEMP\npp.exe")
Write-Host -ForegroundColor Green "Running interactive npp installer... "
& "$env:TEMP\npp.exe"

#delete downloaded files from temp folder
#del "$env:TEMP\7z.msi" "$env:TEMP\npp.exe"

Write-Host -ForeGround Green "Script finished."
Write-Host -ForeGround Red "Do not forget to give SUServices group rights to log on as a service, opening Local Security Policy managment now"

#it is possible to automate this on windows 2008, but only using a workaround which seems unstable, thus launching the console for manual configuration
& secpol.msc
