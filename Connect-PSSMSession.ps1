<#
.Synopsis
   creates and enters a remote session with the best configuration (credssp) if it can.
.DESCRIPTION
   The file path is passed back to the local system to open up via either UNC or PSDrive if creds are required.
   The listener must be started before the connection is established. Keep in mind that sessions are reused.
.EXAMPLE
   Send-PSSMFileOpen myfile.txt
#>
function Connect-PSSMSession
{
    [CmdletBinding()]
    
    Param
    (
        # The name of the remote computer to connect to. Short name will be resolved to fully qualified
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [string]
        $ComputerName,
        #Credentials to connect with. If none are supplied the session is searched for creds to match the remote system.
        [Parameter(Position=1)]
        [Management.Automation.PSCredential]
        $Credential,
        # Loads the Remote_Profile.ps1 from your profile folder (documents\windowspowershell)
        [string]
        $RemoteProfile=(join-path (split-path $profile) Remote_Profile.ps1),
        [switch]
        $SessionOnly,
        [switch]
        $NoProfile
    )
    process{
    #get FQDN if not provided to let user know where they are connecting
    #also to grab domain for creds
    if($ComputerName -notlike "*.*")
    {
        try {
        $fqdn = [net.dns]::GetHostEntry($ComputerName).HostName
        ## fqdn doesnt seem to be needed for credssp, leave it out, if it breaks, insert here
        }
        catch {
        Write-Error "Unable to resolve host name!" -ErrorAction Stop

        }
    }
    else
    {
        $fqdn=$ComputerName
    }
    #change to FQDN if you end up using that, which as of now doesnt seem to be needed.
    Write-host "Connecting to $fqdn" -ForegroundColor Green
    #was a remote profile specified or the default used.
    
    #no creds provided, search for some, but make sure you've got a FQDN to work with to figure out domain
    if(-not $Credential)
    {
            $Credential = Find-Credential -computername $fqdn
            Write-Verbose "Using $($Credential.UserName)"
    }
    else
    {
        Write-Verbose "using specified credentials"
    }

    ##remote any broken sessions
    Get-PSSession | ?{$_.State -eq "Broken"} | Remove-PSSession

    #is there already an active session?
    $session = Get-PSSession | ?{$_.ComputerName -eq $computername}
    Write-Verbose "Found $($session.count) matching session(s)"

    if($PSBoundParameters.ContainsKey("Credential") -and $session)
    {
        Write-Verbose "Checking to see if open sessions are using correct credentials"
        $session = $session |? { $_.Runspace.ConnectionInfo.Credential.UserName -eq $Credential.UserName}
        Write-Verbose "Found $($session.count) with matching Creds"
    }
    
    #################################
    ## we have a session to work with, make sure its optimal, if not scrap it and try again!
    #################################
    if($session)
    {
        write-verbose "Session found, checking for credssp"
        $credssp = if($session.Runspace.ConnectionInfo.AuthenticationMechanism){$true}
        #its not credssp, can we make it?!
        if(-not $credssp -and $Credential -and [bool](Test-WSMan $computername -Credential $Credential -Authentication Credssp -ea 0))
        {
            Write-Verbose "not credssp but it can be done, so we shall do it!"
            Remove-PSSession -Session $session
            #$session = New-PSSession -ComputerName $computername -Credential $Credential -Authentication Credssp
            $session = $null #exact same if will do this again
        }
        else{write-verbose "Session found with credssp"}
        Write-Verbose "Found $($session.count) matching sessions"
    }
    #################################
    # lets check profile options now
    #################################
    if($session)
    {
        #does it have a profile?
        Write-Verbose "Checking session remote profile ($($Session.count) sessions, more than 1, might be bad)"
        if(Get-Member -Name RemoteProfile -InputObject $session)
        {
            $sessionprofile = $session.RemoteProfile
            Write-Verbose "local session profile: $sessionprofile"
        }
        else #maybe we lost our session info, peek in to make sure
        {
            $sessionprofile = invoke-command -Session $session -ScriptBlock {$RemoteProfile}
            Write-Verbose "local session info not found, remote session profile: $sessionprofile"
        }
        #####
        if($NoProfile -and -not $sessionprofile)
        {
            #no profile requested, but session has profile
            #dont remove session, we might still want it, but clear out session
            Write-Verbose "No profile was specified but existing session has profile loaded, new session will be created"
            $session = $null
        }
        elseif($sessionprofile -ne $RemoteProfile)
        {
            Write-Verbose "Session found but contains a different remote profile ($($sessionprofile)), new session will be created"
            $session=$null
        }
        else
        {
            Write-Verbose "profile matches! lets use it!"
            Write-Host "Matching Session found" -ForegroundColor Green
        }

    }

    if(-not $session) #no session, lets make one
    {
        Write-Host "Creating New session" -ForegroundColor Green
        #can we do credssp
        if($Credential -and [bool](Test-WSMan $computername -Credential $Credential -Authentication Credssp -ea 0))
        {
            Write-Verbose "Creating session with CredSSP"
            $session = New-PSSession -ComputerName $ComputerName -Credential $Credential -Authentication Credssp
        }
        #can we do it with local creds?
        elseif(Test-WSMan $computername -Authentication Default -ea 0)
        {
            Write-Verbose "No creds provided, attempting with current user creds, no CredSSP"
            $session = New-PSSession -ComputerName $computername -ea 0
        }
        #local creads dont work, try found creds
        
        if(-not $session -and $credential -and [bool](Test-WSMan -ComputerName $computername -Credential $Credential -Authentication Default -ea 0))
        {
            Write-Verbose "Using credentials to create session without CredSSP"
            $session = New-PSSession -ComputerName $computername -Credential $Credential
        }
        if($session -and -not $NoProfile -and (test-path $RemoteProfile))##TODO: do i need to check session? it should be there by now
        {
            #load profile
            Write-Verbose "Injecting profile located at $RemoteProfile"
            Invoke-Command -Session $session -FilePath $RemoteProfile
            #tag profile info
            Invoke-Command -Session $session -ScriptBlock {$RemoteProfile = $args[0]} -ArgumentList $RemoteProfile
            
            if($psise)
            {
                Invoke-Command -Session $session -ScriptBlock {$global:RemoteConnection = $args[0]} -ArgumentList @{HostName=[net.dns]::GetHostEntry('localhost').HostName;Port=12340 + $psise.PowerShellTabs.IndexOf($psise.CurrentPowerShellTab)}
                ## plugin system?
                Invoke-Command -Session $session -FilePath $PSScriptRoot\send-pssmfileopen.ps1
            }

            $session | Add-Member -MemberType NoteProperty -Name RemoteProfile -Value $RemoteProfile
        }
        elseif($session)
        {
            write-verbose "Checking existing session for profile injection"
            if(-not $NoProfile)
            {
                #profile was requests but not found, notify the user
                Write-Warning "!!! Remote profile ($($RemoteProfile)) not found! Loading without profile"
            }
            #no profile, set it to blank string
            Invoke-Command -Session $session -ScriptBlock {$RemoteProfile = ""}
            $session | Add-Member -MemberType NoteProperty -Name RemoteProfile -Value ""
        }
    }

    if($session)
    {
        ## tag profile info
        Write-Host "Connecting as: $($session.Runspace.ConnectionInfo.Credential.UserName)" -ForegroundColor Green
        Write-Host "Authentication Method: $($session.Runspace.ConnectionInfo.AuthenticationMechanism)" -ForegroundColor Green
        if($SessionOnly)
        {
            $session
        }
        else
        {
            Write-Verbose "Session ID: $($session.Id)"
            Enter-PSSession  -id $session.id
        }
    }
    else
    {
        Write-Error "Cant connect to $computername"
    }
    }
}

Set-Alias -Name cs -Value Connect-PSSMSession 

### add in tab completion
$Completion_ConnectSession_ComputerName = {
param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-PSSession  | Where {$_.ComputerName -match $wordToComplete } |Sort-Object ComputerName | ForEach-Object {
        New-Object System.Management.Automation.CompletionResult $_.ComputerName, $_.ComputerName, 'ParameterValue', $_.ComputerName
    }
}

if (-not $global:TabExpansionOptions) { $global:TabExpansionOptions = @{CustomArgumentCompleters = @{};NativeArgumentCompleters = @{}}}
$global:TabExpansionOptions['CustomArgumentCompleters']['Connect-PSSMSession:ComputerName'] = $Completion_ConnectSession_ComputerName
if(-not $script:OriginalTabExpansion2)
{
    $script:OriginalTabExpansion2 = $Function:TabExpansion2
}
if($script:OriginalTabExpansion2 -notmatch "TabExpansionOption")
{
    $Function:TabExpansion2 = $Function:TabExpansion2 -replace 'End\r\n{','End { if ($null -ne $options) { $options += $global:TabExpansionOptions} else {$options = $global:TabExpansionOptions}'
}


Export-ModuleMember -Function * -Alias *
### tab complete the name via dynamic param