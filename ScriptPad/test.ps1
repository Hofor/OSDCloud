###
Write-Host -ForegroundColor Green "Transport Layer Security (TLS) 1.2"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

try {
    Install-Module OSD -Force -SkipPublisherCheck
}
catch {
    Write-Warning "OSD Module already installed or installation failed"
}

Import-Module OSD -Force

Write-Host "Loading OSDCloud functions..." -ForegroundColor Green
Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/functions.ps1')

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

$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID
if ($DriverPack) {
   $DriverPackName = 'Microsoft Update Catalog'
    #$DriverPackName = $DriverPack.Name
    Write-Host "Matched driver pack: $DriverPackName" -ForegroundColor Green
}
else {
    $DriverPackName = 'Microsoft Update Catalog'
    Write-Warning "No OSDCloud driver pack matched product '$Product'. Using Microsoft Update Catalog drivers."
}


#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$false
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$true
    WindowsUpdateDrivers = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    MSCatalogFirmware  = [bool]$true
    SetTimeZone = [bool]$false
    ClearDiskConfirm = [bool]$False
    NetFx3 = [bool]$True
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$true
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
