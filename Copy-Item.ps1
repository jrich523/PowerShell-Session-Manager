function Copy-Item {
[CmdletBinding(DefaultParameterSetName='Path', SupportsShouldProcess=$true, ConfirmImpact='Medium', SupportsTransactions=$true, HelpUri='http://go.microsoft.com/fwlink/?LinkID=113292')]
param(
    [Parameter(ParameterSetName='Path', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string[]]
    ${Path},

    [Parameter(ParameterSetName='LiteralPath', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath')]
    [string[]]
    ${LiteralPath},

    [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Destination},

    [switch]
    ${Container},

    [switch]
    ${Force},

    [string]
    ${Filter},

    [string[]]
    ${Include},

    [string[]]
    ${Exclude},

    [switch]
    ${Recurse},

    [switch]
    ${PassThru},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential})

begin
{
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

        ##mine!
        $null = Test-Path $Destination -ErrorAction SilentlyContinue -ErrorVariable errvar
        if($errvar[0].CategoryInfo.Category -eq "PermissionDenied" -and $Destination -match '(\\\\(.+?)\\([^\\]+))(.*)')
        {
            Write-Verbose ""
            $creds = Find-Credential -ComputerName $Matches[2] -All
            $i = 0
            do
            {
                $psdrive = New-PSDrive -Name TD -PSProvider FileSystem -Root $matches[1] -Credential $creds[$i]
                $testpath = Join-Path "TD:" $matches[4]
            }while(-not ($rst = Test-Path $testpath -ErrorAction SilentlyContinue) -and $i++ -le $creds.count)
            
            if($rst){$PSBoundParameters.Destination = Join-Path "TD:" $Matches[4]}
        }
        elseif ($Credential){
            $psdrive = New-PSDrive -Name TD -PSProvider FileSystem -Root $matches[1] -Credential $credential
            $PSBoundParameters.Destination = Join-Path "TD:" $Matches[4]
            $PSBoundParameters.Credential = $null
        }
        ### not mine!
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Copy-Item', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    Remove-PSDrive -Name TD -Force -ErrorAction SilentlyContinue
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Copy-Item
.ForwardHelpCategory Cmdlet

#>
}

Export-ModuleMember -Function * -Alias *