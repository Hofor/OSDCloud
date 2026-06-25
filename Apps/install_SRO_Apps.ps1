$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-AppInstall-Script.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host "Execute OSD Cloud App Install Script" -ForegroundColor Green

$usb = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\OSDCloud\Apps\ADSelfServicePlusClientSoftware.msi" } | Select-Object -First 1

Write-Host $usb

$msi = "$($usb.DriveLetter):\OSDCloud\Apps\ADSelfServicePlusClientSoftware.msi"
$mst = "$($usb.DriveLetter):\OSDCloud\Apps\ADSelfServicePlusClientSoftware.mst"

Write-Host $msi
Write-Host $mst

Start-Process msiexec.exe -ArgumentList "/i `"$msi`" TRANSFORMS=`"$mst`" /qn /norestart" -Wait -NoNewWind -PassThru

Stop-Transcript
