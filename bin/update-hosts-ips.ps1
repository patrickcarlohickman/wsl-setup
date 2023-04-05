#Requires -RunAsAdministrator

# Any host line that contains this TLD will have the IP address updated.
$wslTld = 'test'

$file = $env:windir + '\System32\drivers\etc\hosts'
$regex = '(?<=^\s*)(\d+\.\d+\.\d+\.\d+)(?=.*\.' + $wslTld + '(\s+|$))'

# Get the current IP address of the wsl instance.
$wslIp = $(wsl -e /bin/bash -c "ip -4 -o address show eth0 | grep -oP """"(?<=inet\s)\d+(\.\d+){3}""""")

Write-Host "Updating hosts file for TLD [.$wslTld] with WSL IP [$wslIp]."

# Use the regex to replace existing IP addresses with the
# current wsl IP address for the wsl TLD defined above.
(Get-Content $file) -replace $regex, $wslIp | Set-Content $file

Write-Host 'hosts file updated.'

# If running in the console, wait for input before closing.
if ($Host.Name -eq "ConsoleHost") {
    Write-Host ""
    Write-Host "Press any key to continue or wait 3 seconds..."

    # Make sure buffered input doesn't "press a key" and skip the ReadKey().
    $Host.UI.RawUI.FlushInputBuffer()

    # Wait for a set time or until a key is pressed.
    $counter = 0
    while (!$Host.UI.RawUI.KeyAvailable -and $counter -lt 3000) {
        Start-Sleep -Milliseconds 100
        $counter = $counter + 100
    }

    # Consume the key if one was pressed.
    if ($Host.UI.RawUI.KeyAvailable) {
        $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyUp") > $null
    }
}
