<#
.Synopsis
   Sends the path of a file back to the local system
.DESCRIPTION
   The file path is passed back to the local system to open up via either UNC or PSDrive if creds are required.
   The listener must be started before the connection is established. Keep in mind that sessions are reused.
.EXAMPLE
   Send-PSSMFileOpen myfile.txt
#>
function Send-PSSMFileOpen  {
    [CmdletBinding()]
    param(
        #The File you'd like to open
        [Parameter(ValueFromPipeline=$true, Position=1)]
        [string]$file,
        #connection back to the local host
        [string]$address=$Global:RemoteConnection.HostName,
        #port to connect to
        [int]$port=$Global:RemoteConnection.Port
    )
    begin {
        $client = New-Object System.Net.Sockets.TcpClient $address, $port
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter $stream
    }
    process {
        if($file){
            if(Test-Path $file -ea 0)
            {
                $fullpath = (gi $file).FullName
                #$hostname = [net.dns]::GetHostEntry('localhost').HostName
                $writer.Write("open;$fullpath")
            }
            else
            {
                Write-Error "unable to resolve file"
            }
        }
        else
        {
            Write-Verbose "closing remote endpoint"
            $writer.write("")
        }
        
    }
    end {
        $writer.Dispose()
        $stream.Dispose()
        $client.close()
    }
}

if(-not (gcm psedit -ea SilentlyContinue)){Set-Alias -Name psedit -Value Send-PSSMFileOpen}