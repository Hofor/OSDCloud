#Download & Extract to Program Files
$FileName = ".msi"
$mstPath = "" #Local path på USB
$URL = "https://download.microsoft.com/download/C/7/A/C7AAD914-A8A6-4904-88A1-29E657445D03/$FileName"
$DownloadTempFile = "$env:TEMP\$FileName"



$Download = Start-BitsTransfer -Source $URL -Destination $DownloadTempFile -DisplayName $FileName

if (Test-Path -Path $DownloadTempFile)
{
    Write-Output "Successfully Downloaded $FileName"
}
else
{
    Write-Output "Failed to Downloaded $FileName"
    exit 253    
}

$args = "/i `"$DownloadTempFile`" TRANSFORMS=`"$mstPath`" /qb!"

Start-Process -FilePath "msiexec.exe" -ArgumentList $args -Wait -NoNewWind -PassThru

if ($Install.ExitCode -eq 0)
{
    Write-Output "Installation Exit Successfully"
}
