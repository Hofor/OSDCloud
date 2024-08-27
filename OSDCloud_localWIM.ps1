Invoke-Expression -Command (Invoke-RestMethod -Uri functions.osdcloud.com)

<#
$Manufacturer = (Get-CimInstance -Class:Win32_ComputerSystem).Manufacturer
$Model = (Get-CimInstance -Class:Win32_ComputerSystem).Model
$HPTPM = $false
$HPBIOS = $false
$HPIADrivers = $false

if ($Manufacturer -match "HP" -or $Manufacturer -match "Hewlett-Packard"){
    $Manufacturer = "HP"
    if ($InternetConnection){
        $HPEnterprise = Test-HPIASupport
    }
}
if ($HPEnterprise){
    Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/deviceshp.psm1')
    osdcloud-InstallModuleHPCMSL
    $TPM = osdcloud-HPTPMDetermine
    $BIOS = osdcloud-HPBIOSDetermine
    $HPIADrivers = $true
    if ($TPM){
    write-host "HP Update TPM Firmware: $TPM - Requires Interaction" -ForegroundColor Yellow
        $HPTPM = $true
    }
    Else {
        $HPTPM = $false
    }

    if ($BIOS -eq $false){
        $CurrentVer = Get-HPBIOSVersion
        write-host "HP System Firmware already Current: $CurrentVer" -ForegroundColor Green
        $HPBIOS = $false
    }
    else
        {
        $LatestVer = (Get-HPBIOSUpdates -Latest).ver
        $CurrentVer = Get-HPBIOSVersion
        write-host "HP Update System Firmwware from $CurrentVer to $LatestVer" -ForegroundColor Yellow
        $HPBIOS = $true
    }
}

#>

#Variables to define the Windows OS / Edition etc to be applied during OSDCloud
$Product = (Get-MyComputerProduct)
$Model = (Get-MyComputerModel)
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$OSVersion = 'Windows 11' #Used to Determine Driver Pack
$OSReleaseID = '23H2' #Used to Determine Driver Pack
$OSName = 'D:\OSDCloud\OS\CustomImage.wim'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage = 'da-dk'


#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$False
    RecoveryPartition = [bool]$true
    #OEMActivation = [bool]$True
    WindowsUpdate = [bool]$true
    WindowsUpdateDrivers = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
	NetFx3 = [bool]$True
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$true
    CheckSHA1 = [bool]$true
}


#write variables to console
Write-Output $Global:MyOSDCloud

#Update Files in Module that have been updated since last PowerShell Gallery Build (Testing Only)
$ModulePath = (Get-ChildItem -Path "$($Env:ProgramFiles)\WindowsPowerShell\Modules\osd" | Where-Object {$_.Attributes -match "Directory"} | select -Last 1).fullname
import-module "$ModulePath\OSD.psd1" -Force

#Launch OSDCloud
Write-Host "Starting OSDCloud" -ForegroundColor Green
write-host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"

Start-OSDCloud -OSName $OSName 

write-host "OSDCloud Process Complete, Running Custom Actions From Script Before Reboot" -ForegroundColor Green
