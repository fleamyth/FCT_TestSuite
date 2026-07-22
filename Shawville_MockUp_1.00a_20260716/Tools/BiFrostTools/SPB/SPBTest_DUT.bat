del /q spbTestTool.txt

echo timeout 3 >kill.bat
echo taskkill /f /t /im "spbTestTool.exe" >>kill.bat
start kill.bat

echo open> test.txt
echo write {20 00 01 00}>> test.txt
echo write {20 00 01 00}>> test.txt
echo write {20 00 01 00}>> test.txt
echo close>> test.txt

spbTestTool.exe /i test.txt > spbTestTool.txt  2>&1
exit /b 0