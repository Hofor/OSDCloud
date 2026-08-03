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

$ChassisType = (Get-WmiObject -Query "SELECT * FROM Win32_SystemEnclosure").ChassisTypes
$HyperV = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE '%Microsoft Corporation%' AND Model LIKE '%Virtual Machine%'"
$VMware = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE '%VMware%' AND Model LIKE '%VMware%'"

If ($HyperV -or $VMware) 
{
    $Manufacturer = "VM"
    Write-Host ":Manufacturer : $Manufacturer" 
}
else
{
    $Manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer
    $Model        = Get-MyComputerModel
    $Product      = Get-MyComputerProduct
    
    Write-Host "Manufacturer : $Manufacturer"
    Write-Host "Model        : $Model"
    Write-Host "Product      : $Product"
}

#=========================================================================
# OSDCloud Variables
#=========================================================================
Write-SectionHeader "[PreOS] MyOSDCloud Variables"

$Global:MyOSDCloud = [ordered]@{

    # Deployment
    Restart               = [bool]$false
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

#Region Determine if using native driver packs, or if I want to use extracted drivers on OSDCloudUSB
$Product = (Get-MyComputerProduct)
$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID

if ($DriverPack){
    $Global:MyOSDCloud.DriverPackName = $DriverPack.Name
}

write-host $Global:MyOSDCloud.DriverPackName

#If Drivers are expanded on the USB Drive, disable installing a Driver Pack
if ((Test-DISMFromOSDCloudUSB) -eq $true){
    Write-Host "Found Driver Pack Extracted on Cloud USB Flash Drive, disabling Driver Download via OSDCloud" -ForegroundColor Green
    $Global:MyOSDCloud.DriverPackName = "None"
}
else
{
   #$Global:MyOSDCloud.MSCatalogFirmware = $true
   $Global:MyOSDCloud.DriverPackName = 'Microsoft Update Catalog'  
}
#endregion Driver Pack Stuff

#$Global:MyOSDCloud.DriverPackName   = 'Microsoft Update Catalog'
#$Global:MyOSDCloud.MSCatalogFirmware = $true

Write-Host ($Global:MyOSDCloud | Out-String)
#endregion

#region OS Tasks
#=======================================================================
Write-SectionHeader "[OS] Params and Start-OSDCloud"
#=======================================================================
Write-SectionHeader "[OS] Start OSDCloud"
$OSVersion = 'Windows 11' #Used to Determine Driver Pack
$OSReleaseID = '24H2' #Used to Determine Driver Pack
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage = 'da-dk'
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage -SkipAutopilot -ZTI
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
#powershell.exe -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/Hofor/OSDCloud/main/scripts/removeAppx.ps1'')"

exit /b 0
'@
$OOBEcmdTasks | Out-File -FilePath 'C:\Windows\Setup\Scripts\oobe.cmd' -Encoding ASCII -Force
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

$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ASCII -Force
Write-Host "SetupComplete.cmd created successfully" -ForegroundColor Green

#=========================================================================
# Finish
#=========================================================================
Write-Host ""
Write-Host "Deployment completed. Rebooting..." -ForegroundColor Green

Stop-Transcript | Out-Null

# wpeutil reboot
