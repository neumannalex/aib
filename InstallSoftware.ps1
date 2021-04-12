# https://devkimchi.com/2020/08/26/app-provisioning-on-azure-vm-with-chocolatey-for-live-streaming/


# Logs
mkdir "C:\\mylogs"
echo "Starting script InstallSoftware.ps1 at $(Get-Date)" > "C:\\mylogs\install.txt"

# Install Chocolatey
echo "Starting to install Chocolatey at $(Get-Date)" > "C:\\mylogs\install.txt"
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
echo "Finished installing Chocolatey at $(Get-Date)" > "C:\\mylogs\install.txt"


# Install Software
echo "Starting to install VSCode at $(Get-Date)" > "C:\\mylogs\install.txt"
choco install vscode -y
echo "Finished installing VSCode at $(Get-Date)" > "C:\\mylogs\install.txt"