@ECHO ON
cd %~dp0
setlocal EnableDelayedExpansion
rem grpcui.exe -insecure 192.168.1.51:16133

:Start
SET DUT_IP=192.168.1.51
SET ServicePorts=16133
if EXIST ..\sn.dat IF "%SN%" EQU "" SET /p SN=<..\sn.dat
if EXIST ..\TSRID.dat IF "%TSRID%" EQU "" SET /p TSRID=<..\TSRID.dat
if EXIST ..\TSRID_DB.dat IF "%TSRID_DB%" EQU "" SET /p TSRID_DB=<..\TSRID_DB.dat
if EXIST ..\TestItems_Count.flg SET /p TestItems_Count=<..\TestItems_Count.flg  & SET TestItems_Count=!TestItems_Count: =!
if defined TSRID_DB set TSRID_DB=%TSRID_DB: =%
SET SkipCountAdd=False
If "%SkipCountAdd%"=="False" (
	set /a TestItems_Count+=1
	echo !TestItems_Count! > ..\TestItems_Count.flg
)
SET RTN=

:Function
if /I "%1"=="NfcChipId" goto Get_NFC_ChipID
if /I "%1"=="NfcSelfTest1" goto Get_NFC_AntennaSelfTestLoop1
if /I "%1"=="NfcSelfTest2" goto Get_NFC_AntennaSelfTestLoop2
if /I "%1"=="GetWifiMac" goto Get_Wifi_MacAddress
if /I "%1"=="SetWifiMac" goto Set_Wifi_MacAddress
if /I "%1"=="GetBtMac" goto Get_BT_MacAddress
if /I "%1"=="SetBtMac" goto Set_BT_MacAddress
if /I "%1"=="GetCellularMac" goto Get_Cellular_MacAddress
if /I "%1"=="SetCellularMac" goto Set_Cellular_MacAddress
if /I "%1"=="GetGpsMac" goto Get_GPS_MacAddress
if /I "%1"=="SetGpsMac" goto Set_GPS_MacAddress
if /I "%1"=="FlashModemFW" goto Flash_Modem_FW
if /I "%1"=="GetEID" goto Get_EID
if /I "%1"=="GetIMEI" goto Get_IMEI
if /I "%1"=="SetIMEI" goto Set_IMEI
if /I "%1"=="" goto NoParameter
goto NoParameter

	
:Get_NFC_ChipID
	set TestItem=%TestItems_Count%_Get_NFC_ChipID
	set BFLogFile=GetNFCChipID
	set LogFile=GetNFCChipID.txt

	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -emit-defaults -insecure -d "{}" %DUT_IP%:%ServicePorts% NfcService/GetNfcChipId > !LogFile! 2>&1 
	findstr /c:"\"failed_nci_cmd\"" !LogFile! 
	if !errorlevel! equ 0 goto fail

	findstr /c:"\"nfc_chip_id\": 0" !LogFile! 
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)

:Get_NFC_AntennaSelfTestLoop1
	set TestItem=%TestItems_Count%_Get_NFC_AntennaSelfTestLoop1
	set BFLogFile=GetNFCAntennaSelfTestLoop1
	set LogFile=GetNFCAntennaSelfTestLoop1.txt

	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -emit-defaults -insecure -d "{}" %DUT_IP%:%ServicePorts% NfcService/NfcAntennaSelfTestLoop1 > !LogFile! 2>&1 
	findstr /c:"\"failed_nci_cmd\"" !LogFile! 
	if !errorlevel! equ 0 goto fail

	findstr /c:"\"nfc_antenna_tx_ldo_current\": 0" !LogFile! 
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:Get_NFC_AntennaSelfTestLoop2
	set TestItem=%TestItems_Count%_Get_NFC_AntennaSelfTestLoop2
	set BFLogFile=GetNFCAntennaSelfTestLoop2
	set LogFile=GetNFCAntennaSelfTestLoop2.txt

	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -emit-defaults -insecure -d "{}" %DUT_IP%:%ServicePorts% NfcService/NfcAntennaSelfTestLoop2 > !LogFile! 2>&1 
	findstr /c:"\"failed_nci_cmd\"" !LogFile! 
	if !errorlevel! equ 0 goto fail

	findstr /c:"\"nfc_antenna_rssi\": 0" !LogFile! 
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)

:Get_Cellular_MacAddress
	set TestItem=%TestItems_Count%_Get_Cellular_MacAddress
	set TechnologyType=CELLULAR
	set BFLogFile=GetCellularMacAddress
	set LogFile=GetCellularMacAddress.txt
	goto Get_MacAddress

:Get_GPS_MacAddress
	set TestItem=%TestItems_Count%_Get_GPS_MacAddress
	set TechnologyType=GPS
	set BFLogFile=GetGpsMacAddress
	set LogFile=GetGpsMacAddress.txt
	goto Get_MacAddress
	
:Get_Wifi_MacAddress
	set TestItem=%TestItems_Count%_Get_Wifi_MacAddress
	set TechnologyType=WIFI
	set BFLogFile=GetWifiMacAddress
	set LogFile=GetWifiMacAddress.txt
	goto Get_MacAddress

:Get_BT_MacAddress
	set TestItem=%TestItems_Count%_Get_Bt_MacAddress
	set TechnologyType=BLUETOOTH
	set BFLogFile=GetBtMacAddress
	set LogFile=GetBtMacAddress.txt
	goto Get_MacAddress














	
:Get_MacAddress
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -emit-defaults -insecure -d "{\"technologyType\": \"%TechnologyType%\"}" %DUT_IP%:%ServicePorts% RadioMacAddressService/GetMacAddress > !LogFile! 2>&1 
	findstr /c:"\"mac_address\"" !LogFile! 
	if !errorlevel! neq 0 goto fail

	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (!LogFile!) do (
		if "%%j"=="mac_address" set Reading=%%l
	)

	echo Reading=!Reading::=!
	echo !Reading::=!> Mac_%TechnologyType%.txt
	find /i "000000000000" Mac_%TechnologyType%.txt
	if %errorlevel% neq 1 goto fail
	find /i "FFFFFFFFFFFF"  Mac_%TechnologyType%.txt
	if %errorlevel% neq 1 goto fail
	find /i "888888888888"  Mac_%TechnologyType%.txt
	if %errorlevel% neq 1 goto fail
	goto pass

:Set_Cellular_MacAddress
	set TestItem=%TestItems_Count%_Set_Cellular_MacAddress
	set TechnologyType=CELLULAR
	set BFLogFile=SetCellularMacAddress
	set LogFile=SetCellularMacAddress.txt
	goto Set_MacAddress

:Set_GPS_MacAddress
	set TestItem=%TestItems_Count%_Set_GPS_MacAddress
	set TechnologyType=GPS
	set BFLogFile=SetGpsMacAddress
	set LogFile=SetGpsMacAddress.txt
	goto Set_MacAddress
	
:Set_Wifi_MacAddress
	set TestItem=%TestItems_Count%_Set_Wifi_MacAddress
	set TechnologyType=WIFI
	set BFLogFile=SetWifiMacAddress
	set LogFile=SetWifiMacAddress.txt
	set MacType=WLAN
	goto Set_MacAddress

:Set_BT_MacAddress
	set TestItem=%TestItems_Count%_Set_Bt_MacAddress
	set TechnologyType=BLUETOOTH
	set BFLogFile=SetBtMacAddress
	set LogFile=SetBtMacAddress.txt
	set MacType=BT
	goto Set_MacAddress
	
:Set_MacAddress
	if exist %LogFile% del /q %LogFile%
	if "%2"=="" (
		echo No Mac address defined in parameter. > %LogFile%
		goto fail
	)
	
	if exist %MacType%.provision del /q %MacType%.provision
	powershell -ex bypass .\UEFIProvisionFileGen.ps1 -mac "%2" -mode "%MacType%"
	if %errorlevel% neq 0 goto fail
	
	powershell -NoProfile -ExecutionPolicy Bypass .\ConvertToBase64.ps1 -filePathAndName "%MacType%.provision"
	set /p Base64Data=< ConvertToBase64.txt
	ECHO Base64Data=%Base64Data%
	ECHO grpcurl.exe -insecure -d "{ \"targetPath\": \"c:\\tools\\RF\\QC_WiFiBT\\" , \"fileBytes\": \"!Base64Data!\" }" %DUT_IP%:16137 FileSystemService/CreateFile > %LogFile%
	ECHO grpcurl.exe -insecure -d "{ \"executablePath\": \"c:\\tools\\RF\\QC_WiFiBT\\UEFIProvsionWifiBT.cmd\", \"arguments\": \"/W %MacType%.provision %MacType%.provision" }" %DUT_IP%:16137 ExecutableService/RunExecutable >> %LogFile%
	REM PAUSE
	rem %3 need to use \\ instead of \ (ex: C:\\Tools\\Audio\\File.txt)
	grpcurl.exe -insecure -d "{ \"targetPath\": \"c:\\tools\\RF\\QC_WiFiBT\\" , \"fileBytes\": \"!Base64Data!\" }" %DUT_IP%:16137 FileSystemService/CreateFile > %LogFile%
	rem if %errorlevel% neq 0 goto fail

	grpcurl.exe -insecure -d "{ \"executablePath\": \"c:\\tools\\RF\\QC_WiFiBT\\UEFIProvsionWifiBT.cmd\", \"arguments\": \"/W %MacType%.provision %MacType%.provision" }" %DUT_IP%:16137 ExecutableService/RunExecutable >> %LogFile%
	rem echo grpcurl.exe -emit-defaults -insecure -d "{\"technologyType\": \"%TechnologyType%\" , \"macAddress\": \"%2\"}" %DUT_IP%:%ServicePorts% RadioMacAddressService/SetMacAddress > %LogFile%	
	rem grpcurl.exe -emit-defaults -insecure -d "{\"technologyType\": \"%TechnologyType%\" , \"macAddress\": \"%2\"}" %DUT_IP%:%ServicePorts% RadioMacAddressService/SetMacAddress >> !LogFile! 2>&1 
	rem Check if Bifrost Log Error
	REM echo %errorlevel%
	REM pause
	if %errorlevel% neq 0 goto fail
	goto pass

:Flash_Modem_FW
	echo %time%
	set TestItem=%TestItems_Count%_Flash_Modem_FW
	set BFLogFile=FlashModemFW
	set LogFile=FlashModemFW.txt

	if exist %LogFile% del /q %LogFile%
	echo grpcurl.exe -emit-defaults -insecure -d "{\"modemFlashingInterface\": \"PCIE\" , \"modemEnumeratingInterface\": \"PCIE\", \"clearNand\": true, \"version\": \"LATEST\"}" %DUT_IP%:%ServicePorts% CellularFirmwareService/FlashModemFirmware > %LogFile%	
	grpcurl.exe -emit-defaults -insecure -d "{\"modemFlashingInterface\": \"PCIE\" , \"modemEnumeratingInterface\": \"PCIE\", \"clearNand\": true, \"version\": \"LATEST\"}" %DUT_IP%:%ServicePorts% CellularFirmwareService/FlashModemFirmware >> !LogFile! 2>&1 
	rem Check if Bifrost Log Error
	echo %time%
	REM findstr /c:"\"version\": \"Modem\"" !LogFile! 
	REM if !errorlevel! equ 0 (
		REM goto pass
	REM ) else (
		REM goto fail
	REM )
	findstr /c:"\"version\": \"250613-DE-d12a900-00197\"" !LogFile! 
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)
:Get_EID
	set TestItem=%TestItems_Count%_Get_EID
	set BFLogFile=GetEID
	set LogFile=GetEID.txt

	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -emit-defaults -insecure -d "{}" %DUT_IP%:%ServicePorts% ESimService/GetEid > !LogFile! 2>&1 
	rem Check if Bifrost Log Error
	findstr /c:"eid" !LogFile!  > tmp.log
	if !errorlevel! neq 0 goto fail
	rem No %2 input then skip compare 
	if "%2"=="" (
		goto upload_EID
		REM goto pass
	) else (		
		findstr /c:"%2" !LogFile! 
		if !errorlevel! equ 0 (
			rem upload EID to SFIS
			goto upload_EID
			
			REM goto pass
		) else (
			REM set rtn=255
			goto fail
		)
	)
	:upload_EID
	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (tmp.log) do (
		echo %%l >EID.txt
	)
	copy EID.txt ..\
	set /p EID=<EID.txt

	echo .\Data_Upload\upload.exe EID %EID% %sn% >uploadEID.log
	call .\Data_Upload\SFISupload-diag.exe EID %EID% %sn% >>uploadEID.log
	findstr /c:"DATA SAVE" uploadEID.log
		if !errorlevel! equ 0 (
			goto pass
		) else (
			set rtn=254
			goto fail
		)


:Get_IMEI
	set TestItem=%TestItems_Count%_Get_IMEI
	set BFLogFile=GetIMEI
	set LogFile=GetIMEI.txt

	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -emit-defaults -insecure -d "{\"technologyType\": \"CELLULAR\"}" %DUT_IP%:%ServicePorts% RadioConnectionService/ConnectRadio > !LogFile! 2>&1 
	grpcurl.exe -emit-defaults -insecure -d "{}" %DUT_IP%:%ServicePorts% ImeiService/GetImei >> !LogFile! 2>&1 
	grpcurl.exe -emit-defaults -insecure -d "{\"technologyType\": \"CELLULAR\"}" %DUT_IP%:%ServicePorts% RadioConnectionService/DisconnectRadio >> !LogFile! 2>&1 
	rem Check if Bifrost Log Error
	findstr /c:"imei" !LogFile! 
	if !errorlevel! neq 0 goto fail
	rem No %2 input then skip compare 
	if "%2"=="" (
		goto pass
	) else (		
		findstr /c:"%2" !LogFile! 
		if !errorlevel! equ 0 (
			goto pass
		) else (
			goto fail
		)
	)

:Set_IMEI
	set TestItem=%TestItems_Count%_Set_IMEI
	set BFLogFile=SetIMEI
	set LogFile=SetIMEI.txt

	if exist %LogFile% del /q %LogFile%
	if "%2"=="" (
		echo No IMEI defined in parameter. > %LogFile%
		goto fail
	)
	set "length=0"
	set "str=%2"
	@echo off
	:S_IMEI_Loop
	if not "%str%"=="" (
		set "str=%str:~1%"
		set /a length+=1
		goto S_IMEI_Loop
	)
	if !length! neq 15 goto fail
	@echo on
	echo grpcurl.exe -emit-defaults -insecure -d "{\"technologyType\": \"CELLULAR\"}" %DUT_IP%:%ServicePorts% RadioConnectionService/ConnectRadio > !LogFile! 2>&1 
	echo grpcurl.exe -emit-defaults -insecure -d "{\"imei\": \"%2\"}" %DUT_IP%:%ServicePorts% ImeiService/SetImei >> !LogFile! 2>&1 	
	grpcurl.exe -emit-defaults -insecure -d "{\"technologyType\": \"CELLULAR\"}" %DUT_IP%:%ServicePorts% RadioConnectionService/ConnectRadio > !LogFile! 2>&1 
	grpcurl.exe -emit-defaults -insecure -d "{\"imei\": \"%2\"}" %DUT_IP%:%ServicePorts% ImeiService/SetImei >> !LogFile! 2>&1 
	
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto DisconnectFail
	goto DisconnectPass
	
:DisconnectFail
	grpcurl.exe -emit-defaults -insecure -d "{\"technologyType\": \"CELLULAR\"}" %DUT_IP%:%ServicePorts% RadioConnectionService/DisconnectRadio
	goto fail
	
:DisconnectPass
	grpcurl.exe -emit-defaults -insecure -d "{\"technologyType\": \"CELLULAR\"}" %DUT_IP%:%ServicePorts% RadioConnectionService/DisconnectRadio
	goto pass

	
:NoParameter
echo no Parameter enter.
goto End


:fail
echo fail
cd %~dp0
if not exist ..\Tools\Temp\MISClog\%TestItem% MKDIR ..\Tools\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Tools\Temp\MISClog\%TestItem%\
if defined LogFile copy /y %LogFile% ..\Temp\
..\Tools\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleRadio" -to "..\Temp" -w -e 0 -timeout 10
REM for %%D in (!BFLogFile!) do move /y C:\DeviceBridgeLogs\%SN%_%TSRID_DB%\*%%D*.* ..\Tools\Temp\MISClog\%TestItem%\
echo rtn="%rtn%"
if defined rtn (
	exit /b %rtn% 
) else (
	exit /b 255
)

:pass
echo pass
cd %~dp0
if not exist ..\Tools\Temp\MISClog\%TestItem% MKDIR ..\Tools\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Tools\Temp\MISClog\%TestItem%\
if defined LogFile copy /y %LogFile% ..\Temp\
if defined TechnologyType copy /y Mac_%TechnologyType%.txt ..\Temp\
if defined TechnologyType copy /y Mac_%TechnologyType%.txt ..\Tools\Temp\MISClog\%TestItem%\
..\Tools\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleRadio" -to "..\Temp" -w -e 0 -timeout 10
REM for %%D in (!BFLogFile!) do move /y C:\DeviceBridgeLogs\%SN%_%TSRID_DB%\*%%D*.* ..\Tools\Temp\MISClog\%TestItem%\
exit /b 0

:not_backup
if defined rtn (
	echo %rtn%
	exit /b %rtn%
) else ( 
	exit /b 255
)

:End