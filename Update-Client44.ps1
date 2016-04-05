# Update SunSystems 4.4 Client machine
# Note: Use Query-Client44.ps1 on working client to get encrypted password for this script

$globalConfFile = "$env:ProgramData\Infor\SunSystems\Security\Global.config"
$qaConfMdb      = "$env:ProgramData\Infor Query & Analysis\Settings\LsAgEg10.mdb"

#New Settings to load:
$newHost = "MELSWSUN"   #host
$secPort = "55000"      #port
$DSN     = "*$newHost"  #prefix host/tsn with asterix
$SUNDB   = "SUNDB"      #Database for Sun
$VISIONDB= "VISION"     #Database for Vision

$userID  = "LAS"        #SQL User for Vision/Sun
$encPass = "KEKKIP"     #encrypted password for Vision/Sun

#initialize settings hashtable
$SS4dict = @{ "SS4:DSN"    = $DSN; "SS4:Database"    = $SUNDB; "SS4:UserID"    = $userID; "SS4:Password"    = $encPass; "SS5:Enabled" = $false}
$QAdict =  @{ "Vision:DSN" = $DSN; "Vision:Database" = $VISIONDB; "Vision:UserID" = $userID; "Vision:Password" = $encPass;}


Try{
    #Jet OLEDB driver is 32bit and doesn't work from 64bit architecture, we need to ensure we are running 32bit Powershell
    if ($env:Processor_Architecture -ne "x86")   
    { 
        #not 32bit, relaunching current script in 32bit
        write-warning 'Launching x86 PowerShell'
        & "$env:windir\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" `
            -noninteractive -noprofile -file $myinvocation.Mycommand.path -executionpolicy bypass
        exit
    }
    #Always running in 32bit PowerShell at this point.

    #make backup of config files - running script more than once will overwrite the backups!
    Copy-Item $globalConfFile "$globalConfFile.back"
    Copy-Item $qaConfMdb "$qaConfMdb.back"

    $globalconf = [xml](gc $globalConfFile)
    write-host "Current Global Security Service Host: $($globalconf.configuration.security.connections.client.host)"
    
    #amend host & port in config file
    $globalconf.configuration.security.connections.client.host = $newHost
    $globalconf.configuration.security.connections.client.port = $secPort
    $globalconf.Save($globalConfFile)
    
    #prepare ADO.NET objects
    $qry = @"
SELECT [Group], KeyID, DText 
FROM Register WHERE [Group]='AL_CON' 
AND [KeyID] IN ('$($SS4dict.Keys -Join "','")','$($QAdict.Keys -Join "','")')
"@

    $update = @"
UPDATE [Register] SET [Group] = ?, [KeyID] = ?, DText = ? WHERE [Group] = ? AND [KeyID] = ?
"@
    $builder    = New-Object -TypeName System.Data.OleDb.OleDbConnectionStringBuilder
    $builder['Provider']    = "Microsoft.Jet.OLEDB.4.0"
    $builder['Data Source'] = $qaConfMdb #location of Q&A Settings
    $conn       = New-Object -TypeName System.Data.OleDb.OleDbConnection ($builder.ConnectionString)
    $qryCmd     = New-Object -TypeName System.Data.OleDb.OleDbCommand $qry
    $qryAdapter = New-Object -TypeName System.Data.OleDb.OleDbDataAdapter $qryCmd
    $dataset    = New-Object -TypeName System.Data.DataSet
    $updateCmd  = New-Object -TypeName System.Data.OleDb.OleDbCommand -Args $update
    $updateCmd.Parameters.Add((New-Object -TypeName System.Data.OleDb.OleDbParameter -Args @("Group", [System.Data.OleDb.OleDbType]::VarWChar, 0))) > $null
    $updateCmd.Parameters.Add((New-Object -TypeName System.Data.OleDb.OleDbParameter -Args @("KeyID", [System.Data.OleDb.OleDbType]::VarWChar, 0))) > $null
    $updateCmd.Parameters.Add((New-Object -TypeName System.Data.OleDb.OleDbParameter -Args @("DText", [System.Data.OleDb.OleDbType]::LongVarWChar, 0))) > $null
    $updateCmd.Parameters.Add((New-Object -TypeName System.Data.OleDb.OleDbParameter -Args @("Original_Group", [System.Data.OleDb.OleDbType]::VarWChar, 0))) > $null
    $updateCmd.Parameters.Add((New-Object -TypeName System.Data.OleDb.OleDbParameter -Args @("Original_KeyID", [System.Data.OleDb.OleDbType]::VarWChar, 0))) > $null

    #qry Q&A Settings
    Write-Host -ForegroundColor Green "Current settings"
    $qryCmd.Connection = $conn
    $conn.Open()
    $qryAdapter.Fill($dataset) > $null #suppress rowcount
    $dataset.Tables[0]                 #return rst
    $conn.Close()
    
    #update host & password in Q&A mdb
    $updateCmd.Connection = $conn
    $conn.Open()
    
    $updateCmd.Parameters["Original_Group"].Value = "AL_CON"
    $updateCmd.Parameters["Group"].Value = "AL_CON"

    $SS4dict.GetEnumerator() | % {
        $updateCmd.Parameters["Original_KeyID"].Value = $_.Key
        $updateCmd.Parameters["KeyID"].Value = $_.Key
        $updateCmd.Parameters["DText"].Value = $_.Value
        Write-Host -ForegroundColor Green "Updating $($_.Key) = $($_.Value)"
        [string]$updateCmd.ExecuteNonQuery() +" Row(s) Affected"
    }

    $QAdict.GetEnumerator() | % {
        $updateCmd.Parameters["Original_KeyID"].Value = $_.Key
        $updateCmd.Parameters["KeyID"].Value = $_.Key
        $updateCmd.Parameters["DText"].Value = $_.Value
        Write-Host -ForegroundColor Green "Updating $($_.Key) = $($_.Value)"
        [string]$updateCmd.ExecuteNonQuery() +" Row(s) Affected"
    }
    $conn.Close()
} Catch
{
    $_.Exception.Message
}
