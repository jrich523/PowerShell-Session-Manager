try{Add-Type -Path $PSScriptRoot\MonitorCommand.cs}catch{}

. $PSScriptRoot\PSSMListener.ps1
. $PSScriptRoot\Connect-PSSMSession.ps1
