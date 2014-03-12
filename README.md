PowerShell-Session-Manager
==========================

## Install ##
	iex (new-object System.Net.WebClient).DownloadString('https://raw.github.com/jrich523/PowerShell-Session-Manager/master/Install.ps1')

# *Simplify Remoting!* #

## Features ##

- Auto find credentials with **Find-Credential**
- Simple Remoting connections with **Connect-PSSession** (alias: cs)
- **Copy-Item** proxy function that supports credentials 
- Remote Profiles - The Connect-PSSession -RemoteProfile parameter. This will default to Remote_Profile.ps1 located in the user profile path.
- Maintained Session - Because **New-PSSession** is what creates the session they are never destroyed.
- Remotely supported PSEdit (Still in development)
- Tab complete server name for established connections.


## Syntax ##
*Just import the module and you're off and running!*


    ipmo PSSessionManager
    #will help auto connection to resources in  DomainA
    $DomainAcred = get-credential 
    cs ServerA


**Connect-PSSession** will use **Find-Credential**, which looks for any credential objects you've got to see if any will work with the system. It uses DNS and the domain\username syntax of the credential object to figure out which credentials SHOULD work.
If credentials are found it will use those and attempt to make a CredSSP connection, if it cant it does a standard connection.

Once you exit the session it is maintained and reentered upon requesting a connection to that server again.

The script will look to see if there is a Remote_Profile.ps1 in the profile folder (my documents\windowspowershell\)

There is a built in remote editor so that you can run PSEdit in the remote connection and it will open up locally.


The remote profile and psedit are new and only lightly tested features so please let me know what you find with using them.


## Bugs ##

- Importing the module again with -Force will break tab completion
- Remote PSEdit will only work with ISE and a single tab. Still in progress  

## Future Features ##

- Use BetterCredentials to load credentials from the Windows Credential Store
- Support Configuration file for cred matching options
- Quick RDP launch feature