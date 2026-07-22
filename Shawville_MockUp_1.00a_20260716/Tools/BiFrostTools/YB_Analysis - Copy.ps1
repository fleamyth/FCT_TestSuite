# 讀取 JSON 文件
$jsonData = Get-Content -Path ".\GetHardwareComponents.txt" | ConvertFrom-Json

# 提取 DriverList 鍵中的人員列表
$driverList = $jsonData.driver_status

# 設定多個例外清單
$exceptionList = @("Surface Meteorlake SPT Client", "Surface Machine Learning Service Driver")

# 列印出Status 非 OK 
$filteredData = $driverList | Where-Object {$_.status -ne "OK" }
#Write-Output "Count after filtering people who status not equ OK: $($filteredData.Count)"


# Count is an intrinsic property added to nearly all scalar objects in PowerShell. What you've encountered is a bug in Windows PowerShell (v5.1 or lower) that was fixed in version 6. It affects [pscustomobject] and [ciminstance] instances.

# Windows PowerShell bug, fixed in v6:
# ([pscustomobject] @{ foo = 'bar' }).Count # $null
# To workaround this, use the array subexpression operator (@(...)) to guarantee output is collected in an array, which does have a Count property.

# 排除例外清單 
$filteredExceptData = @($filteredData | Where-Object { -not ($exceptionList -contains $_.name) })
#Write-Output "Count after filtering people who are not in the exception list: $($filteredExceptData.Count)"

$filteredExceptData | ForEach-Object { Write-Output $_.name }

# 根據篩選結果返回 1 或 0
if ($filteredExceptData.Count -gt 0) {
 Write-Output "exit 1"
    exit 1
} else {
 Write-Output "exit 0"
    exit 0
}