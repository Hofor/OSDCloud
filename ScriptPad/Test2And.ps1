Invoke-Expression -Command (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/functions.ps1')

#Variables to define the Windows OS / Edition etc to be applied during OSDCloud
$Product = (Get-MyComputerProduct)
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$OSVersion = 'Windows 11' #Used to Determine Driver Pack
$OSReleaseID = '24H2' #Used to Determine Driver Pack
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage = 'da-dk'

$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID
if ($DriverPack) {
    $DriverPackName = $DriverPack.Name
    Write-Host "Matched driver pack: $DriverPackName" -ForegroundColor Green
}
else {
    $DriverPackName = 'Microsoft Update Catalog'
    Write-Warning "No OSDCloud driver pack matched product '$Product'. Using Microsoft Update Catalog drivers."
}

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
    Product = $Product
    DriverPackName = $DriverPackName
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

        Write-Host "HP product ID: $Product" -ForegroundColor DarkGray
    }

    "*LENOVO*" {

        Write-Host "Lenovo Device detected" -ForegroundColor Green

        Write-Host "Lenovo product ID: $Product" -ForegroundColor DarkGray
    }

    default {

        Write-Host "Using Microsoft Update Catalog drivers" -ForegroundColor Yellow

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
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage -SkipAutopilot -ZTI
#endregion


#=========================================================================
# Finish
#=========================================================================
Write-Host ""
Write-Host "Deployment completed. Rebooting..." -ForegroundColor Green

Stop-Transcript | Out-Null

# wpeutil reboot
