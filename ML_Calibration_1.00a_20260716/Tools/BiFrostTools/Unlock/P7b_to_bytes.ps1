# 讀取二進位檔案
$binaryData = [System.IO.File]::ReadAllBytes("output.p7b")

# 轉換為 Base64 字串
$base64String = [Convert]::ToBase64String($binaryData)

# 轉換為 byte 陣列（使用 ASCII 編碼避免 BOM）
$bytes = [System.Text.Encoding]::ASCII.GetBytes($base64String)

# 直接寫入 binary.txt，確保無 BOM
[System.IO.File]::WriteAllBytes("binary.txt", $bytes)

Write-Host "Base64 encoded data has been written to 'binary.txt' without BOM."
