#Query SunSystems 4.4 Client machine configuration

$globalConfFile = "$env:ProgramData\Infor\SunSystems\Security\Global.config"
$qaConfMdb      = "$env:ProgramData\Infor Query & Analysis\Settings\LsAgEg10.mdb"

#Ignore following settings - not used during Query
$DSN     = ""  #prefix host/tsn with asterix
$SUNDB   = ""  #Database for Sun
$VISIONDB= ""  #Database for Vision
$userID  = ""  #SQL User for Vision/Sun
$encPass = ""  #encrypted password for Vision/Sun

#initialize setting hashtable
$SS4dict = @{ "SS4:DSN"    = $DSN; "SS4:Database"    = $SUNDB; "SS4:UserID"    = $userID; "SS4:Password"    = $encPass;}
$QAdict =  @{ "Vision:DSN" = $DSN; "Vision:Database" = $VISIONDB; "Vision:UserID" = $userID; "Vision:Password" = $encPass;}

Try{
    #Jet OLEDB driver is 32bit and doesn't work from 64bit architecture
    if ($env:Processor_Architecture -ne "x86")   
    { 
        #not 32bit, relaunching current script in 32bit
        write-warning 'Launching x86 PowerShell'
        &"$env:windir\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" `
            -noninteractive -noprofile -file $myinvocation.Mycommand.path -executionpolicy bypass
        exit
    }
    #Always running in 32bit PowerShell at this point.
    $globalconf = [xml](gc $globalConfFile)
    write-host "Current Global Security Service Host: $($globalconf.configuration.security.connections.client.host)"
   
    #prepare ADO.NET objects
    $qry = @"
SELECT [Group], KeyID, DText 
FROM Register WHERE [Group]='AL_CON' 
AND [KeyID] IN ('$($SS4dict.Keys -Join "','")','$($QAdict.Keys -Join "','")')
"@

    $builder    = New-Object -TypeName System.Data.OleDb.OleDbConnectionStringBuilder
    $builder['Provider']    = "Microsoft.Jet.OLEDB.4.0"
    $builder['Data Source'] = $qaConfMdb #location of Q&A Settings
    $conn       = New-Object -TypeName System.Data.OleDb.OleDbConnection ($builder.ConnectionString)
    $qryCmd     = New-Object -TypeName System.Data.OleDb.OleDbCommand $qry
    $qryAdapter = New-Object -TypeName System.Data.OleDb.OleDbDataAdapter $qryCmd
    $dataset    = New-Object -TypeName System.Data.DataSet
    
    #qry Q&A Settings
    Write-Host -ForegroundColor Green "Current settings"
    $qryCmd.Connection = $conn
    $conn.Open()
    $qryAdapter.Fill($dataset) > $null #suppress rowcount
    $dataset.Tables[0]                 #return rst
    $conn.Close()
} Catch
{
    $_.Exception.Message
}
