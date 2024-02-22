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
        exit 0
    }
}

#Find the screenconnect msi
# Define the registry path to search
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData"
$msiUninstallString

# Get all subkeys under the registry path
$subKeys = Get-ChildItem -Path $registryPath -Recurse | Where-Object { $_.Name -match 'InstallProperties' }

# Loop through each subkey
foreach ($subKey in $subKeys) {
    $displayName = Get-ItemProperty -Path $subKey.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue
    if ($displayName -ne $null -and $displayName.DisplayName -eq "Screenconnect") {
        Write-Output "Found DisplayName: $($displayName.DisplayName)"
        # Check if UninstallString key exists
        $uninstallString = Get-ItemProperty -Path $subKey.PSPath -Name "UninstallString" -ErrorAction SilentlyContinue
        if ($uninstallString -ne $null) {
            Write-Output "Found UninstallString: $($uninstallString.UninstallString)"
            $msiUninstallString = $($uninstallString.UninstallString)
            Write-Output "Found uninstall string: $msiUninstallString"
        } else {
            Write-Output "UninstallString not found in $($subKey.Name)"
            exit 1
        }
    }
}

#Parse uninstall key from uninstall string
# Define the regular expression pattern
$regexPattern = "\{(.*?)\}"

# Perform the regex match
$match = [regex]::Match($msiUninstallString, $regexPattern)

# Check if a match is found
if ($match.Success) {
    # Extract the captured group
    $uninstallCode = $match.Groups[1].Value
    Write-Output "Uninstall Code: $uninstallCode"
} else {
    Write-Output "No uninstall code found."
    exit 1
}

#Uninstall Screenconnect Server msi
try {
    Write-Output "Attempting to uninstall $programName"
    Start-Process C:\Windows\System32\msiexec.exe -ArgumentList "/x{$uninstallCode} /qn /norestart" -wait
}
catch {
    Write-Output "Screenconnect Server failed to uninstall with error: " $_
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
