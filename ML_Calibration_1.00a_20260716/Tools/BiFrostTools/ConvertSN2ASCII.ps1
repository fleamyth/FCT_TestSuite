param (
    [string]$filePath
)

# Check if the file path is provided
if (-not $filePath) {
    Write-Host "Please provide a file path."
    exit
}

# Read the content of the file
$inputString = Get-Content -Path $filePath -Raw

# Initialize an empty string to store the result
$resultString = ""

# Loop through each character in the input string
foreach ($char in $inputString.ToCharArray()) {
    # Convert the character to its hexadecimal value and append to the result string
    $resultString += [convert]::ToString([int][char]$char, 16)
}

# Define the path to the output file
$outputFilePath = "SN_ASCII.txt"

# Write the result to the output file
Set-Content -Path $outputFilePath -Value $resultString