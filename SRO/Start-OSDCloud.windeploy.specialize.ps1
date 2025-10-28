[CmdletBinding()]
param ()

$Global:Transcript = "SRO-OBBE-Phase.log"
Start-Transcript -Path (Join-Path "$env:OSDCloud\Logs\" $Global:Transcript) -ErrorAction Ignore

Write-Host "OSDCloud Specialize Configuration Starting..." -ForegroundColor Cyan

# 1. Sæt computernavn
$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
$NewComputerName = "SRO-$($Serial)"
Write-Host "Renaming computer to $NewComputerName"
(Get-WmiObject Win32_ComputerSystem).Rename($NewComputerName)

# 2. Opret lokal administratorbruger
$Username = "SRO-Admin"
$Password = ConvertTo-SecureString "SRO-ADMIN123456" -AsPlainText -Force
New-LocalUser -Name $Username -Password $Password -FullName "SRO Local Admin" -Description "Local Admin"
Add-LocalGroupMember -Group "Administratorer" -Member $Username
Write-Host "Local admin user '$Username' created"

# 3. Sæt netværksprofil til privat
#Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
#Write-Host "Network profile set to Private"


# 4. Fjern uønskede Windows Capabilities
Write-Host "Fjern uønskede Windows Capabilities" -ForegroundColor Green
<#
$CapabilitiesToRemove = @(
    "OpenSSH.Client~~~~0.0.1.0",
    "XPS.Viewer~~~~0.0.1.0",
    "Microsoft.Windows.WordPad~~~~0.0.1.0",
	"OneCoreUAP.OneSync~~~~0.0.1.0",
	"Print.Management.Console~~~~0.0.1.0",
	"VBSCRIPT~~~~",
	"Media.WindowsMediaPlayer~~~~0.0.12.0",
	"Microsoft.Windows.PowerShell.ISE",
	"Microsoft.Wallpapers.Extended",
	"MathRecognizer~~~~0.0.1.0",
	"Language.TextToSpeech~~~da-DK~0.0.1.0",
	"App.StepsRecorder~~~~0.0.1.0",
	"Browser.InternetExplorer~~~~0.0.11.0",
	"MathRecognizer~~~~0.0.1.0"
)

foreach ($cap in $CapabilitiesToRemove) {
    Write-Host "Removing capability: $cap"
    Remove-WindowsCapability -Online -Name $cap
}
#>
# 5. Fjern uønskede Inbox Apps
<#
$AppsToRemove = @(
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
        "Microsoft.ZuneVideo",
	    "Microsoft.XboxApp",
        "Microsoft.OneNote",
        "Microsoft.MicrosoftSolitaireCollection",
		"AppUp.ThunderboltControlCenter",
		"DolbyLaboratories.DolbyAccess",
		"DolbyLaboratories.DolbyDigitalPlusDecoderOEM",
		"Microsoft.BingSearch",
		"Microsoft.Edge.GameAssist",
		"Microsoft.MicrosoftEdge.Stable",
		"Microsoft.OutlookForWindows",
		"Microsoft.OutlookForWindows_1.0.0.0_neutral__8wekyb3d8bbwe",
		"Microsoft.Paint",
		"Microsoft.Windows.DevHome",
		"Microsoft.Windows.Photos",
		"Microsoft.WindowsAlarms",
		"Microsoft.WindowsCalculator",
		"Microsoft.WindowsNotepad",
		"Microsoft.WindowsStore",
		"Microsoft.WindowsTerminal",
		"MicrosoftCorporationII.QuickAssist",
		"MicrosoftWindows.Client.WebExperience"
)
#>

Write-Host "Fjern uønskede Inbox Apps" -ForegroundColor Green

foreach ($app in $AppsToRemove) {
    Write-Host "Removing app: $app"
    Get-AppxPackage -Name $app | Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online
}

# 6. Forbered til OOBE
try {
	Write-Host "Specialize configuration. Proceeding to OOBE..." -ForegroundColor Green
	
	Set-ItemProperty -Path "HKLM:\System\Setup" -Name CmdLine -Value 'PowerShell -ExecutionPolicy Bypass -File C:\Windows\System32\OOBE\Start-OOBEDeploy.ps1'
	
	#Set-ItemProperty -Path "HKLM:\System\Setup" -Name CmdLine -Value 'PowerShell -ExecutionPolicy Bypass -Command Start-OSDCloud.windeploy.oobe'
	Start-Process -WorkingDirectory "$env:SystemRoot\System32\OOBE" -FilePath WinDeploy.exe
	
	Write-Host "Specialize configuration complete. Proceeding to OOBE..." -ForegroundColor Green
} catch {
    Write-Host "Fejl under forberedelse af OOBE: $_"
}
Stop-Transcript
