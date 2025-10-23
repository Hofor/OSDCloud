 Write-Host "Starting Rename Device" -ForegroundColor Cyan
Start-Sleep -Seconds 5

$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
$TargetComputername = $Serial.Substring(4,3)
(Get-WmiObject Win32_ComputerSystem).Rename($TargetComputername )
Start-Sleep -Seconds 5


