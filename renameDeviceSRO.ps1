# cleanup.osdcloud.ch
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-RenameDevice-Script.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore
 
Write-Host "Starting Rename Device" -ForegroundColor Cyan
Start-Sleep -Seconds 5

$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
$TargetComputername = $Serial.Substring(4,3)
Write-Host $TargetComputername
(Get-WmiObject Win32_ComputerSystem).Rename($TargetComputername )
Start-Sleep -Seconds 5

Stop-Transcript
