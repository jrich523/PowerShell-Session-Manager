$Global:commandtracker = @()

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Start-PSSMListener
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Position=0)]
        $Port
    )

    $script:monitor = new-object DoWork.MonitorCommand
    ### CREATE PLUGIN LIKE SYSTEM
    $script:ListenerEvent = Register-ObjectEvent -InputObject $script:monitor -EventName OnCommand -Action {
        $Global:CommandTracker += $eventargs;
        $value = $eventargs.value
        $computername = $eventargs.computername
        $command = $eventargs.command

        $isLocalHost = $computername -match $env:COMPUTERNAME

        ## plugin system
        if($eventargs.command -eq "open")
        {
               
            if($isLocalHost)
            {
                $path = $value
            }
            else
            {
                $drive,$endpath = $value.split(":")
                $drivename = $computername.Split(".")[0] + $drive
                if(-not (Get-PSDrive $drivename -ea 0 -Scope global))
                {
                    $cred = (Get-PSSession | ?{$computername -match $_.ComputerName} | select -first 1).runspace.connectioninfo.credential
                    New-PSDrive -Name $drivename -PSProvider FileSystem -Root \\$computername\$drive`$ -Description "Connection manager drive" -Credential $cred -Scope global
                }
                $path = (gi ($drivename + ":" + $endpath)).FullName

            
            }
            $psise.CurrentPowerShellTab.Files.SelectedFile=$psise.CurrentPowerShellTab.Files.Add($path)

        }
        ## end plugin
    }

    if($psise)
    {
        $port = 12340 + $psise.PowerShellTabs.IndexOf($psise.CurrentPowerShellTab)
    }
    else
    {
        #todo: add some randomness, or check
        port = 12345
    }
    $null = $script:monitor.Start($port)

}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Stop-PSSMListener
{
    [CmdletBinding()]
    Param()
    Unregister-Event $script:ListenerEvent
    $client = New-Object System.Net.Sockets.TcpClient 'localhost', $script:monitor.port
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter $stream
    $writer.Dispose()
    $stream.Dispose()
    $client.close()
}