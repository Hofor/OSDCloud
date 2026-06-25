$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-AppInstall-Script.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host "Execute OSD Cloud App Install Script" -ForegroundColor Green

$msiPath = $null
$mstPath = $null

# Scan alle drevbogstaver robust
foreach ($letter in [char]'C'..[char]'Z') {

    $msiTest = "$letter`:\OSDCloud\Apps\ADSelfServicePlusClientSoftware.msi"
    $mstTest = "$letter`:\OSDCloud\Apps\ADSelfServicePlusClientSoftware.mst"

    if (Test-Path $msiTest) {
        $msiPath = $msiTest

        if (Test-Path $mstTest) {
            $mstPath = $mstTest
        }

        Write-Host "Fundet installationsfiler på drev: $letter" -ForegroundColor Green
        break
    }
}

# Stop hvis MSI ikke findes
if (-not $msiPath) {
    Write-Host "MSI ikke fundet på nogen drev!" -ForegroundColor Red
    exit 1
}

Write-Host "MSI: $msiPath"

if ($mstPath) {
    Write-Host "MST: $mstPath"
} else {
    Write-Host "MST ikke fundet - fortsætter uden transform" -ForegroundColor Yellow
}

# Byg argumenter
$arguments = "/i `"$msiPath`" /qn /norestart"

if ($mstPath) {
    $arguments = "/i `"$msiPath`" TRANSFORMS=`"$mstPath`" /qn /norestart"
}

# Kør installation
Start-Process msiexec.exe -ArgumentList $arguments -Wait -NoNewWindow

Write-Host "Installation completed"

<#$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-AppInstall-Script.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host "Execute OSD Cloud App Install Script" -ForegroundColor Green

$usb = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\OSDCloud\Apps\ADSelfServicePlusClientSoftware.msi" } | Select-Object -First 1

Write-Host $usb

$msi = "$($usb.DriveLetter):\OSDCloud\Apps\ADSelfServicePlusClientSoftware.msi"
$mst = "$($usb.DriveLetter):\OSDCloud\Apps\ADSelfServicePlusClientSoftware.mst"

Write-Host $msi
Write-Host $mst

Start-Process msiexec.exe -ArgumentList "/i `"$msi`" TRANSFORMS=`"$mst`" /qn /norestart" -Wait -NoNewWind -PassThru
#>

Stop-Transcript
