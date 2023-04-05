#Requires -RunAsAdministrator

Param(
    [Parameter(Mandatory=$false)]
    $wslHost
)

if (!$PSBoundParameters.ContainsKey('wslHost')) {
    $wslHost = Read-Host -Prompt 'Enter new hostname to add'
    Write-Host ""
}

$file = $env:windir + '\System32\drivers\etc\hosts'

# Get the current IP address of the wsl instance.
$wslIp = $(wsl -e /bin/bash -c "ip -4 -o address show eth0 | grep -oP """"(?<=inet\s)\d+(\.\d+){3}""""")

# Read the last byte of the file.
$size = 1
$buffer = new-object Byte[] $size
$fs = [IO.File]::OpenRead($file)
$fs.Seek(-$size, [System.IO.SeekOrigin]::End) | Out-Null
$fs.Read($buffer, 0, $size) | Out-Null
$fs.Close()

Write-Host "Adding new hosts entry for host [$wslHost]."

# If the file doesn't end with a newline (chr 10), add a newline.
if ($buffer[0] -ne 10) {
    Add-Content -Path $file -Value ""
}

# Add the new host line.
Add-Content -Path $file -Value "$wslIp`t$wslHost"

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
