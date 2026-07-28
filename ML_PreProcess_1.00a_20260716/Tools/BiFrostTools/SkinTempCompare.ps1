# 設置各個 Skin 的 Low 和 High 範圍
$skin1_Low = 10
$skin1_High = 80
$skin2_Low = 10
$skin2_High = 80
$skin3_Low = 10
$skin3_High = 80
$skin4_Low = 10
$skin4_High = 80
$skin5_Low = 10
$skin5_High = 80
$skin6_Low = 10
$skin6_High = 80
# 讀取外部 JSON 檔案
$jsonFilePath = "GetSkinTemp.txt"
$json = Get-Content $jsonFilePath | ConvertFrom-Json

# 初始化結果變數
$result = 0

# 比對溫度是否在範圍內
foreach ($sample in $json.samples) {
    switch ($sample.name) {
        "skin1" {
            if ($sample.last_value_in_c -ge $skin1_Low -and $sample.last_value_in_c -le $skin1_High) {
                Write-Output "$($sample.name) Temp $($sample.last_value_in_c) in range: $($skin1_Low) ~ $($skin1_High) degree"
            } else {
                Write-Output "$($sample.name) Temp $($sample.last_value_in_c) not in range: $($skin1_Low) ~ $($skin1_High) degree"
		$result = 255
            }
        }
        # "skin2" {
            # if ($sample.last_value_in_c -ge $skin2_Low -and $sample.last_value_in_c -le $skin2_High) {
                # Write-Output "$($sample.name) Temp $($sample.last_value_in_c) in range: $($skin2_Low) ~ $($skin2_High) degree"
            # } else {
                # Write-Output "$($sample.name) Temp $($sample.last_value_in_c) not in range: $($skin2_Low) ~ $($skin2_High) degree"
		# $result = 255
            # }
        # }
        "skin3" {
            if ($sample.last_value_in_c -ge $skin3_Low -and $sample.last_value_in_c -le $skin3_High) {
                Write-Output "$($sample.name) Temp $($sample.last_value_in_c) in range: $($skin3_Low) ~ $($skin3_High) degree"
            } else {
                Write-Output "$($sample.name) Temp $($sample.last_value_in_c) not in range: $($skin3_Low) ~ $($skin3_High) degree"
		$result = 255
            }
        }
        "skin4" {
            if ($sample.last_value_in_c -ge $skin4_Low -and $sample.last_value_in_c -le $skin4_High) {
                Write-Output "$($sample.name) Temp $($sample.last_value_in_c) in range: $($skin4_Low) ~ $($skin4_High) degree"
            } else {
                Write-Output "$($sample.name) Temp $($sample.last_value_in_c) not in range: $($skin4_Low) ~ $($skin4_High) degree"
		$result = 255
            }
        }
       # "skin5" {
           # if ($sample.last_value_in_c -ge $skin5_Low -and $sample.last_value_in_c -le $skin5_High) {
               # Write-Output "$($sample.name) Temp $($sample.last_value_in_c) in range: $($skin5_Low) ~ $($skin5_High) degree"
           # } else {
               # Write-Output "$($sample.name) Temp $($sample.last_value_in_c) not in range: $($skin5_Low) ~ $($skin5_High) degree"
		# $result = 255
           # }
       # }
	   # "skin6" {
           # if ($sample.last_value_in_c -ge $skin6_Low -and $sample.last_value_in_c -le $skin6_High) {
               # Write-Output "$($sample.name) Temp $($sample.last_value_in_c) in range: $($skin6_Low) ~ $($skin6_High) degree"
           # } else {
               # Write-Output "$($sample.name) Temp $($sample.last_value_in_c) not in range: $($skin6_Low) ~ $($skin6_High) degree"
		# $result = 255
           # }
       # }
        default {
            Write-Output "$($sample.name) Temp range not setup: $($sample.last_value_in_c) degree"
        }
    }
}

Write-Output "exit $($result)"
exit $result