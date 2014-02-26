try{Add-Type -Path $PSScriptRoot\MonitorCommand.cs}catch{}

. $PSScriptRoot\PSSMListener.ps1
. $PSScriptRoot\Connect-PSSMSession.ps1
. $PSScriptRoot\copy-item.ps1
. $PSScriptRoot\find-credential.ps1