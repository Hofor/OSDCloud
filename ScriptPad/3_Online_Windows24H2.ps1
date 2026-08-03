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

Write-Host "TLS 1.2 Enabled" -ForegroundColor Green
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor `
    [Net.SecurityProtocolType]::Tls12

$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud.log"
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
Write-SectionHeader "[PreOS] OSD Module"

try {
    Install-Module OSD -Force -SkipPublisherCheck
}
catch {
    Write-Warning "OSD Module install skipped"
}

Import-Module OSD -Force

Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/functions.ps1')

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

#=========================================================================
# Driver Pack Detection
#=========================================================================
Write-SectionHeader "[PreOS] Driver Pack Discovery"

$DriverPackName = $null

try {
    $DriverPack = Get-OSDCloudDriverPack `
        -Product $Product `
        -OSVersion $OSVersion `
        -OSReleaseID $OSReleaseID

    if ($DriverPack) {
        $DriverPackName = $DriverPack.Name
        Write-Host "Matched Driver Pack: $DriverPackName" -ForegroundColor Green
    }
}
catch {
    Write-Warning "No Driver Pack Match Found"
}

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
    MSCatalogFirmware     = $true

    Product               = $Product

    SyncMSUpCatDriverUSB  = $false
    CheckSHA1             = $true
}

#=========================================================================
# OEM Handling
#=========================================================================
Write-SectionHeader "[PreOS] OEM Configuration"

switch -Wildcard ($Manufacturer.ToUpper()) {

    "*HP*" {

        Write-Host "HP Device Detected" -ForegroundColor Green

        # HPIA styrer det hele
        $Global:MyOSDCloud.DriverPackName = $null

        $Global:MyOSDCloud.HPIADrivers  = $true
        $Global:MyOSDCloud.HPIAFirmware = $true

        $Global:MyOSDCloud.HPBIOSUpdate = $true
        $Global:MyOSDCloud.HPTPMUpdate  = $true
    }

    "*LENOVO*" {

        Write-Host "Lenovo Device Detected" -ForegroundColor Green

        if ($DriverPackName) {
            $Global:MyOSDCloud.DriverPackName = $DriverPackName
        }
        else {
            $Global:MyOSDCloud.DriverPackName = 'Microsoft Update Catalog'
        }

        $Global:MyOSDCloud.MSCatalogFirmware = $true
    }

    "*DELL*" {

        Write-Host "Dell Device Detected" -ForegroundColor Green

        if ($DriverPackName) {
            $Global:MyOSDCloud.DriverPackName = $DriverPackName
        }
        else {
            $Global:MyOSDCloud.DriverPackName = 'Microsoft Update Catalog'
        }

        $Global:MyOSDCloud.MSCatalogFirmware = $true
    }

    default {

        Write-Host "Unknown Manufacturer - Using Microsoft Update Catalog" -ForegroundColor Yellow

        $Global:MyOSDCloud.DriverPackName = 'Microsoft Update Catalog'
        $Global:MyOSDCloud.MSCatalogFirmware = $true
    }
}

Write-Host ""
Write-Host ($Global:MyOSDCloud | Out-String)
#endregion

#=========================================================================
# Start OSDCloud
#=========================================================================
Write-SectionHeader "[OS] Start OSDCloud"

Start-OSDCloud `
    -OSName $OSName `
    -OSEdition $OSEdition `
    -OSActivation $OSActivation `
    -OSLanguage $OSLanguage `
    -SkipAutopilot `
    -ZTI

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
    }
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

if (-not (Test-Path 'C:\Windows\Setup\Scripts')) {
    New-Item -Path 'C:\Windows\Setup\Scripts' -ItemType Directory -Force | Out-Null
}

$OOBEcmdTasks = @'
@echo off

powershell.exe -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/Hofor/OSDCloud/main/scripts/psWindowsUpdate.ps1'')"
powershell.exe -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/Hofor/OSDCloud/main/scripts/removeAppx.ps1'')"

exit /b 0
'@

$OOBEcmdTasks | Out-File `
    -FilePath 'C:\Windows\Setup\Scripts\oobe.cmd' `
    -Encoding ASCII `
    -Force
#endregion

#=========================================================================
# SetupComplete
#=========================================================================
Write-SectionHeader "[PostOS] Create SetupComplete.cmd"

$SetupCompleteCMD = @'
@echo off

REM Cleanup
powershell.exe -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/Hofor/OSDCloud/main/scripts/cleanupOSD.ps1'')"

REM Create Autopilot folder
mkdir C:\Windows\Provisioning\Autopilot 2>nul

REM Download Autopilot profile
powershell.exe -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Hofor/OSDCloud/main/scripts/AutopilotConfiguration.json' -OutFile 'C:\Windows\Provisioning\Autopilot\AutopilotConfigurationFile.json'"

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