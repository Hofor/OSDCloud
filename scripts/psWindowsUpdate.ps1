#Start the Transcript
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-WindowsUpdate-Script.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host "Execute OSD Cloud Cleanup Script" -ForegroundColor Green

#=================================================
#   oobeCloud Settings
#=================================================
$Global:oobeCloud = @{
    #oobeSetDisplay = $true
    #oobeSetRegionLanguage = $true
    #oobeSetDateTime = $true
    #oobeRegisterAutopilot = $false
    #oobeRegisterAutopilotCommand = 'Get-WindowsAutopilotInfo -Online -GroupTag Demo -Assign'
    #oobeRemoveAppxPackage = $true
    #oobeRemoveAppxPackageName = 'CommunicationsApps','OfficeHub','People','Skype','Solitaire','Xbox','ZuneMusic','ZuneVideo'
    #oobeAddCapability = $true
    #oobeAddCapabilityName = 'GroupPolicy','ServerManager','VolumeActivation'
    oobeUpdateDrivers = $true
    oobeUpdateWindows = $true
    #oobeRestartComputer = $true
    #oobeStopComputer = $false
}

function Step-oobeTrustPSGallery {
    [CmdletBinding()]
    param ()
    if ($env:UserName -eq 'defaultuser0') {
        $PSRepository = Get-PSRepository -Name PSGallery
        if ($PSRepository)
        {
            if ($PSRepository.InstallationPolicy -ne 'Trusted')
            {
                Write-Host -ForegroundColor Cyan 'Set-PSRepository PSGallery Trusted'
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            }
        }
    }
}

function Step-oobeExecutionPolicy {
    [CmdletBinding()]
    param ()
    if ($env:UserName -eq 'defaultuser0') {
        if ((Get-ExecutionPolicy) -ne 'RemoteSigned') {
            Write-Host -ForegroundColor Cyan 'Set-ExecutionPolicy RemoteSigned'
            Set-ExecutionPolicy RemoteSigned -Force
        }
    }
}

function Step-oobeUpdateDrivers {
    [CmdletBinding()]
    param ()
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeUpdateDrivers -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Updating Windows Drivers'
        if (!(Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore)) {
            try {
                Install-Module PSWindowsUpdate -Force
                Import-Module PSWindowsUpdate -Force
            }
            catch {
                Write-Warning 'Unable to install PSWindowsUpdate Driver Updates'
            }
        }
        if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
            Start-Process PowerShell.exe -ArgumentList "-Command Install-WindowsUpdate -UpdateType Driver -AcceptAll -IgnoreReboot" -Wait
        }
    }
}
function Step-oobeUpdateWindows {
    [CmdletBinding()]
    param ()
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeUpdateWindows -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Updating Windows'
        if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
            try {
                Install-Module PSWindowsUpdate -Force
                Import-Module PSWindowsUpdate -Force
            }
            catch {
                Write-Warning 'Unable to install PSWindowsUpdate Windows Updates'
            }
        }
        if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
            #Write-Host -ForegroundColor DarkCyan 'Add-WUServiceManager -MicrosoftUpdate -Confirm:$false'
            Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
            #Write-Host -ForegroundColor DarkCyan 'Install-WindowsUpdate -UpdateType Software -AcceptAll -IgnoreReboot'
            #Install-WindowsUpdate -UpdateType Software -AcceptAll -IgnoreReboot -NotTitle 'Malicious'
            #Write-Host -ForegroundColor DarkCyan 'Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot'
            Start-Process PowerShell.exe -ArgumentList "-Command Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotTitle 'Preview', 'Feature update', 'Windows 11, version 25H2','Windows 11, version 26H2'" -Wait
        }
    }
}

#endregion

# Execute functions
Step-oobeExecutionPolicy
Step-oobeTrustPSGallery
Step-oobeUpdateDrivers
Step-oobeUpdateWindows

Stop-Transcript
