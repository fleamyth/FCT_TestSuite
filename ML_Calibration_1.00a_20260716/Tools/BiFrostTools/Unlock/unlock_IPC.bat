cd /d %~dp0
set /p bin=<binary.txt
grpcurl.exe -insecure -d "{ \"unlockSoc\": \"true\",\"useUnlockSignature\": \"true\", \"unlockSignature\": \"%bin%\" }" 192.168.1.51:16137 UefiService/TriggerUefiMfgUnlock  

  
  