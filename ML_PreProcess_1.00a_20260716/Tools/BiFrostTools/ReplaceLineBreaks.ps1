param (
    [string]$InputFile = "MEInfo.txt",
    [string]$OutputFile = "MEInfo_Modified.txt"
)

# 讀取文件內容 
$content = Get-Content -Path $InputFile -Raw

# 替換 \r\n 為實際的換行符 
$content = $content -replace '\\r\\n', "`n"

# 將修改後的內容寫回文件 
Set-Content -Path $OutputFile -Value $content

Write-Host "Done. Output saved to $OutputFile"
