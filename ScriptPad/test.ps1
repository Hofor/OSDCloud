Invoke-Expression -Command (Invoke-RestMethod -Uri functions.osdcloud.com)

$Manufacturer = (Get-CimInstance -Class:Win32_ComputerSystem).Manufacturer
$Model = (Get-CimInstance -Class:Win32_ComputerSystem).Model
 
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


#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$False
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$true
    WindowsUpdateDrivers = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    MSCatalogFirmware  = [bool]$true
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
    NetFx3 = [bool]$True
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$false
    CheckSHA1 = [bool]$true
}

#=========================================================================
# OEM Handling
#=========================================================================
Write-Host "[PreOS] OEM Configuration"

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

Write-Host ($Global:MyOSDCloud | Out-String)
#endregion

#region OS Tasks
#=======================================================================
Write-Output "[OS] Params and Start-OSDCloud"
#=======================================================================
Write-Output "[OS] Start OSDCloud"
$OSVersion = 'Windows 11' #Used to Determine Driver Pack
$OSReleaseID = '24H2' #Used to Determine Driver Pack
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage = 'da-dk'
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage -SkipAutopilot -ZTI
#endregion


#=========================================================================
# Finish
#=========================================================================
Write-Host ""
Write-Host "Deployment completed. Rebooting..." -ForegroundColor Green

Stop-Transcript | Out-Null

# wpeutil reboot
