# 定义 Base64 文件路径和名称
param (
    [string]$base64FilePathAndName
)

# 读取 Base64 文件内容
$base64Content = Get-Content -Path $base64FilePathAndName -Raw

# 获取当前脚本所在目录
$currentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 定义输出文件名称
$outputFileName = [System.IO.Path]::ChangeExtension((Get-Item $base64FilePathAndName).Name, ".txt")
$outputFilePath = Join-Path -Path $currentDirectory -ChildPath "ConvertFromBase64.txt"

# 检查文件内容是否为空
if ([string]::IsNullOrEmpty($base64Content)) {
    # Write-Output "文件内容为空，不进行转换。"
    # 输出空内容到新文件
    Set-Content -Path $outputFilePath -Value ""
    exit
}

# 将 Base64 内容转换为字节数组
$bytes = [Convert]::FromBase64String($base64Content)

# 将字节数组转换为原始字符串
$originalContent = [System.Text.Encoding]::UTF8.GetString($bytes)

# 保存原始字符串到新文件
Set-Content -Path $outputFilePath -Value $originalContent

Write-Output "Base64 编码已成功转换回原始字符串并保存到 $outputFilePath"