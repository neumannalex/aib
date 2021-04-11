# https://devkimchi.com/2020/08/26/app-provisioning-on-azure-vm-with-chocolatey-for-live-streaming/


# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Software
# choco install vscode -y