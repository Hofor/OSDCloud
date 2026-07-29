#=========================================================================
# OSDCloud Deployment
#=========================================================================
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

#=========================================================================
# Logging
#=========================================================================
if (-not (Test-Path 'X:\OSDCloud\Logs')) {
    New-Item -Path 'X:\OSDCloud\Logs' -ItemType Directory -Force | Out-Null
}

#Transport Layer Security (TLS) 1.2
Write-Host -ForegroundColor Green "Transport Layer Security (TLS) 1.2"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Start-OSDCloudLogic.log"
Start-Transcript -Path (Join-Path "X:\OSDCloud\Logs" $Transcript) | Out-Null

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

#=========================================================================
# OSD Module
#=========================================================================
Write-SectionHeader "[PreOS] Import OSD Module"

try {
    Install-Module OSD -Force -SkipPublisherCheck
}
catch {
    Write-Warning "OSD Module already installed or installation failed"
}

Import-Module OSD -Force

Write-Host "Loading OSDCloud functions..." -ForegroundColor Green
Invoke-Expression (Invoke-RestMethod -Uri functions.osdcloud.com)

#=========================================================================
# Device Information
#=========================================================================
Write-SectionHeader "[PreOS] Hardware Detection"

$Manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer
$Model        = Get-MyComputerModel
$Product      = Get-MyComputerProduct

Write-Host "Manufacturer : $Manufacturer"
Write-Host "Model        : $Model"
Write-Host "Product      : $Product"

#=========================================================================
# OSDCloud Variables
#=========================================================================
Write-SectionHeader "[PreOS] MyOSDCloud Variables"

$Global:MyOSDCloud = [ordered]@{

    # Deployment
    Restart               = [bool]$true
    RecoveryPartition     = [bool]$true
    ClearDiskConfirm      = [bool]$false
    ShutdownSetupComplete = [bool]$false

    # Windows
    OEMActivation         = [bool]$true
    SetTimeZone           = [bool]$true
    NetFx3                = [bool]$true

    # Updates
    WindowsUpdate         = [bool]$true
    WindowsUpdateDrivers  = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    
    # Misc
    SyncMSUpCatDriverUSB  = [bool]$false
    CheckSHA1             = [bool]$true
}

#=========================================================================
# OEM Handling
#=========================================================================
Write-SectionHeader "[PreOS] OEM Configuration"
<#
switch -Wildcard ($Manufacturer.ToUpper()) {

    "*HP*" {

        Write-Host "HP Device detected" -ForegroundColor Green

        $Global:MyOSDCloud.HPBIOSUpdate =  [bool]$true
        $Global:MyOSDCloud.HPTPMUpdate  =  [bool]$true
        $Global:MyOSDCloud.HPIADrivers  =  [bool]$true
        $Global:MyOSDCloud.HPIAFirmware =  [bool]$true

        # Let OSDCloud determine HP driver package
        $Global:MyOSDCloud.DriverPackName = $null
    }

    "*LENOVO*" {

        Write-Host "Lenovo Device detected" -ForegroundColor Green

        # Let OSDCloud select Lenovo OEM driver pack
        $Global:MyOSDCloud.DriverPackName = $null
    }

    default {

        Write-Host "Using Microsoft Update Catalog drivers" -ForegroundColor Yellow

        $Global:MyOSDCloud.DriverPackName   = 'Microsoft Update Catalog'
        $Global:MyOSDCloud.MSCatalogFirmware = $true
    }
}
#>

$Global:MyOSDCloud.DriverPackName   = 'Microsoft Update Catalog'
$Global:MyOSDCloud.MSCatalogFirmware = $true

Write-Host ""
Write-Host ($Global:MyOSDCloud | Out-String)

#=========================================================================
# Start OSDCloud
#=========================================================================

Write-SectionHeader "[OS] Start OSDCloud"

$Params = @{

    OSVersion     = "Windows 11"
    OSBuild       = "24H2"

    OSEdition     = "Enterprise"
    OSLanguage    = "da-dk"
    OSLicense     = "Volume"

    ZTI           = $true
    Firmware      = $true
}

Write-Host ($Params | Out-String)

Start-OSDCloud @Params
#endregion

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================

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
    "RemoveAppx": [
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
#=========================================================================
# SetupComplete
#=========================================================================
Write-SectionHeader "[PostOS] Create SetupComplete.cmd"

if (-not (Test-Path 'C:\Windows\Setup\Scripts')) {
    New-Item -Path 'C:\Windows\Setup\Scripts' -ItemType Directory -Force | Out-Null
}

$SetupCompleteCMD = @'
@echo off

#powershell.exe -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/Hofor/OSDCloud/main/scripts/removeAppx.ps1'')"

powershell.exe -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/Hofor/OSDCloud/main/scripts/cleanupOSD.ps1'')"

exit /b 0
'@

$SetupCompleteCMD | Out-File `
    -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' `
    -Encoding ASCII `
    -Force

Write-Host "SetupComplete.cmd created successfully" -ForegroundColor Green

#=========================================================================
# Finish
#=========================================================================
Write-Host ""
Write-Host "Deployment completed. Rebooting..." -ForegroundColor Green

Stop-Transcript | Out-Null

# wpeutil reboot
