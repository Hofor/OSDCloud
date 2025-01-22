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
    WindowsUpdate = [bool]$True
    WindowsUpdateDrivers = [bool]$false
    WindowsDefenderUpdate = [bool]$True
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
    NetFx3 = [bool]$True
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$false
    CheckSHA1 = [bool]$true
}

#Region Determine if using native driver packs, or if I want to use extracted drivers on OSDCloudUSB
$Product = (Get-MyComputerProduct)
write-host  "Product: " $Product
write-host "Model " $Model 

$Global:MyOSDCloud.DriverPackName = $Model
write-host $Global:MyOSDCloud.DriverPackName

$DriverPack = Get-OSDCloudDriverPack -Product $Product 
write-host  "Get-OSDCloudDriverPack: " $DriverPack

#$Global:OSDCloud.DriverPackSource
#$DriverPack = "Hofor Drivers"

$Global:OSDCloud.DriverPackOffline = Find-OSDCloudFile -Name $Global:OSDCloud.DriverPack.FileName -Path '\OSDCloud\DriverPacks\' | Sort-Object FullName
$Global:OSDCloud.DriverPackOffline = $Global:OSDCloud.DriverPackOffline | Where-Object {$_.FullName -notlike "C*"} | Where-Object {$_.FullName -notlike "X*"} | Select-Object -First 1
write-host "DriverPackOffline: " $Global:OSDCloud.DriverPackOffline

#HAK
$Source = "E:\OSDCloud\DriverPacks\DISM\$($Manufacturer)\$($Model)"
write-host = "Source : " $Source 


#if ($DriverPack){
#    $Global:MyOSDCloud.DriverPackName = $DriverPack
#}

#write-host $Global:MyOSDCloud.DriverPackName

#If Drivers are expanded on the USB Drive, disable installing a Driver Pack
write-host "If Test-DISMFromOSDCloudUSB"
if ((Test-DISMFromOSDCloudUSB) -eq $true){
    Write-Host "Found Driver Pack Extracted on Cloud USB Flash Drive, disabling Driver Download via OSDCloud" -ForegroundColor Green
    Start-DISMFromOSDCloudUSB
    $Global:MyOSDCloud.DriverPackName = "None"
}
else
{
   Write-Host "Else - No Driver Pack Extracted on USB!"
   #$Global:MyOSDCloud.DriverPackName = 'Microsoft Update Catalog'  
}
#endregion Driver Pack Stuff

#write variables to console
Write-Output $Global:MyOSDCloud

#Launch OSDCloud
Write-Host "Starting OSDCloud" -ForegroundColor Green
write-host "Start-OSDCloud -FindImageFile -OSimageIndex 1 -ZTI"

Start-OSDCloud -FindImageFile -OSimageIndex 1 -ZTI

write-host "OSDCloud Process Complete, Running Custom Actions From Script Before Reboot" -ForegroundColor Green

#Restart
restart-computer
