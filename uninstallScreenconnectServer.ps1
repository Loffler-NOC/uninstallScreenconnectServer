#Check if Screenconnect Server is installed
$programName = "ScreenConnect"

# Check if the program is installed
$installed = Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -eq $programName }

if ($installed -ne $null) {
    Write-Output "$programName is installed. Continuing to uninstallation."
} else {
    # Check 32-bit registry if not found in 64-bit
    $installed = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -eq $programName }
    if ($installed -ne $null) {
        Write-Output "$programName is installed. Continuing to uninstallation."
    } else {
        Write-Output "$programName is not installed. Exiting script."
        Exit 0
    }
}

#Download the Screenconnect Server msi
try {
    if (-not (Test-Path -Path "C:\Software" -PathType Container)) {
    New-Item -Path "C:\Software" -ItemType Directory
    }
    Invoke-WebRequest -Uri https://cwa.connectwise.com/tools/screenconnect/ControlServerInstaller2019.msi -Outfile C:\Software\ScreenConnectServerInstaller.msi
}
catch {
    Write-Output "Screenconnect Server was not able to be downloaded. Please check that the device is able to reach https://cwa.connectwise.com/tools/screenconnect/ControlServerInstaller2019.msi . Full error message:"
    Write-Output $_
    exit 1
}

#Uninstall Screenconnect Server msi
try {
    Start-Process C:\Windows\System32\msiexec.exe -ArgumentList "/x C:\Software\ScreenConnectServerInstaller.msi /qn /norestart" -wait
}
catch {
    Write-Output "Screenconnect Server failed to uninstall with error: " $_
    exit 1
}

#Clean up the Passly installer
try {
    Remove-Item -Path "C:\Software\ScreenConnectServerInstaller.msi"
}
catch {
    Write-Output "Could not clean up installer. Please check C:\Software\ScreenConnectServerInstaller.msi and see if it was removed. Full error message:"
    Write-Output $_
    exit 1
}

# Check if the program is installed
$installed = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -eq $programName }

if ($installed -ne $null) {
    Write-Output "$programName Failed to uninstall but did not throw an error. Please investigate."
    exit 1
} else {
    # Check 32-bit registry if not found in 64-bit
    $installed = Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -eq $programName }
    if ($installed -ne $null) {
        Write-Output "$programName Failed to uninstall but did not throw an error. Please investigate."
        exit 1
    } else {
        Write-Output "$programName successfully uninstalled."
        exit 0
    }
}
