$usb = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\OSDCloud\Apps\ADSelfServicePlusClientSoftware.msi" } | Select-Object -First 1

$msi = "$($usb.DriveLetter):\OSDCloud\Apps\ADSelfServicePlusClientSoftware.msi"
$mst = "$($usb.DriveLetter):\OSDCloud\Apps\ADSelfServicePlusClientSoftware.mst"

Start-Process msiexec.exe -ArgumentList "/i `"$msi`" TRANSFORMS=`"$mst`" /qn /norestart" -Wait -NoNewWind -PassThru
