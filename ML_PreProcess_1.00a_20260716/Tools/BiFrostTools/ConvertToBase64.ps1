# 定义文件路径和名称
param (
    [string]$filePathAndName
)

# 读取文件内容
$fileContent = Get-Content -Path $filePathAndName -Raw

# 将内容转换为字节数组
$bytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)

# 进行 Base64 编码
$base64Content = [Convert]::ToBase64String($bytes)

# 获取当前脚本所在目录
$currentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 定义输出文件名称
$outputFileName = [System.IO.Path]::ChangeExtension((Get-Item $filePathAndName).Name, ".base64")
$outputFilePath = Join-Path -Path $currentDirectory -ChildPath "ConvertToBase64.txt"

# 保存 Base64 编码数据到新文件
Set-Content -Path $outputFilePath -Value $base64Content

Write-Output "文件已成功转换为 Base64 编码并保存到 $outputFilePath"