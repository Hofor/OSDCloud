[CmdletBinding()]
param ()

Start-Transcript -Path "C:\OSDCloud\Logs\Start-OOBEDeploy.log" -ErrorAction Ignore

Write-Host "🚀 Starting OOBE configuration..." -ForegroundColor Cyan

# Installer nødvendige moduler
Install-Module OSD -Force
Install-Module AutopilotOOBE -Force

# Start OOBEDeploy med parametre
$Params = @{
    Autopilot     = $false
    RemoveAppx    = "Xbox", "Solitaire", "Skype", "People", "OfficeHub"
    UpdateDrivers = $true
    UpdateWindows = $true
}
Start-OOBEDeploy @Params

Write-Host "OOBE configuration complete." -ForegroundColor Green

Stop-Transcript
