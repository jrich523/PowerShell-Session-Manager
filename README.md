PowerShell-Session-Manager
==========================

Simplify remoting!

just import the module and run

cs ServerA

it will look for any credential objects you've got to see if any will work with the system.
If creds are found it will use those and attempt to make a CredSSP connection, if it cant it does a standard connection.

Once you exit the session it is maintained and reentered upon requestiong a connection to that server again.

The script will look to see if there is a Remote_Profile.ps1 in the profile folder (my documents\windowspowershell\)

There is a built in remote editor so that you can run PSEdit in the remote connection and it will open up locally.


The remote profile and psedit are new and only lightly tested features so please let me know what you find with using them.


