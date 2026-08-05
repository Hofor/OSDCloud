#=========================================================================
# Helper Functions
#=========================================================================
function Write-SectionHeader {
    param([string]$Message)

    Write-Host ""
    Write-Host "=========================================================================" -ForegroundColor DarkGray
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" -ForegroundColor Cyan
    Write-Host "=========================================================================" -ForegroundColor DarkGray
}

Write-SectionHeader "[Start] OSD Cloud"

#=========================================================================
# Logging
#=========================================================================
if (-not (Test-Path 'X:\OSDCloud\Logs')) {
    New-Item -Path 'X:\OSDCloud\Logs' -ItemType Directory -Force | Out-Null
}

Write-Host "TLS 1.2 Enabled" -ForegroundColor Green
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud.log"
Start-Transcript -Path (Join-Path "X:\OSDCloud\Logs" $Transcript) | Out-Null

#=========================================================================
# OSD Module
#=========================================================================
Write-SectionHeader "[PreOS] OSD Module"
Invoke-Expression -Command (Invoke-RestMethod -Uri functions.osdcloud.com)

#=========================================================================
# Device Information
#=========================================================================
Write-SectionHeader "[PreOS] Hardware Detection"

$Product      = Get-MyComputerProduct
$Model        = Get-MyComputerModel
$Manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer

$OSVersion    = 'Windows 11'
$OSReleaseID  = '24H2'
$OSName       = 'Windows 11 24H2 x64'
$OSEdition    = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage   = 'da-dk'

Write-Host "Manufacturer: $Manufacturer" -ForegroundColor Yellow
Write-Host "Model: $Model" -ForegroundColor Yellow
Write-Host "Product: $Product" -ForegroundColor Yellow
#endregion

#=========================================================================
# MyOSDCloud
#=========================================================================
Write-SectionHeader "[PreOS] MyOSDCloud"

$Global:MyOSDCloud = [ordered]@{

    Restart               = $true
    RecoveryPartition     = $true
    ClearDiskConfirm      = $false
    ShutdownSetupComplete = $false
    OEMActivation         = $true
    NetFx3                = $true
    SetTimeZone           = $false
    WindowsUpdate         = $true
    WindowsUpdateDrivers  = $true
    WindowsDefenderUpdate = $true
    #MSCatalogFirmware    = $true
    #Product              = $Product
    SyncMSUpCatDriverUSB  = $false
    CheckSHA1             = $true
}
#endregion

#=========================================================================
# OEM Handling
#=========================================================================
Write-SectionHeader "[PreOS] OEM Configuration"

$Global:MyOSDCloud.DriverPackName = $null
$Global:MyOSDCloud.DriverPackName = 'Microsoft Update Catalog'
$Global:MyOSDCloud.MSCatalogFirmware = $true

Write-Host ""
Write-Host ($Global:MyOSDCloud | Out-String)
#endregion

#=========================================================================
# Start OSDCloud
#=========================================================================
Write-SectionHeader "[OS] Start OSDCloud"
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage -SkipAutopilot -ZTI
#endregion

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================
write-SectionHeader "[PostOS] OOBEDeploy Configuration"
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"

$OOBEDeployJson = @'
{
    "AddNetFX3": {
        "IsPresent": true
    },
    "Autopilot": {
        "IsPresent": true
    },
    "UpdateDrivers": {
        "IsPresent": true
    },
    "UpdateWindows": {
        "IsPresent": true
    },
    "UpdateDefender": {
        "IsPresent": true
    },
    "RemoveAppx":  [
                    "MSTeams",
                    "MicrosoftTeams",
                    "Microsoft.BingWeather",
                    "Microsoft.BingNews",
                    "Microsoft.GamingApp",
                    "Microsoft.GetHelp",
                    "Microsoft.Getstarted",
                    "Microsoft.Messaging",
                    "Microsoft.MicrosoftOfficeHub",
                    "Microsoft.MicrosoftSolitaireCollection",
                    "Microsoft.People",
                    "Microsoft.PowerAutomateDesktop",
                    "Microsoft.StorePurchaseApp",
                    "Microsoft.Todos",
                    "microsoft.windowscommunicationsapps",
                    "Microsoft.WindowsFeedbackHub",
                    "Microsoft.WindowsMaps",
                    "Microsoft.WindowsSoundRecorder",
                    "Microsoft.Xbox.TCUI",
                    "Microsoft.XboxGameOverlay",
                    "Microsoft.XboxGamingOverlay",
                    "Microsoft.XboxIdentityProvider",
                    "Microsoft.XboxSpeechToTextOverlay",
                    "Microsoft.YourPhone",
                    "Microsoft.ZuneMusic",
                    "Microsoft.ZuneVideo"
                   ]
}
'@

If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}

$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force
#endregion

#region OOBE Tasks
#================================================
Write-SectionHeader "[PostOS] OOBE CMD Command Line"
#================================================
Write-Host "Downloading Scripts for OOBE and specialize phase"

if (-not (Test-Path 'C:\Windows\Provisioning\Autopilot')) {
    New-Item -Path 'C:\Windows\Provisioning\Autopilot' -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path 'C:\Windows\Setup\Scripts')) {
    New-Item -Path 'C:\Windows\Setup\Scripts' -ItemType Directory -Force | Out-Null
}

Invoke-RestMethod https://raw.githubusercontent.com/Hofor/OSDCloud/main/scripts/AutopilotConfiguration.json | Out-File -FilePath 'C:\Windows\Provisioning\Autopilot\AutopilotConfigurationFile.json' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/Hofor/OSDCloud/main/scripts/removeAppx.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\removeAppx.ps1' -Encoding ascii -Force

$OOBEcmdTasks = @'
@echo off

REM start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\psWindowsUpdate.ps1
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\removeAppx.ps1

exit 
'@
$OOBEcmdTasks | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force
Write-Host "oobe.cmd created successfully" -ForegroundColor Green
#endregion

#region Collecting the logs
#=======================================================================	
Write-SectionHeader "Moving OSDCloud Logs to IntuneManagementExtension\Logs\OSD"	
#=======================================================================
$LogFolder = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD"

if (-NOT (Test-Path $LogFolder)) {	
    New-Item -Path $LogFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null	
}	

if (Test-Path 'C:\OSDCloud\Logs') {
    Get-ChildItem 'C:\OSDCloud\Logs' | Copy-Item -Destination $LogFolder -Force
}

if (Test-Path 'X:\OSDCloud\Logs') {
    Get-ChildItem 'X:\OSDCloud\Logs' | Copy-Item -Destination $LogFolder -Force
}
#endregion

#=========================================================================
# Finish
#=========================================================================
Write-Host ""
Write-Host "Deployment completed. Rebooting..." -ForegroundColor Green

Stop-Transcript | Out-Null
