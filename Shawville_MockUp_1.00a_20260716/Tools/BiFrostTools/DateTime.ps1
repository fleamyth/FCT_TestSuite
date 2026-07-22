# 取得當前的日期和時間
$currentDateTime = Get-Date

# 格式化日期和時間為 ISO 8601 格式
$formattedDateTime = $currentDateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

Set-Content -Path ".\IPC_DateTime.txt" -Value $formattedDateTime