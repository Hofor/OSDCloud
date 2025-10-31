[CmdletBinding()]
param ()

Start-Transcript -Path "C:\OSDCloud\Logs\Start-OSDCloud.windeploy.specialize.log" -ErrorAction Ignore

Write-Host "OSDCloud Specialize Configuration Starting..." -ForegroundColor Cyan

# 1. Sæt computernavn
$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
$NewComputerName = "SRO-$($Serial)"
Write-Host "Renaming computer to $NewComputerName"
(Get-WmiObject Win32_ComputerSystem).Rename($NewComputerName)

# 2. Opret lokal administratorbruger
#$Username = "SRO-Admin"
#$Password = ConvertTo-SecureString "SRO-ADMIN123456" -AsPlainText -Force
#New-LocalUser -Name $Username -Password $Password -FullName "SRO Local Admin" -Description "Local Admin"
#Add-LocalGroupMember -Group "Administratorer" -Member $Username
#Write-Host "Local admin user '$Username' created"

# 3. Sæt netværksprofil til privat
#Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
#Write-Host "Network profile set to Private"

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
