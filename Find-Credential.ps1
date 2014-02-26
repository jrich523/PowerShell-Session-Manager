<#
.Synopsis
   Find any credential object that SHOULD apply to the computer provided
.DESCRIPTION
   Looks at the FQDN of the system and pulls off the domain aspect of it and then searches for all credntial variables that have that domain used.
   This should find useful creds in most situations.
.EXAMPLE
    This will return the first credntial object it finds that should work on that server (domain match)
   Find-Credential -ComputerName ServerA
.EXAMPLE
   This will return all credntial objects that should work on this machine.
   Find-Credential -ComputerName ServerA -All
#>
function Find-Credential
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCredential])]
    Param
    (
        # Destination Computer
        [Parameter(Mandatory=$true, Position=0)]
        $ComputerName,
        [switch]
        $All
    )
    if($ComputerName -notlike "*.*")
    {
        try {
            $fqdn = [net.dns]::GetHostEntry($ComputerName).HostName
        }
        catch {
            Write-Error "Unable to resolve host name!" -ErrorAction Stop
        }
    }
    else
    {
        $fqdn=$ComputerName
    }
    $domain = $fqdn.Substring($fqdn.IndexOf('.')+1)
    $tempc = gv |?{$_.value -is "System.Management.Automation.PSCredential"} | ? {$domain -match $_.value.username.split('\')[0]} 
    if(-not $all){$temppc = $temppc | select -First 1}
    if($tempc)
    {
        Write-Verbose "Credentials found in $($tempc.name)"
        $tempc| %{$_.value}
    }
}

Export-ModuleMember -Function * -Alias *