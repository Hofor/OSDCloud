#Start the Transcript
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-removeAppx-Script.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore
 
#Write-Host "Removing unwanted AppX packages..." -ForegroundColor Cyan

$AppxPackages = @(
    "Microsoft.BingWeather",
    "Microsoft.BingNews",
    "Microsoft.GamingApp",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.Todos",
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
    "MicrosoftTeams",
    "MSTeams",
    "Clipchamp.Clipchamp",
    "MicrosoftCorporationII.QuickAssist",
    "Microsoft.OutlookForWindows",
    "Microsoft.Windows.DevHome"

)

foreach ($Package in $AppxPackages) {

    #Write-Host "Removing $Package"

    Get-AppxPackage -AllUsers -Name $Package -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    Get-AppxProvisionedPackage -Online |
        Where-Object DisplayName -eq $Package |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}


Stop-Transcript
