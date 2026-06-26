Invoke-Expression -Command (Invoke-RestMethod -Uri functions.osdcloud.com)

$Manufacturer = (Get-CimInstance -Class:Win32_ComputerSystem).Manufacturer
$Model = (Get-CimInstance -Class:Win32_ComputerSystem).Model

#Variables to define the Windows OS / Edition etc to be applied during OSDCloud
$Product = (Get-MyComputerProduct)
$Model = (Get-MyComputerModel)
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$OSVersion = 'Windows 11' #Used to Determine Driver Pack
$OSReleaseID = '25H2' #Used to Determine Driver Pack
$OSName = 'Windows 11 25H2 x64'
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
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
    NetFx3 = [bool]$True
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$true
    CheckSHA1 = [bool]$true
}

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
   $Global:MyOSDCloud.DriverPackName = 'Microsoft Update Catalog'  
}
#endregion Driver Pack Stuff

#write variables to console
Write-Output $Global:MyOSDCloud

#Launch OSDCloud
Write-Host "Starting OSDCloud" -ForegroundColor Green
write-host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage -SkipAutopilot -ZTI

write-host "Invoke Copy Start-OSDCloud.windeploy.specialize.ps1"
Invoke-WebRequest 'https://raw.githubusercontent.com/Hofor/OSDCloud/refs/heads/main/SRO/SRO-FJV-OSDCloud.windeploy.specialize.ps1' -OutFile "C:\Windows\System32\OOBE\Start-OSDCloud.windeploy.specialize.ps1"

write-host "Invoke Copy Start-OSDCloud.windeploy.specialize.ps1"
Invoke-WebRequest 'https://raw.githubusercontent.com/Hofor/OSDCloud/refs/heads/main/SRO/SRO-FJV-OSDCloud.windeploy.specialize.ps1' -OutFile "C:\Windows\System32\OOBE\Start-OSDCloud.windeploy.xxxx.ps1"

write-host "Set Content In unattend.xml"
Invoke-WebRequest 'https://raw.githubusercontent.com/Hofor/OSDCloud/refs/heads/main/SRO/SRO-FJV-unattend.xml' -OutFile "C:\Windows\Panther\unattend.xml"

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
$OOBEDeployJson = @'
{
    "AddNetFX3":  {
                      "IsPresent":  false
                  },
    "Autopilot":  {
                      "IsPresent":  false
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
                    "Microsoft.MicrosoftStickyNotes",
                    "Microsoft.MSPaint",
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
                   ],
    "UpdateDrivers":  {
                          "IsPresent":  true
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================

Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
#Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Hofor/OSDCloud/refs/heads/main/Apps/install_SRO_Apps.ps1
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Hofor/OSDCloud/refs/heads/main/scripts/cleanupOSD.ps1
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#Restart Computer from WInPE into Full OS to continue Process
restart-computer

