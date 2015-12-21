### UNTESTED - test at own risk, pull requests welcome!
write-host "Installing SQL Server 2008 R2..."

#assuming Powershell 2
$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path
do {
  $sa_password = Read-host "Enter SA Password:" -AsSecureString
  $sa_password_confirm = Read-host "Confirm SA Password:" -AsSecureString
  $decrypted = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
  $decrypted_confirm = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password1))
  
  if ($sa_password.Length -lt 8) {
    Write-Host "Your password is less than 8 characters"
  } elseif ($decrypted -ne $decrypted_confirm) {
    Write-Host "Passwords do not match!"
  }
} while (($sa_password.Length -lt 8) -and ($decrypted -ne $decrypted_confirm))


# /QS    = Quiet, but show progress 
# /SAPWD = provide SA password
Start-Process E:\Setup.exe -Wait -NoNewWindow -ErrorAction Stop -ArgumentList `
  "/IACCEPTSQLSERVERLICENSETERMS /SAPWD=""$decrypted"" /ConfigurationFile=""$scriptRoot\MSSQLConf.ini"""
