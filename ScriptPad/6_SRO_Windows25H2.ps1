#region Initialize

#Start the Transcript
$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud.log"
$null = Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore

#Determine the proper Windows environment
if ($env:SystemDrive -eq 'X:') {$WindowsPhase = 'WinPE'}
else {
    $ImageState = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State' -ErrorAction Ignore).ImageState
    if ($env:UserName -eq 'defaultuser0') {$WindowsPhase = 'OOBE'}
    elseif ($ImageState -eq 'IMAGE_STATE_SPECIALIZE_RESEAL_TO_OOBE') {$WindowsPhase = 'Specialize'}
    elseif ($ImageState -eq 'IMAGE_STATE_SPECIALIZE_RESEAL_TO_AUDIT') {$WindowsPhase = 'AuditMode'}
    else {$WindowsPhase = 'Windows'}
}

#Finish initialization
Write-Host -ForegroundColor DarkGray "$ScriptName $ScriptVersion $WindowsPhase"

#Load OSDCloud Functions
Invoke-Expression -Command (Invoke-RestMethod -Uri functions.osdcloud.com)

#endregion
#=================================================
#region WinPE
if ($WindowsPhase -eq 'WinPE') {

    #Write-Host -ForegroundColor Cyan "To start a new PowerShell session, type 'start powershell' and press enter"
    #Write-Host -ForegroundColor Cyan "Start-OSDCloud or Start-OSDCloudGUI can be run in the new PowerShell session"
    #Stop the startup Transcript.  OSDCloud will create its own
    $null = Stop-Transcript -ErrorAction Ignore

    $Params = @{
      OSVersion = "Windows 11"
      OSBuild = "25H2"
      OSEdition = "Enterprise"
      OSLanguage = "da-dk"
      OSLicense = "Volume"
      ZTI = $true
      Firmware = $false
      SkipAutopilot = $true
      SkipODT = $true
      Restart = $true
    }
    Start-OSDCloud @Params

}
#endregion
#=================================================
#region Specialize
if ($WindowsPhase -eq 'Specialize') {
    $null = Stop-Transcript -ErrorAction Ignore
}
#endregion
#=================================================
#region AuditMode
if ($WindowsPhase -eq 'AuditMode') {
    $null = Stop-Transcript -ErrorAction Ignore
}
#endregion
#=================================================
#region OOBE
if ($WindowsPhase -eq 'OOBE') {

    Write-Host -ForegroundColor Cyan 'WindowsPhase OOBE'  
    osdcloud-RemoveAppx -Basic
    osdcloud-NetFX
    osdcloud-UpdateDrivers
    osdcloud-UpdateDefenderStack
    osdcloud-UpdateWindows
  
    $null = Stop-Transcript -ErrorAction Ignore
    osdcloud-RestartComputer
}
#endregion
#=================================================
#region Windows
if ($WindowsPhase -eq 'Windows') {

    #Load OSD and Azure stuff
    Write-Host -ForegroundColor Cyan 'WindowsPhase Windows'
    #Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/_oobe.psm1')
    #Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/_anywhere.psm1')
    #Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/_oobewin.psm1')
    #Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/autopilot.psm1')
    #Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/defender.psm1')
     
    osdcloud-SetExecutionPolicy
    #osdcloud-InstallPackageManagement
    #osdcloud-InstallModuleKeyVault
    osdcloud-InstallModuleOSD
    #osdcloud-InstallModuleAzureAD
    
    osdcloud-RemoveAppx -Basic
    osdcloud-UpdateDefenderStack
    osdcloud-NetFX
    
    $null = Stop-Transcript -ErrorAction Ignore
}
#endregion
#=================================================
