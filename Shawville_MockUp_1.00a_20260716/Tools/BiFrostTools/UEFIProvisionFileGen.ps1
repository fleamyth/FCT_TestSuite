param (
    [string]$mac,
    [ValidateSet("BT", "WLAN")]
    [string]$mode
)

# Validate MAC address format
if ($mac.Length -ne 12 -or ($mac -match "[^0-9A-Fa-f]")) {
    Write-Host "wrong mac"
    exit 255
}

# Convert MAC address to byte array
$macByteArray = [byte[]]($mac -split '(.{2})' | Where-Object {$_} | ForEach-Object {[convert]::ToByte($_,16)})

# Determine prefix and output file based on mode
switch ($mode) {
    "BT" {
        $prefix = [byte[]](0x01, 0x06)
        $outputFile = "BT.PROVISION"
    }
    "WLAN" {
        $prefix = [byte[]](0x01, 0x07, 0x01)
        $outputFile = "WLAN.PROVISION"
    }
}

# Combine prefix and MAC address bytes
$finalBytes = $prefix + $macByteArray

# Write to binary file
[System.IO.File]::WriteAllBytes($outputFile, $finalBytes)

Write-Host "Binary file: $outputFile"
exit 0
