param([string]$InstallDirectory)

if ('' -eq $InstallDirectory)
{
    $personalModules = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules
    if (($env:PSModulePath -split ';') -notcontains $personalModules)
    {
        Write-Warning "$personalModules is not in `$env:PSModulePath"
    }

    if (!(Test-Path $personalModules))
    {
        Write-Error "$personalModules does not exist"
    }

    $InstallDirectory = Join-Path -Path $personalModules -ChildPath PSSessionManager
}
if (!(Test-Path $InstallDirectory))
{
    $null = mkdir $InstallDirectory    
}

$wc = New-Object System.Net.WebClient
$wc.DownloadFile("https://raw.github.com/jrich523/PowerShell-Session-Manager/master/PSSessionManager.psd1","$installDirectory\PSSessionManager.psd1")
Push-Location
cd $InstallDirectory
(Import-LocalizedData -FileName PSSessionManager.psd1).filelist | %{$wc.DownloadFile("https://raw.github.com/jrich523/PowerShell-Session-Manager/master/$_","$installDirectory\$_")}
gci | Unblock-File
Pop-Location


#iex (new-object System.Net.WebClient).DownloadString('https://raw.github.com/jrich523/PowerShell-Session-Manager/master/Install.ps1')