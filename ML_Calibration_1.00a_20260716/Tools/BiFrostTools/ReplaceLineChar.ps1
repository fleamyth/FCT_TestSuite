# 讀取文件內容
$content = Get-Content -Path "MEInfo.txt" -Raw

# 替換 \r\n 為實際的換行符
$content = $content -replace '\\r\\n', "`n"

# 將修改後的內容寫回文件
Set-Content -Path "MEInfo.txt" -Value $content
Write-Host "文件中的 \r\n 字串已替換成實際的換行符。"
