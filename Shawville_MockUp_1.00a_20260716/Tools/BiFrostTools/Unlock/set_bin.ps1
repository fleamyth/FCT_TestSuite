$binaryContent = Get-Content -Raw -Path "binary.txt"

$batContent = @"
cd /d %~dp0
grpcurl.exe -insecure -d "{ \"unlockSoc\": \"false\", \"useUnlockSignature\": \"true\", \"unlockSignature\": \"$binaryContent\" }" 192.168.1.51:16137 UefiService/TriggerUefiMfgUnlock
"@

$batContent | Out-File -Encoding ASCII -FilePath "unlock_IPC_para.bat"
