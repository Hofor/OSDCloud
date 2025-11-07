[CmdletBinding()]
param ()

Start-Transcript -Path "C:\OSDCloud\Logs\Start-OSDCloud.windeploy.specialize.log" -ErrorAction Ignore

Write-Host "OSDCloud Specialize Configuration Starting..." -ForegroundColor Cyan

# 1. Sæt computernavn
$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
$NewComputerName = "SRO-FJV-$($Serial)"
Write-Host "Renaming computer to $NewComputerName"
(Get-WmiObject Win32_ComputerSystem).Rename($NewComputerName)

# 2. Fjern uønskede Windows Capabilities
Write-Host "Fjern uønskede Windows Capabilities" -ForegroundColor Green

$CapabilitiesToRemove = @(
    "OpenSSH.Client~~~~0.0.1.0",
    "XPS.Viewer~~~~0.0.1.0",
    "Microsoft.Windows.WordPad~~~~0.0.1.0",
	"OneCoreUAP.OneSync~~~~0.0.1.0",
	"Print.Management.Console~~~~0.0.1.0",
	"Media.WindowsMediaPlayer~~~~0.0.12.0",
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

# 3. Fjern uønskede Inbox Apps
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
		"MicrosoftCorporationII.QuickAssist"
)

Write-Host "Fjern uønskede Inbox Apps" -ForegroundColor Green

foreach ($app in $AppsToRemove) {
    Write-Host "Removing app: $app"
    Get-AppxPackage -Name $app | Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online
}

# 4. Registry Settings for WSUS:
Write-Host "Registry Settings for WSUS" -ForegroundColor Green
new-item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name WUServer -Value 'http://10.209.148.16:8530'
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name WUStatusServer -Value 'http://10.209.148.16:8530'

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR" -Name Start -Value 4

# 6. Firewall Settings:
write-Host "Firewall Settings" -ForegroundColor Green
# Åbn outbound TCP port 3389 for privat profil
New-NetFirewallRule -DisplayName "Allow Outbound TCP 3389 - Private" -Direction Outbound -Protocol TCP -LocalPort 3389 -Action Allow -Profile Private, Domain, Public

# Åbn outbound UDP port 3389 for privat profil
New-NetFirewallRule -DisplayName "Allow Outbound UDP 3389 - Private" -Direction Outbound -Protocol UDP -LocalPort 3389 -Action Allow -Profile Private, Domain, Public

# Åbn outbound TCP port 3850 for privat profil
New-NetFirewallRule -DisplayName "Allow Outbound TCP 3850 - Private" -Direction Outbound -Protocol TCP -LocalPort 3850 -Action Allow -Profile Private, Domain, Public

# Åbn outbound TCP port 3851 for privat profil
New-NetFirewallRule -DisplayName "Allow Outbound TCP 3851 - Private" -Direction Outbound -Protocol TCP -LocalPort 3851 -Action Allow -Profile Private, Domain, Public

#Åben for WSUS
# Tillad inbound TCP trafik på port 8530 for Private profil
New-NetFirewallRule -DisplayName "Allow Inbound WSUS 10.209.148.16 TCP 8530 - Private" -Direction Inbound -Protocol TCP -LocalPort 8530 -Action Allow -Profile Private, Domain, Public

# Tillad outbound TCP trafik på port 8530 for Private profil
New-NetFirewallRule -DisplayName "Allow Outbound WSUS to 10.209.148.16 TCP 8530" -Direction Outbound -Protocol TCP -RemoteAddress 10.209.148.16 -RemotePort 8530 -Action Allow -Profile Private, Domain, Public

#Block alle outbound trafik
write-Host "Block All Outbound - Domain Profile" -ForegroundColor Green
Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction block -NotifyOnListen False -AllowUnicastResponseToMulticast True  -Profile Domain

#Block alle og outbound trafik
write-Host "Block All Outbound - Private Profile" -ForegroundColor Green
Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction block -NotifyOnListen False -AllowUnicastResponseToMulticast True  -Profile Private

#New-NetFirewallRule -DisplayName "Block All Outbound - Public Profile" -Direction Outbound -Action Block -Profile Public -Enabled True -PolicyStore ActiveStore
#New-NetFirewallRule -DisplayName "Block All Outbound - Domain Profile" -Direction Outbound -Action Block -Profile Domain -Enabled True -PolicyStore ActiveStore
#Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction block -NotifyOnListen False -AllowUnicastResponseToMulticast True  -Profile Domain

# 7. Sæt netværksprofil til privat
#Write-Host "Network profile set to Private"
#Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

$temp = Get-NetConnectionProfile
#Write-Host $temp.NetworkCategory

# 6. Forbered til OOBE
<#
try {
	Write-Host "Specialize configuration. Proceeding to OOBE..." -ForegroundColor Green
	
	Set-ItemProperty -Path "HKLM:\System\Setup" -Name CmdLine -Value 'PowerShell.exe -ExecutionPolicy Bypass -File C:\Windows\System32\OOBE\Start-OOBEDeploy.ps1'
	$regedit = Get-ItemProperty -Path "HKLM:\System\Setup" -Name CmdLine
	write-host "Get-ItemProperty: $($regedit)" -ForegroundColor Green
	#Set-ItemProperty -Path "HKLM:\System\Setup" -Name CmdLine -Value 'PowerShell -ExecutionPolicy Bypass -Command Start-OSDCloud.windeploy.oobe'

	if(test-path "$env:SystemRoot\System32\OOBE\WinDeploy.exe")
	{
		write-host "Findes"
	}
	else
	{
		write-host "Findes ikke"
	}
	
	Write-Host "*Starting WinDeploy.exe..." -ForegroundColor Green
	Start-Process -WorkingDirectory "$env:SystemRoot\System32\OOBE\" -FilePath WinDeploy.exe
	
	Write-Host "Specialize configuration complete. Proceeding to OOBE..." -ForegroundColor Green
} 
catch 
{
    Write-Host "Fejl under forberedelse af OOBE: $_"
}
#>
Stop-Transcript
