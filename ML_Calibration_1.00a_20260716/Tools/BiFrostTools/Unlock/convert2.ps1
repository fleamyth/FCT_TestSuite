# 讀取 blob.txt 內容
$jsonContent = Get-Content -Raw -Path "blob.txt" | ConvertFrom-Json

# 取出 unlock_blob 的 Base64 字串
$base64String = $jsonContent.unlock_blob
Write-Host $base64String

# 轉換為 byte 陣列
$binaryData = [Convert]::FromBase64String($base64String)

# 輸出到二進位檔案
[System.IO.File]::WriteAllBytes("output.bin", $binaryData)

Write-Host "Binary file 'output.bin' has been created."
