param([string]$InstallDirectory)
$ModName = "PSSessionManager"
$repo = "PowerShell-Session-Manager"
$userid = "jrich523"

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

    $InstallDirectory = Join-Path -Path $personalModules -ChildPath $ModName
}
if (!(Test-Path $InstallDirectory))
{
    $null = mkdir $InstallDirectory    
}

$wc = New-Object System.Net.WebClient
$wc.DownloadFile("https://raw.github.com/$userid/$repo/master/$modname.psd1","$installDirectory\$ModName.psd1")
Push-Location
cd $InstallDirectory
(Import-LocalizedData -FileName "$ModName.psd1").filelist | %{$wc.DownloadFile("https://raw.github.com/$userid/$repo/master/$_","$installDirectory\$_")}
gci | Unblock-File
Pop-Location


#iex (new-object System.Net.WebClient).DownloadString('https://raw.github.com/jrich523/PowerShell-Session-Manager/master/Install.ps1')