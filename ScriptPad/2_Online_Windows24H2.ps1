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
Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/functions.ps1')

#=========================================================================
# Device Information
#=========================================================================
Write-SectionHeader "[PreOS] Hardware Detection"
#Variables to define the Windows OS / Edition etc to be applied during OSDCloud
$Product = (Get-MyComputerProduct)
$Model = (Get-MyComputerModel)
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$OSVersion = 'Windows 11' #Used to Determine Driver Pack
$OSReleaseID = '24H2' #Used to Determine Driver Pack
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage = 'da-dk'

$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID
if ($DriverPack) {
    #$DriverPackName = 'Microsoft Update Catalog'
    $DriverPackName = $DriverPack.Name
    Write-Host "Matched driver pack: $DriverPackName" -ForegroundColor Green
}
else {
    $DriverPackName = 'Microsoft Update Catalog'
    Write-Warning "No OSDCloud driver pack matched product '$Product'. Using Microsoft Update Catalog drivers."
}


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
    SetTimeZone           = [bool]$false
    NetFx3                = [bool]$true

    # Updates
    WindowsUpdate         = [bool]$true
    WindowsUpdateDrivers  = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    MSCatalogFirmware     = [bool]$true
    Product               = $Product
    DriverPackName        = $DriverPackName
    
    # Misc
    SyncMSUpCatDriverUSB  = [bool]$false
    CheckSHA1             = [bool]$true
}

#=========================================================================
# OEM Handling
#=========================================================================
Write-SectionHeader "[PreOS] OEM Configuration"
switch -Wildcard ($Manufacturer.ToUpper()) {

    "*HP*" {

        Write-Host "HP Device detected" -ForegroundColor Green
        
        $Global:MyOSDCloud.HPBIOSUpdate =  [bool]$true
        $Global:MyOSDCloud.HPTPMUpdate  =  [bool]$true
        $Global:MyOSDCloud.HPIADrivers  =  [bool]$true
        $Global:MyOSDCloud.HPIAFirmware =  [bool]$true
    }

    "*LENOVO*" {

        Write-Host "Lenovo Device detected" -ForegroundColor Green

        # Let OSDCloud determine HP driver package
        $Global:MyOSDCloud.DriverPackName = $null
    
        # Almindelige opdateringer
        $Global:MyOSDCloud.WindowsUpdate = $true
        $Global:MyOSDCloud.WindowsUpdateDrivers = $true
        $Global:MyOSDCloud.WindowsDefenderUpdate = $true

        # Firmware via Microsoft Catalog hvis tilgængelig
        $Global:MyOSDCloud.MSCatalogFirmware = $true

    }

    default {
    
    Write-Host "Using Microsoft Update Catalog drivers" -ForegroundColor Yellow

        # Let OSDCloud determine driver package
        $Global:MyOSDCloud.DriverPackName = $null
    
        # Almindelige opdateringer
        $Global:MyOSDCloud.WindowsUpdate = $true
        $Global:MyOSDCloud.WindowsUpdateDrivers = $true
        $Global:MyOSDCloud.WindowsDefenderUpdate = $true

        # Firmware via Microsoft Catalog hvis tilgængelig
        $Global:MyOSDCloud.MSCatalogFirmware = $true
    }
}

Write-Host ""
Write-Host ($Global:MyOSDCloud | Out-String)
#endregion

#region OS Tasks
#=======================================================================
Write-SectionHeader "[OS] Params and Start-OSDCloud"
#=======================================================================
Write-SectionHeader "[OS] Start OSDCloud"
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage -SkipAutopilot -ZTI
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
