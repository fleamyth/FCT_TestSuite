@ECHO ON
cd %~dp0
setlocal EnableDelayedExpansion
rem grpcui.exe -insecure 192.168.1.51:16137

:Start
SET DUT_IP=192.168.1.51
SET ServicePorts=16137
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
if /I "%1"=="HealthCheck" goto BiFrost_Health_Check
if /I "%1"=="MODE" goto UEFI_Mode_Check
if /I "%1"=="MODEAFT" goto UEFI_Mode_Check_Aft
if /I "%1"=="Unlock" goto UEFI_Unlock
if /I "%1"=="MTEOS" goto MTEOS
if /I "%1"=="UEFI" goto UEFI_Ver
if /I "%1"=="SAM" goto SAM_Ver
if /I "%1"=="PD" goto PD_Ver
if /I "%1"=="PD_SDF" goto PD_Ver_FromSDF
if /I "%1"=="PD_SDF_BYPASS" goto PD_Ver_FromSDF_BYPASS
if /I "%1"=="ME" goto ME_Ver
if /I "%1"=="PCBA" goto PCBA_SN
if /I "%1"=="SSD" goto SSD
if /I "%1"=="DUT" goto DUT_SN
if /I "%1"=="SetTime" goto SetSystemTimeUTC
if /I "%1"=="YB" goto Yellow_bang
if /I "%1"=="Driver" goto Driver_Enumeration
if /I "%1"=="CPU" goto CPU
if /I "%1"=="CPUSN" goto CPU_SN
if /I "%1"=="MEM" goto Memory
if /I "%1"=="MEMFREQ" goto Memoryfreq
if /I "%1"=="PCIE" goto PCIE
if /I "%1"=="TPM" goto TPM
if /I "%1"=="SetPCBASN" goto Set_PCBA_SN
if /I "%1"=="GetFuseStatus" goto UEFI_GetEoFStatus
if /I "%1"=="GetUnlockBlob" goto UEFI_GetUnlockBlob
if /I "%1"=="Blob2Bin" goto UEFI_Covert2Bin
if /I "%1"=="Bin2P7b" goto UEFI_Bin2P7b
if /I "%1"=="P7b2Bin" goto UEFI_P7b2Bin
if /I "%1"=="SetBin" goto UEFI_set_bin
if /I "%1"=="SetUEFIMode" goto UEFI_TriggerUefiUnlock
if /I "%1"=="IPC2Dut" goto IPC2DUT
if /I "%1"=="GetPTMac" goto Get_PT_MacAddress
if /I "%1"=="SetPTMac" goto Set_PT_MacAddress
if /I "%1"=="GetPostTime" goto Get_POST_Time
if /I "%1"=="GetSLInfo" goto SurfLink_GetID
if /I "%1"=="PowerControl" goto SystemPowerControl
if /I "%1"=="BTPID" goto BT_PID_CHECK
if /I "%1"=="TPMSwitch" goto TPM_Switch
if /I "%1"=="TPMSwitchCheck" goto TPM_Switch_Check
if /I "%1"=="" goto NoParameter
goto NoParameter

:BiFrost_Health_Check
	set TestItem=%TestItems_Count%_System_BF_Health_Check
	set BFLogFile=System_BF_Health_Check
	set LogFile=System_BF_Health_Check.txt 
	set BF_Health_Check=0
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{}" %DUT_IP%:%ServicePorts% grpc.health.v1.Health/Check > %LogFile%
	if %errorlevel% equ 0 (
		REM grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\Windows\\System32\\cmd.exe\", \"arguments\": \"E:\\LanRS.bat\" }" 192.168.1.51:16137 ExecutableService/RunExecutable >> %LogFile%
		REM exit /b 0
		REM set BF_Health_Check=0
	) else (
		REM exit /b 255
		set BF_Health_Check=1
	)
	rem power
	grpcurl.exe -insecure -d "{}" %DUT_IP%:16138 grpc.health.v1.Health/Check >> %LogFile%
	if %errorlevel% equ 0 (
		REM exit /b 0
		REM set BF_Health_Check=0
	) else (
		REM exit /b 255
		set BF_Health_Check=1
	)
	if %BF_Health_Check% equ 0 (
		REM .\LANRS-diags.exe /e -ip 192.168.1.51 -w -ex -f "cmd.exe /c E:\GET_DK.bat >E:\dk_check.txt" -timeout 60
		REM grpcurl.exe -insecure -d "{ \"executablePath\": \"E:\\LanRS.bat\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable >> %LogFile%
		grpcurl.exe -insecure -d "{ \"executablePath\": \"E:\\LanRS.bat\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable >> %LogFile%
		goto pass
	) else (
		echo BF_Health_Check radio,system fail  >> %LogFile%
		goto fail
	)
	
:UEFI_Mode_Check
	del ..\Tools\UnlockUEFI.fpc
	set TestItem=%TestItems_Count%_UEFI_Mode_Check
	set BFLogFile=GetUefiMode
	set LogFile=GetUefiMode.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{}" %DUT_IP%:%ServicePorts% UefiService/GetUefiMode > %LogFile%
	findstr /c:"UEFI_MODE_MANUFACTURING" %LogFile% 
	if %errorlevel% equ 0 goto pass
	findstr /c:"UEFI_MODE_CUSTOMER" %LogFile% 
	if %errorlevel% equ 0 echo customer mode>..\Tools\UnlockUEFI.fpc & goto pass	
	SET RTN=1
	goto fail
	REM if %errorlevel% equ 0 (
		REM goto pass
	REM ) else (
	
		REM echo customer mode>..\Tools\UnlockUEFI.fpc
		REM goto fail
	REM )

	:showUEFI_Mode_Fail
	..\Tools\Screen-diag.exe -nl -enter /SS 55 "Check UEFI as manufacturing mode failed.<br> гq  FA  SSD   Revent log   `!!" 0xFFFFFF -bg 0x882222
	taskkill /IM Screen-diag.exe
	goto fail	
	
:UEFI_Mode_Check_Aft
	REM del ..\Tools\UnlockUEFI.fpc
	set TestItem=%TestItems_Count%_UEFI_Mode_Check_Aft
	set BFLogFile=GetUefiModeAft
	set LogFile=GetUefiModeAft.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{}" %DUT_IP%:%ServicePorts% UefiService/GetUefiMode > %LogFile%
	findstr /c:"UEFI_MODE_MANUFACTURING" %LogFile% 
	if %errorlevel% equ 0 goto pass
	
	findstr /c:"UEFI_MODE_CUSTOMER" %LogFile% 
	if %errorlevel% equ 0 goto fail	
	
	SET RTN=1
	goto fail
:UEFI_GetEoFStatus
	set TestItem=%TestItems_Count%_UEFI_UEFI_GetEoFStatus
	set BFLogFile=UEFI_GetEoFStatus
	set LogFile=UEFI_GetEoFStatus.txt 
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{}" %DUT_IP%:%ServicePorts% UefiService/GetEndOfManufacturingFuseStatus > %LogFile%
	if %errorlevel% equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:UEFI_GetUnlockBlob
	set TestItem=%TestItems_Count%_UEFI_GetUnlockBlob
	set BFLogFile=GetUnlockBlob
	set LogFile=GetUnlockBlob.txt 
	
	if exist %LogFile% del /q %LogFile%
	if exist FirmwarePolicy.bin del /q FirmwarePolicy.bin
	if "%2"=="" (
		grpcurl.exe -insecure -d "{}" %DUT_IP%:%ServicePorts% UefiService/GetUefiMfgUnlockBlob > %LogFile%
	) else (
		grpcurl.exe -insecure -d "{\"unlockSoc\": \"true\"}" %DUT_IP%:%ServicePorts% UefiService/GetUefiMfgUnlockBlob > %LogFile%
	)
	if !errorlevel! equ 0 (
		TIMEOUT 10
		echo ..\Tools\LANRS-diags.exe /q -ip %DUT_IP% -w -rf "C:\tools\MfgUnlock\FirmwarePolicy.bin" -to "%~dp0..\BiFrostTools"
		..\Tools\LANRS-diags.exe /q -ip %DUT_IP% -w -rf "C:\tools\MfgUnlock\FirmwarePolicy.bin" -to "%~dp0..\BiFrostTools"
		if not exist FirmwarePolicy.bin goto fail
		goto pass
	) else (
		goto fail
	)
	
:UEFI_Covert2Bin
	set TestItem=%TestItems_Count%_UEFI_Covert2Bin
	set BFLogFile=UEFI_Covert2Bin
	set LogFile=output.bin
	
	if exist %LogFile% del /q %LogFile%
	
	powershell -ex bypass .\Unlock\Convert.ps1
	
	if NOT exist %LogFile% goto fail
	copy %LogFile% ..\Tools\SRQClientwork\unlock.bin
	goto pass
	
:UEFI_Bin2P7b
	REM convert thru SRQ server
	
:UEFI_P7b2Bin
	set TestItem=%TestItems_Count%_UEFI_P7b2Bin
	set BFLogFile=UEFI_Covert2Bin
	set LogFile=binary.txt
	
	if exist %LogFile% del /q %LogFile%
	if NOT exist output.p7b goto fail
	powershell -ex bypass .\Unlock\P7b_to_bytes.ps1
	if NOT exist %LogFile% goto fail	
	goto pass
	
:UEFI_set_bin
	set TestItem=%TestItems_Count%_set_bin
	set BFLogFile=UEFI_set_bin
	set LogFile=unlock_IPC_para.bat
	
	if exist %LogFile% del /q %LogFile%
	powershell -ex bypass .\Unlock\set_bin.ps1
	if NOT exist %LogFile% goto fail
	goto pass
	
:UEFI_TriggerUefiUnlock
	set TestItem=%TestItems_Count%_UEFI_TriggerUefiUnlock
	set BFLogFile=TriggerUefiUnlock
	set LogFile=TriggerUefiUnlock.txt 
	
	if exist %LogFile% del /q %LogFile%
	
	REM call unlock_IPC_para.bat
	
	set /p bin=<binary.txt
	if "%2"=="" (
		grpcurl.exe -insecure -d "{\"useUnlockSignature\": \"true\", \"unlockSignature\": \"%bin%\"}" %DUT_IP%:%ServicePorts% UefiService/TriggerUefiMfgUnlock > %LogFile%
	) else (
		grpcurl.exe -insecure -d "{ \"unlockSoc\": \"true\",\"useUnlockSignature\": \"true\", \"unlockSignature\": \"%bin%\" }" %DUT_IP%:%ServicePorts% UefiService/TriggerUefiMfgUnlock > %LogFile%
	)
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:UEFI_TriggerQCUnlock
	set TestItem=%TestItems_Count%_UEFI_TriggerQCUnlock
	set BFLogFile=TriggerQCUnlock
	set LogFile=TriggerQCUnlock.txt 
	
	if exist %LogFile% del /q %LogFile%
	set /p bin=<binary.txt
	grpcurl.exe -insecure -d "{ \"setQcCustomerMode\": \"true\",\"useUnlockSignature\": \"true\", \"unlockSignature\": \"%bin%\" }" %DUT_IP%:%ServicePorts% UefiService/TriggerQCMfgExit  > %LogFile%
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:UEFI_GetQCMfgMode
	set TestItem=%TestItems_Count%_UEFI_GetQCMfgMode
	set BFLogFile=GetQCMfgMode
	set LogFile=GetQCMfgMode.txt 
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% UefiService/GetQCMfgMode  > %LogFile%
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:UEFI_Unlock
	if "%2"=="UefiUnlockProxyService" goto UEFI_Unlock2
	set TestItem=%TestItems_Count%_UEFI_Unlock
	set BFLogFile=GetUefiMode GetUefiMfgUnlockBlob TriggerUefiMfgUnlock
	set LogFile=GetUefiUnlockSalt.txt 
	set dd=%~dp0
	rem for /f "tokens=1,2,3,4 tokens=\" %%i in ('%dd%') do 
	rem (
	rem 	set aa=%%i
	rem 	set bb=%%j
	rem 	set cc=%%k	
	rem )
	DevInfo-diag.exe /cmd "TriggerUefiMfgUnlock %dd%SRQClientwork" > %LogFile%
	findstr /c:"Unlock UEFI Done" %LogFile% > GetUefiUnlockSalt_check.txt 2>&1
	set returnc=%errorlevel% 
	echo returnc=%returnc% >> GetUefiUnlockSalt_check.txt
	if not exist ..\Tools\Temp\MISClog\%TestItem% MKDIR ..\Tools\Temp\MISClog\%TestItem%
	copy /y GetUefiUnlockSalt_check.txt ..\Tools\Temp\MISClog\%TestItem%\
	if %returnc% equ 0 goto pass
	..\Tools\Screen-diag.exe -nl -enter /SS 55 " O d   O MSSD Ű !!<br> óq  FA T {    Event log" 0xFFFFFF -bg 0x882222
    taskkill /IM Screen-diag.exe
	goto fail

:UEFI_Unlock2
	set TestItem=%TestItems_Count%_UEFI_Unlock
	set BFLogFile=RunExecutable
	set LogFile=DevMfgUnlock_trace.txt 
	DevInfo-diag.exe /cmd "RunExecutable C:\Tools\MfgUnlock\Gaviota\DevMfgUnlock.cmd" -para " " > %LogFile%
	find "Successfully unlocked TestSigned Gaviota Manufacturing Mode" %LogFile%
	if %errorlevel% equ 0 goto pass
	..\Tools\Screen-diag.exe -nl -enter /SS 55 " O d   O MSSD Ű !!<br> óq  FA T {    Event log" 0xFFFFFF -bg 0x882222
    taskkill /IM Screen-diag.exe
	goto fail
	
:MTEOS
	set TestItem=%TestItems_Count%_MTEOS_Version_Check
	set BFLogFile=GetOsVersion
	set LogFile=GetOsVersion.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ \"componentId\": \"COMPONENT_ID_OS\" }" %DUT_IP%:%ServicePorts% DeviceInfoService/GetFirmwareVersion > %LogFile%
	findstr /c:"%2" %LogFile% 
	if %errorlevel% equ 0 (
		goto pass
	) else (
		goto fail
	)

:BF_Ver
	set TestItem=%TestItems_Count%_DBRuntime_Version
	set BFLogFile=GetRuntimeVersion
	set LogFile=GetRuntimeVersion.txt
	DevInfo-diag.exe -sn %SN% /cmd GetRuntimeVersion -cmp %2 %2 > %LogFile%
	if %errorlevel% equ 0 (
		goto pass
	) else (
		goto fail
	)

:UEFI_Ver
	set TestItem=%TestItems_Count%_UEFI_Version_Check
	set BFLogFile=GetUefiVersion
	set LogFile=GetUefiVersion.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ \"componentId\": \"COMPONENT_ID_UEFI\" }" %DUT_IP%:%ServicePorts% DeviceInfoService/GetFirmwareVersion > %LogFile%
	findstr /c:"version" %LogFile% > tmp.log
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto fail
	rem for /F "tokens=1,2* delims=\" " %%i in (tmp.log) do (
	
	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (tmp.log) do (
		set Reading=%%l
	)
	rem if defined Reading set Reading=%Reading: =%
	rem echo %Reading%
	set argCount=0
	for %%x in (%*) do (
		set /a argCount+=1
		set "argVec[!argCount!]=%%~x"
	)
	echo Number of processed arguments: %argCount%
	
	for /l %%i in (2,1,%argCount%) do (
		find /i "!argVec[%%i]!" tmp.log
		REM if !errorlevel!==0 goto QS_ES_VERCHECK
		if !errorlevel!==0 goto pass
	)
	goto fail
	REM :QS_ES_VERCHECK
	REM if exist ..\LCD.fpc (
		REM find /i "3.2135.143" tmp.log
		REM if %errorlevel%==0 goto pass
	REM ) else (
		REM find /i "3.135.143" tmp.log
		REM if %errorlevel%==0 goto pass
	REM )
	REM goto fail
:SAM_Ver
	set TestItem=%TestItems_Count%_SAM_Version_Check
	set BFLogFile=GetSamFwVersion
	set LogFile=GetSamFwVersion.txt

	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ \"componentId\": \"COMPONENT_ID_SAM\" }" %DUT_IP%:%ServicePorts% DeviceInfoService/GetFirmwareVersion > %LogFile%
	findstr /c:"version" %LogFile% > tmp.log
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto fail
	rem for /F "tokens=1,2* delims=\" " %%i in (tmp.log) do (
	
	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (tmp.log) do (
		set Reading=%%l
	)
	rem if defined Reading set Reading=%Reading: =%
	rem echo %Reading%
	set argCount=0
	for %%x in (%*) do (
		set /a argCount+=1
		set "argVec[!argCount!]=%%~x"
	)
	echo Number of processed arguments: %argCount%
	
	for /l %%i in (2,1,%argCount%) do (
		find /i "!argVec[%%i]!" tmp.log
		if !errorlevel!==0 goto pass
	)
	goto fail

:PD_Ver
	set TestItem=%TestItems_Count%_PD_Version_Check
	set BFLogFile=GetPdFwVersion
	set LogFile=GetPdFwVersion.txt

	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ \"componentId\": \"COMPONENT_ID_PD_CONTROLLER\" }" %DUT_IP%:%ServicePorts% DeviceInfoService/GetFirmwareVersion > %LogFile%
	findstr /c:"version" %LogFile% > tmp.log
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto fail
	rem for /F "tokens=1,2* delims=\" " %%i in (tmp.log) do (
	
	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (tmp.log) do (
		set Reading=%%l
	)
	rem if defined Reading set Reading=%Reading: =%
	rem echo %Reading%
	set argCount=0
	for %%x in (%*) do (
		set /a argCount+=1
		set "argVec[!argCount!]=%%~x"
	)
	echo Number of processed arguments: %argCount%
	
	for /l %%i in (2,1,%argCount%) do (
		find /i "!argVec[%%i]!" tmp.log
		if !errorlevel!==0 goto pass
	)
	goto fail
	
:PD_Ver_FromSDF
	set TestItem=%TestItems_Count%_PD_Version_Check
	set BFLogFile=GetPdFwVersion
	set LogFile=GetPdFwVersionSDF.txt

	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\tools\\Sdf\\Console\\net8.0\\x64\\SdfConsole.exe\", \"arguments\": \" -c pdgetversion -TC 27\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable > %LogFile%
	findstr /c:"pdGetVersion" %LogFile% > tmp1.log
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto fail
	rem for /F "tokens=1,2* delims=\" " %%i in (tmp.log) do (
	
	for /f "tokens=1,2* delims==" %%i in (tmp1.log) do (
		set Reading=%%j
	)
	if defined Reading set Reading=%Reading: =%
	if defined Reading set Reading=%Reading:\r=%
	if defined Reading set Reading=%Reading:\n=%
	if defined Reading set Reading=%Reading:"=%

	for /f %%i in ('powershell -command "(!Reading! -shr 24) -band 0xFF"') do set major=%%i
	for /f %%i in ('powershell -command "(!Reading! -shr 8) -band 0xFFFF"') do set minor=%%i
	for /f %%i in ('powershell -command "!Reading! -band 0xFF"') do set patch=%%i
	
	echo %major%.%minor%.%patch%>tmp.log
	copy /y tmp.log ..\Temp\PDver.log
	set argCount=0
	for %%x in (%*) do (
		set /a argCount+=1
		set "argVec[!argCount!]=%%~x"
	)
	echo Number of processed arguments: %argCount%
	rem data collection if need
	REM if /I "%2"=="pass" goto pass
	
	for /l %%i in (2,1,%argCount%) do (
		find /i "!argVec[%%i]!" tmp.log
		if !errorlevel!==0 goto pass
	)
	goto fail
:PD_Ver_FromSDF_BYPASS
	set TestItem=%TestItems_Count%_PD_Version_Check
	set BFLogFile=GetPdFwVersion
	set LogFile=GetPdFwVersionSDF.txt

	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\tools\\Sdf\\Console\\net8.0\\x64\\SdfConsole.exe\", \"arguments\": \" -c pdgetversion -TC 27\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable > %LogFile%
	findstr /c:"pdGetVersion" %LogFile% > tmp1.log
	rem Check if Bifrost Log Error
	REM if %errorlevel% neq 0 goto fail
	rem for /F "tokens=1,2* delims=\" " %%i in (tmp.log) do (
	
	for /f "tokens=1,2* delims==" %%i in (tmp1.log) do (
		set Reading=%%j
	)
	if defined Reading set Reading=%Reading: =%
	if defined Reading set Reading=%Reading:\r=%
	if defined Reading set Reading=%Reading:\n=%
	if defined Reading set Reading=%Reading:"=%

	for /f %%i in ('powershell -command "(!Reading! -shr 24) -band 0xFF"') do set major=%%i
	for /f %%i in ('powershell -command "(!Reading! -shr 8) -band 0xFFFF"') do set minor=%%i
	for /f %%i in ('powershell -command "!Reading! -band 0xFF"') do set patch=%%i
	
	echo %major%.%minor%.%patch%>tmp.log
	copy /y tmp.log ..\Temp\PDver.log
	goto pass
	REM set argCount=0
	REM for %%x in (%*) do (
		REM set /a argCount+=1
		REM set "argVec[!argCount!]=%%~x"
	REM )
	REM echo Number of processed arguments: %argCount%
	
	REM for /l %%i in (2,1,%argCount%) do (
		REM find /i "!argVec[%%i]!" tmp.log
		REM if !errorlevel!==0 goto pass
	REM )
	REM goto fail
:ME_Ver
	set TestItem=%TestItems_Count%_ME_Version
	set BFLogFile=RunExecutable
	set LogFile=MEInfo.txt

	if exist %LogFile% del /q %LogFile%
	del /q ME_Version.txt
	grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\Tools\\Intel\\MEInfo\\Windows64\\MEInfoWin64.exe\", \"arguments\": \"-verbose\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable > %LogFile%
	powershell -ex bypass .\ReplaceLineBreaks.ps1 -InputFile "MEInfo.txt" -OutputFile "MEInfo_Modified.txt"
	findstr /C:"    FW Version" MEInfo_Modified.txt > tmp.txt
	set /p ver=<tmp.txt
	set ver=%ver:    FW Version                                   =%
	echo %ver%>tmp.txt
	FOR /F "tokens=1* delims= " %%i in (tmp.txt) do (
		set Reading=%%i
	)

	echo %Reading%>ME_Version.txt
	set argCount=0
	for %%x in (%*) do (
		set /a argCount+=1
		set "argVec[!argCount!]=%%~x"
	)
	echo Number of processed arguments: %argCount%
	
	for /l %%i in (2,1,%argCount%) do (
		find /i "!argVec[%%i]!" ME_Version.txt
		if !errorlevel!==0 goto pass
	)
	goto fail
	
:ME_RPMC_Check
	set LogFile=MEInfo.txt
	
	if not exist %LogFile% (
		set TestItem=%TestItems_Count%_ME_RPMC_Status
		set BFLogFile=RunExecutable
		DevInfo-diag.exe -sn %SN% /cmd "RunExecutable C:\Tools\Intel\MEInfo\MEInfoWin64.exe" -para "-verbose" > %LogFile%
		PT-diags.exe -nc -nl /find %LogFile% "BIOS RPMC Status                         OK"
		if !errorlevel! neq 0 goto fail
		goto pass
	) else (
		PT-diags.exe -nc -nl /find %LogFile% "BIOS RPMC Status                         OK"
		if !errorlevel! neq 0 set rtn=255 & goto not_backup
		set rtn=0 & goto not_backup
	)

:Get_BoardID
	set TestItem=%TestItems_Count%_BoardId
	set DBLogFile=GetBoardId
	set LogFile=GetBoardId.txt
	DevInfo-diag.exe -sn %SN% /cmd getboardid -cmp %2 > %LogFile%
	if %errorlevel% equ 0 goto pass	
	DevInfo-diag.exe -sn %SN% /cmd getboardid -cmp %3 > %LogFile%	
	if %errorlevel% equ 0 goto pass
	goto fail

:PCBA_SN
	set TestItem=%TestItems_Count%_Get_PCBA_SerialNumber
	set BFLogFile=GetPcbaSerialNumber
	set LogFile=GetPcbaSerialNumber.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ \"snType\": \"SERIAL_NUMBER_TYPE_MOTHER_BOARD\" }" %DUT_IP%:%ServicePorts% DeviceInfoService/GetSerialNumber > %LogFile%
	findstr /c:"serial_number" %LogFile% > tmp.log
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto fail
	rem for /F "tokens=1,2* delims=\" " %%i in (tmp.log) do (
	
	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (tmp.log) do (
		set Reading=%%l
	)
	rem if defined Reading set Reading=%Reading: =%
	rem echo %Reading%
	set argCount=0
	for %%x in (%*) do (
		set /a argCount+=1
		set "argVec[!argCount!]=%%~x"
	)
	echo Number of processed arguments: %argCount%
	
	for /l %%i in (2,1,%argCount%) do (
		find /i "!argVec[%%i]!" tmp.log
		if !errorlevel!==0 goto pass
	)
	
	goto fail	

:DUT_SN
	set TestItem=%TestItems_Count%_Get_DUT_SerialNumber
	set BFLogFile=GetDutSerialNumber
	set LogFile=GetDutSerialNumber.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ \"snType\": \"SERIAL_NUMBER_TYPE_DUT\" }" %DUT_IP%:%ServicePorts% DeviceInfoService/GetSerialNumber > %LogFile%
	findstr /c:"serial_number" %LogFile% > tmp.log
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto fail
	rem for /F "tokens=1,2* delims=\" " %%i in (tmp.log) do (
	
	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (tmp.log) do (
		set Reading=%%l
	)
	rem if defined Reading set Reading=%Reading: =%
	rem echo %Reading%
	set argCount=0
	for %%x in (%*) do (
		set /a argCount+=1
		set "argVec[!argCount!]=%%~x"
	)
	echo Number of processed arguments: %argCount%
	
	for /l %%i in (2,1,%argCount%) do (
		find /i "!argVec[%%i]!" tmp.log
		if !errorlevel!==0 goto pass
	)
	goto fail	
	
:Set_PCBA_SN
	set TestItem=%TestItems_Count%_Set_PCBA_SerialNumber
	set BFLogFile=SetPcbaSerialNumber
	set LogFile=SetPcbaSerialNumber.txt

	if exist %LogFile% del /q %LogFile%
	if exist SN_ASCII.txt del /q SN_ASCII.txt
	if not exist ..\SN.dat goto fail

	rem powershell -ex bypass .\ConvertSN2ASCII.ps1 ..\SN.dat
	rem if not exist SN_ASCII.txt goto fail
	rem set /p SN_ASCII=< SN_ASCII.txt
	set /p SN=< ..\SN.dat
	rem echo SN=%SN_ASCII%
	echo grpcurl.exe -insecure -d "{  \"snType\": \"SERIAL_NUMBER_TYPE_MOTHER_BOARD\",\"serialNumber\": \"%SN%\" }" %DUT_IP%:%ServicePorts% DeviceInfoService/SetSerialNumber > %LogFile%
	grpcurl.exe -insecure -d "{  \"snType\": \"SERIAL_NUMBER_TYPE_MOTHER_BOARD\",\"serialNumber\": \"%SN%\" }" %DUT_IP%:%ServicePorts% DeviceInfoService/SetSerialNumber >> %LogFile%
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto fail
	goto pass

:Yellow_bang
	set TestItem=%TestItems_Count%_Device_Yellow_Bang_Check
	set BFLogFile=DevNodeInfo
	set LogFile=GetHardwareComponents.txt 
	
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% HardwareInfoService/GetDriverStatus > %LogFile%
	findstr /c:"driver_status" %LogFile% 
	
	
	rem Check if Bifrost Log Error
	if !errorlevel! neq 0 goto fail

	powershell -ex bypass .\YB_Analysis.ps1
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:PCIE
	set TestItem=%TestItems_Count%_PCIE_CurrentLinkWidth_Check
	set BFLogFile=DevNodeInfo
	set LogFile=GetPCIECurrentLinkWidth.txt 
	
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% HardwareInfoService/GetHardwareComponents > %LogFile%
	findstr /c:"\"current_link_speed\": 3" %LogFile% 
	if !errorlevel! neq 0 goto fail
	findstr /c:"\"current_link_width\": 1" %LogFile% 
	if !errorlevel! neq 0 goto fail	
	findstr /c:"\"max_link_speed\": 4" %LogFile% 
	if !errorlevel! neq 0 goto fail		
	findstr /c:"\"max_link_width\": 4" %LogFile% 
	if !errorlevel! neq 0 goto fail
	goto pass


	
:SetSystemTimeUTC
	set TestItem=%TestItems_Count%_SetSystemTimeUTC
	set LogFile=SetSystemTimeUTC.txt

	if exist %LogFile% del /q %LogFile%
	powershell -ex bypass .\DateTime.ps1
	set /p DateTime=<IPC_DateTime.txt
	
	grpcurl.exe -insecure -d "{ \"systemTime\": \"%DateTime%\" }" %DUT_IP%:%ServicePorts% DeviceInfoService/SetSystemTime > %LogFile%
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)

:IPC2DUT
	set TestItem=%TestItems_Count%_IPC2DUT
	set LogFile=CopyFileToDut.txt

	if exist %LogFile% del /q %LogFile%
	if exist ConvertToBase64.txt del /q ConvertToBase64.txt
	if "%2"=="" (
		echo No file defined in parameter. > %LogFile%
		goto fail
	) else (
		IF not exist %2 (
			echo File "%2" not exist > %LogFile%
			goto fail
		)
	)
	if "%3"=="" (
		echo No destination file defined in parameter. > %LogFile%
		goto fail
	)
	powershell .\ConvertToBase64.ps1 -ex bypass -filePathAndName "%2"
	set /p Base64Data=< ConvertToBase64.txt
	
	rem %3 need to use \\ instead of \ (ex: C:\\Tools\\Audio\\File.txt)
	
	grpcurl.exe -insecure -d "{ \"targetPath\": \"%3\" , \"createDirectory\": \"true\" , \"fileBytes\": \"!Base64Data!\" }" %DUT_IP%:%ServicePorts% FileSystemService/CreateFile > %LogFile%
	if %errorlevel% equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:Get_PT_MacAddress
	set TestItem=%TestItems_Count%_Get_PassThroughLan_MacAddress
	set BFLogFile=GetPassThroughMacAddress
	set LogFile=GetPassThroughMacAddress.txt

	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% ProvisioningService/GetPassThroughMacAddress > %LogFile%
	findstr /c:"mac_address" %LogFile% > tmp.log
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto fail
	rem for /F "tokens=1,2* delims=\" " %%i in (tmp.log) do (
	
	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (tmp.log) do (
		set Reading=%%l
	)
	if defined Reading set Reading=%Reading: =%
	if defined Reading set MacAddress=%Reading::=%
	echo !MacAddress!> Mac_PTLan.txt
	set "length=0"
	set "str=!MacAddress!"
	
	@echo off
	:G_PT_Loop
	if not "%str%"=="" (
		set "str=%str:~1%"
		set /a length+=1
		goto G_PT_Loop
	)
	echo !length!>> Mac_PTLan.txt
	if !length! neq 12 goto fail
	@echo on
	set /p FTP_MacAddress=<..\..\PTLan_MacAddress.txt
	echo %FTP_MacAddress%>> Mac_PTLan.txt
	findstr /c:"%FTP_MacAddress%" %LogFile% > ..\Temp\Check_PTmac.log
	if %errorlevel% neq 0 goto fail
	REM find /i "000000000000" Mac_PTLan.txt
	REM if %errorlevel% neq 1 goto fail
	REM find /i "FFFFFFFFFFFF"  Mac_PTLan.txt
	REM if %errorlevel% neq 1 goto fail
	REM find /i "888888888888"  Mac_PTLan.txt
	REM if %errorlevel% neq 1 goto fail
	goto pass

:Set_PT_MacAddress
	set TestItem=%TestItems_Count%_Set_PassThroughLan_MacAddress
	set BFLogFile=SetPassThroughMacAddress
	set LogFile=SetPassThroughMacAddress.txt
	
	if exist %LogFile% del /q %LogFile%
	if "%2"=="" (
		echo No destination file defined in parameter. > %LogFile%
		goto fail
	)

	set "length=0"
	set "str=%2"
	
	@echo off
	:S_PT_Loop
	if not "%str%"=="" (
		set "str=%str:~1%"
		set /a length+=1
		goto S_PT_Loop
	)
	if !length! neq 12 goto fail
	@echo on

	echo grpcurl.exe -emit-defaults -insecure -d "{ \"macAddress\": \"%2\" }" %DUT_IP%:%ServicePorts% ProvisioningService/SetPassThroughMacAddress > %LogFile%	
	grpcurl.exe -emit-defaults -insecure -d "{ \"macAddress\": \"%2\" }" %DUT_IP%:%ServicePorts% ProvisioningService/SetPassThroughMacAddress >> %LogFile%
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto fail
	goto pass
	

:Wlan_MAC
	set TestItem=%TestItems_Count%_Get_WLan_MacAddress
	set BFLogFile=GetWLanMacAddress
	set LogFile=GetWLanMacAddress.txt
	DevInfo-diag.exe -SN %SN% /cmd GetWLanMacAddress > %LogFile%
	findstr /c:"index 0=" %LogFile% > tmp.log
	if errorlevel 1 echo NA >..\Tools\Temp\__Mac_WLAN.txt & goto fail
	FOR /F "tokens=1,2* delims==" %%i in (tmp.log) do (
		set Reading=%%j
	)
	if defined Reading set Reading=%Reading: =%
	if defined Reading set MacAddress=%Reading::=%
	echo %MacAddress% > ..\Tools\Temp\__Mac_WLAN.txt
	echo %MacAddress% > ..\Temp\__Mac_WLAN.txt
	find /i "000000000000" ..\Tools\Temp\__Mac_WLAN.txt
	if %errorlevel% neq 1 goto fail
	find /i "FFFFFFFFFFFF" ..\Tools\Temp\__Mac_WLAN.txt
	if %errorlevel% neq 1 goto fail
	find /i "888888888888" ..\Tools\Temp\__Mac_WLAN.txt
	if %errorlevel% neq 1 goto fail
	goto pass

:BT_MAC
	set TestItem=%TestItems_Count%_Get_BT_MacAddress
	set BFLogFile=GetBtMacAddress
	set LogFile=GetBtMacAddress.txt
	DevInfo-diag.exe -SN %SN% /cmd GetBtMacAddress > %LogFile%
	findstr /c:"index=" %LogFile% > tmp.log
	if errorlevel 1 echo NA > ..\Tools\Temp\__Mac_BT.txt &goto fail
	FOR /F "tokens=1,2* delims==" %%i in (tmp.log) do (
		set Reading=%%j
	)
	if defined Reading set Reading=%Reading: =%
	if defined Reading set MacAddress=%Reading::=%
	echo %MacAddress% > ..\Tools\Temp\__Mac_BT.txt
	echo %MacAddress% > ..\Temp\__Mac_BT.txt
	find /i "000000000000" ..\Tools\Temp\__Mac_BT.txt
	if %errorlevel% neq 1 goto fail
	find /i "FFFFFFFFFFFF" ..\Tools\Temp\__Mac_BT.txt
	if %errorlevel% neq 1 goto fail
	find /i "888888888888" ..\Tools\Temp\__Mac_BT.txt
	if %errorlevel% neq 1 goto fail
	goto pass
	
:NIC_MAC
	set TestItem=%TestItems_Count%_Get_NIC_MacAddress
	set LogFile=GetEthernetMacAddress.txt
	rem below command will create "GetEthernetMacAddress.txt"
	DevInfo-diag.exe -SN %SN% /cmd GetEthernetMacAddress
	PT-diags.exe -nc -nl /find %LogFile% "Ethernet MAC Address ="
	if %errorlevel% equ 0 (
		goto pass
	) else (
		goto fail
	)

:CPU
	set TestItem=%TestItems_Count%_GetCPUInformation
	set BFLogFile=GetCpuInfo
	set LogFile=GetCpuInfo.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% DeviceInfoService/GetCPUInfo > %LogFile%
	findstr /c:"%2" %LogFile% 
		if %errorlevel% neq 0 (
		set rtn=255
	)
	findstr /c:"%3" %LogFile% 
		if %errorlevel% neq 0 (
		set rtn=255
	)

	if %rtn% equ 0 (
		goto pass
	) else (
		goto fail
	)
:CPU_SN
	set TestItem=%TestItems_Count%_Get_CPU_SerialNumber
	set BFLogFile=GetCPUSerialNumber
	set LogFile=GetCPUSerialNumber.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\Tools\\System\\QCSecurityCheckTool.exe\", \"arguments\": \"/getchipserialnum\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable > %LogFile%

	findstr /c:"Chip Serial Number on device" %LogFile% > tmp.log
	rem Check if Bifrost Log Error
	if %errorlevel% neq 0 goto fail
	REM for /f "tokens=1,2,3,4,5,6,7,* delims= " %%a in (tmp.log) do (
		REM set Reading=%%g
		REM echo %%g>..\Temp\CPU_SN.TXT
	REM )
	PT-diags.exe -sl 3 -el 3 -sa 254 -ea 271 /GStr %LogFile%> ..\Temp\CPU_SN.TXT
	findstr /c:"0x" ..\Temp\CPU_SN.TXT
	if %errorlevel% neq 0 goto fail
	PT-diags.exe /fs ..\Temp\CPU_SN.TXT 18
	if %errorlevel% neq 1 goto fail
	REM goto pass
	REM goto upload_CPU_SN
	:upload_CPU_SN
	set /p CPU_SN=<..\Temp\CPU_SN.txt

	echo .\Data_Upload\SFISupload-diag.exe.exe CpuSN %CPU_SN% %sn% >uploadCPU_SN.log
	call .\Data_Upload\SFISupload-diag.exe CpuSN %CPU_SN% %sn% >>uploadCPU_SN.log
	findstr /c:"DATA SAVE" uploadCPU_SN.log
		if !errorlevel! equ 0 (
			goto pass
		) else (
			set rtn=254
			goto fail
		)
	
	rem if defined Reading set Reading=%Reading: =%
	rem echo %Reading%
	REM set argCount=0
	REM for %%x in (%*) do (
		REM set /a argCount+=1
		REM set "argVec[!argCount!]=%%~x"
	REM )
	REM echo Number of processed arguments: %argCount%
	
	REM for /l %%i in (2,1,%argCount%) do (
		REM find /i "!argVec[%%i]!" tmp.log
		REM if !errorlevel!==0 goto pass
	REM )
	
	REM goto fail	

:SSD
	set TestItem=%TestItems_Count%_GetHardDiskInformation
	set BFLogFile=GetHardDiskInfos
	set LogFile=GetHardDiskInfos.txt
	set RTN=0
	if exist HDD_Vendor.txt del HDD_Vendor.txt
	if exist HDD_FW.txt del HDD_FW.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% StorageService/GetHardDiskInfos > %LogFile%
	PT-diags.exe -nc -nl /find %LogFile% "model_name" > HDD_Model.txt
	for /f "tokens=1,2* delims==" %%i in (HDD_Model.txt) do (
		set Reading=%%k
	)
	find /i %2 HDD_Model.txt
	if %errorlevel% neq 0 (
		set rtn=255
	)

	PT-diags.exe -nc -nl /find %LogFile% "size" > HDD_Size.txt
	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (HDD_Size.txt) do (
		set Reading=%%l
	)
	if defined Reading set Reading=%Reading: =%
	if "%Reading%" neq %3 (
		set rtn=255
	)
	
	PT-diags.exe -nc -nl /find %LogFile% "firmware_version" > HDD_FW.txt
	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (HDD_FW.txt) do (
		set Reading=%%l
	)
	if defined Reading set Reading=%Reading: =%
	if "%Reading%" neq %4 (
		set rtn=255
	) 

rem	PT-diags.exe -nc -nl /find %LogFile% "current_link_speed" > HDD_LinkSpeed.txt
rem	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (HDD_LinkSpeed.txt) do (
rem		set Reading=%%l
rem	)
rem	if defined Reading set Reading=%Reading: =%
rem	if "%Reading%" neq %5 (
rem		set rtn=255
rem	) 
rem
rem	PT-diags.exe -nc -nl /find %LogFile% "current_link_width" > HDD_LinkWidth.txt
rem	for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (HDD_LinkWidth.txt) do (
rem		set Reading=%%l
rem	)
rem	if defined Reading set Reading=%Reading: =%
rem	if "%Reading%" neq %6 (
rem		set rtn=255
rem	) 
	
	if %RTN% equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:Memory
	set TestItem=%TestItems_Count%_GetMemoryInformation
	set BFLogFile=GetPhysicalMemoryInfo
	set LogFile=GetPhysicalMemoryInfo.txt
	set rtn=0
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% DeviceInfoService/GetMemoryInfo > %LogFile%
	findstr /c:"%2" %LogFile% 
		if %errorlevel% neq 0 (
		set rtn=255
	)
	findstr /c:"%3" %LogFile% 
		if %errorlevel% neq 0 (
		set rtn=255
	)
	findstr /c:"%4" %LogFile% 
		if %errorlevel% neq 0 (
		set rtn=255
	)
	REM PT-diags.exe -nc -nl /find %LogFile% "Manufacturer" > Memory_Vendor.txt
	REM for /f "tokens=1,2* delims==" %%i in (Memory_Vendor.txt) do (
		REM set Reading=%%k
	REM )
	REM find /i %2 Memory_Vendor.txt
	REM if %errorlevel% neq 0 (
		REM set rtn=255
	REM )

	REM PT-diags.exe -nc -nl /find %LogFile% "Memory_Size" > Memory_Size.txt
	REM for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (Memory_Size.txt) do (
		REM set Reading=%%l
	REM )
	REM if defined Reading set Reading=%Reading: =%
	REM if "%Reading%" neq %3 (
		REM set rtn=255
	REM )
	
	REM PT-diags.exe -nc -nl /find %LogFile% "Memory_Freq" > Memory_Freq.txt
	REM for /f tokens^=1^,2^,3^,4^*^ delims^=^" %%i in (Memory_Freq.txt) do (
		REM set Reading=%%l
	REM )
	REM if defined Reading set Reading=%Reading: =%
	REM if "%Reading%" neq %4 (
		REM set rtn=255
	REM ) 
	
	if %rtn% equ 0 (
		goto pass
	) else (
		goto fail
	)
:Memoryfreq
	set TestItem=%TestItems_Count%_GetMemoryInformation
	set BFLogFile=GetPhysicalMemoryInfo
	set LogFile=GetPhysicalMemoryInfo.txt
	set rtn=0
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% DeviceInfoService/GetMemoryInfo > %LogFile%
	if not exist %LogFile% set rtn=255 
	REM if exist ..\UltraX7.fpc (
		REM findstr /c:"9600" %LogFile% 
		REM if %errorlevel% neq 0 set rtn=255
	REM )
	REM if exist ..\Ultra5.fpc (
		REM findstr /c:"Intel(R) Core(TM) Ultra 5 335" %LogFile% 
		REM if %errorlevel% neq 0 set rtn=255
	REM )
	REM findstr /c:"%2" %LogFile% 
		REM if %errorlevel% neq 0 (
		REM set rtn=255
	REM )
	
	if %rtn% equ 0 (
		goto pass
	) else (
		goto fail
	)	
:TPM
	set TestItem=%TestItems_Count%_GetTPMInformation
	set BFLogFile=GetTpmInfo
	set LogFile=GetTpmInfo.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% DeviceInfoService/GetTPMInfo > %LogFile%
	findstr /c:"%2" %LogFile% 
	if %errorlevel% equ 0 (
		goto pass
	) else (
		goto fail
	)
	rem Check for below info?
    rem "tpm_id": "1229870147",
    rem "tpm_version": "700.21.0.1155",
    rem "tpm_mode": "TPM_MODE_D_TPM"
  
:PCI_Info
	set TestItem=%TestItems_Count%_GetPCIInformation
	set BFLogFile=GetHardwareComponents DevNodeInfo
	set LogFile=GetHardwareComponents.txt
	set rtn=0
	
	if exist %LogFile% del /q %LogFile%
	del /q GetHardwareComponents_NG.txt
	rem below command will create "GetHardwareComponents.txt"
	DevInfo-diag.exe -SN %SN% /cmd GetHardwareComponents
	for /f "delims=" %%b in ('type %LogFile%') do (
		echo "%%b" | find /i "Device Status: 0"
		if !errorlevel! equ 0 (
			echo found
		) else (
			if exist NG.txt del NG.txt
			echo "%%b" > NG.txt
			call :ExceptionHandle noarg
		)
	)
	goto Additional_PCI_Check
	
	:ExceptionHandle
	rem not install on FCT tester
	PT-diags.exe -nc -nl /find NG.txt "Name: Camera Sensor OV13858, FriendlyName: Surface Camera Rear, Device Status: 10"
	if !errorlevel! equ 0 goto Skip_Device_Check
	PT-diags.exe -nc -nl /find NG.txt "Name: Camera Sensor VD55G0, FriendlyName: Surface IR Camera Front, Device Status: 10"
	if !errorlevel! equ 0 goto Skip_Device_Check
	PT-diags.exe -nc -nl /find NG.txt "Name: Camera Sensor IMX681, FriendlyName: Surface Camera Front, Device Status: 10"
	if !errorlevel! equ 0 goto Skip_Device_Check
	PT-diags.exe -nc -nl /find NG.txt "Name: Intel(R) Quick SPI Host Controller - 7E49, FriendlyName: null, Device Status: 10"
	if !errorlevel! equ 0 goto Skip_Device_Check
	
	rem skip according to MTE PMs request
	PT-diags.exe -nc -nl /find NG.txt "Name: PCI Data Acquisition and Signal Processing Controller, FriendlyName: null, Device Status: 28"
	if !errorlevel! equ 0 goto Skip_Device_Check
	PT-diags.exe -nc -nl /find NG.txt "Name: Surface SMF Core Driver, FriendlyName: null, Device Status: 31"
	if !errorlevel! equ 0 goto Skip_Device_Check
	PT-diags.exe -nc -nl /find NG.txt "Name: Surface Machine Learning Service Driver, FriendlyName: null, Device Status: 28"
	if !errorlevel! equ 0 goto Skip_Device_Check
	PT-diags.exe -nc -nl /find NG.txt "Name: Intel Connectivity Performance Suite, FriendlyName: null, Device Status: 28"
	if !errorlevel! equ 0 goto Skip_Device_Check
	type NG.txt >> GetHardwareComponents_NG.txt
	echo not found
	set rtn=255
			
	:Skip_Device_Check
	if exist NG.txt del NG.txt
	exit /b
	
	:Additional_PCI_Check
	rem rem check for [Bluetooth]
	rem rem USB1_DEV=USB\VID_8087&PID_0033&REV_0000
	rem PT-diags.exe -nc -nl /find %LogFile% "USB\VID_8087&PID_0033&REV_0000"
	rem if %errorlevel% neq 0 set rtn=255
	rem 
	rem rem check for [WLAN]
	rem rem WLAN1_DEV=PCI\VEN_8086&DEV_51F0&SUBSYS_00948086&REV_01
	rem PT-diags.exe -nc -nl /find %LogFile% "PCI\VEN_8086&DEV_51F0&SUBSYS_00948086&REV_01"
	rem if %errorlevel% neq 0 set rtn=255
	
	echo %~dp0 > getpath.txt
	for /f "tokens=1,2,3,* delims=\" %%a in (getpath.txt) do (
		echo %%b> path1.txt
		echo %%c> path2.txt
	)
	set /p path1=<path1.txt
	set /p path2=<path2.txt
	
	echo %rtn%
	if %rtn% equ 0 (
		goto pass
	) else (
		if not exist ..\Tools\Temp\MISClog\%TestItem% MKDIR ..\Tools\Temp\MISClog\%TestItem%
		if exist GetHardwareComponents_NG.txt copy /y GetHardwareComponents_NG.txt ..\Tools\Temp\MISClog\%TestItem%\
		
		rem DevInfo-diag.exe /cmd "SendFile C:\%path1%\%path2%\Tools\Update\Capture.bat E:\Diags\Jalama\Tools\Capture.bat"
		rem DevInfo-diag.exe /cmd "RunExecutable E:\Diags\Jalama\Tools\Update\Capture.bat" -para "1"
		rem 
		rem echo dir /b /o-d E:\Diags\Jalama\Tools\Update\DeviceManager > chk.bat
		rem DevInfo-diag.exe /cmd "SendFile C:\%dd%\%dd%\Tools\Update\chk.bat E:\Diags\Jalama\Tools\Update\chk.bat"
		rem DevInfo-diag.exe /cmd "RunExecutable E:\Diags\Jalama\Tools\Update\chk.bat" -para "1" >aa.log
		rem for /f "skip=5 tokens=1,2 delims= " %%i in (aa.log) do (
		rem 	echo %%i_%%j>b.txt
		rem )
		rem timeout 1
		rem set /p bb=<b.txt
		rem 
		rem DevInfo-diag.exe /cmd "RunExecutable E:\Diags\Jalama\Tools\Update\7z.exe" -para "a -y DeviceManager_%bb%.zip DeviceManager"
		rem DevInfo-diag.exe /cmd "GetFile E:\Diags\Jalama\Tools\Update\DeviceManager\DeviceManager_%bb%.zip C:\!dd!\!dd!\Temp\DeviceManager_%bb%.zip"
		rem DevInfo-diag.exe -SN %SN% -wto 15 -name C:\Tools\WDK\Tools\x64\Devcon.exe -arg "disable {98DE32A9-5D44-419E-B67D-66072BCEF58B}*" /run
		rem DevInfo-diag.exe -SN %SN% -wto 15 -name C:\Tools\WDK\Tools\x64\Devcon.exe -arg "disable INTELAUDIO*" /run
		rem DevInfo-diag.exe -SN %SN% -wto 15 -name C:\Tools\WDK\Tools\x64\Devcon.exe -arg "enable {98DE32A9-5D44-419E-B67D-66072BCEF58B}*" /run
		rem DevInfo-diag.exe -SN %SN% -wto 15 -name C:\Tools\WDK\Tools\x64\Devcon.exe -arg "enable INTELAUDIO*" /run
		goto fail
	) 
 
:Temperature
	set TestItem=%TestItems_Count%_GetTemperatureInformation
	set BFLogFile=GetThermals
	set LogFile=GetThermals.txt
	if "%2"=="Get" (
		del %LogFile%
		DevInfo-diag.exe -SN %SN% /cmd GetThermals > %LogFile%
		if not exist %LogFile% goto fail
		
		del /q ..\Tools\Temp\MISClog\_Temp*_Result.log
		findstr /c:"skin" %LogFile% > tmp.log
		set ccc=1
		for /f "tokens=1,2,3,4,5,6,7,8* delims=,)" %%i in (tmp.log) do (
			echo %%k > ..\Tools\Temp\MISClog\_Temp!ccc!_Result.log
			set /a ccc+=1
		)	
		goto pass
	)
	
	Set SkipCountAdd=True
	:chk
	set /p Reading=<..\Tools\Temp\MISClog\_Temp%2_Result.log
	if defined Reading set Reading=%Reading: =%
	if %Reading% LEQ %3 echo less than value & set rtn=1& goto not_backup
	if %Reading% GEQ %4 echo greater than value & set rtn=2& goto not_backup
	set rtn=0& goto not_backup

:SurfLink_GetID
	set TestItem=%TestItems_Count%_GetSurfLinkId
	set BFLogFile=GetSurfLinkId
	set LogFile=GetSurfLinkId.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% SurflinkService/GetId > %LogFile%
	PT-diags.exe -nc -nl /find %LogFile% "resistor_id_bin" > SL_Bin_Result.txt
	PT-diags.exe -nc -nl /find %LogFile% "resistor_id_adc" > SL_Adc_Result.txt
	for /F "tokens=1,2* delims=:" %%i in (SL_Bin_Result.txt) do (
		set Reading=%%j
	)
	if defined Reading set Bin_Reading=%Reading: =%
	if defined Reading set Bin_Reading=!Bin_Reading:,=!
	echo !Bin_Reading!
	for /F "tokens=1,2* delims=:" %%i in (SL_Adc_Result.txt) do (
		set Reading=%%j
	)
	if defined Reading set Adc_Reading=%Reading: =%
	echo !Adc_Reading!
	
	if /I "%2"=="Adc" (
		if !Adc_Reading! LEQ %3 echo less than value& set rtn=1& goto not_backup
		if !Adc_Reading! GEQ %4 echo greater than value& set rtn=2& goto not_backup
		set rtn=0& goto not_backup
	)
	if /I "%2"=="Bin" (
		if !Bin_Reading! neq %3 set rtn=255& goto not_backup
		set rtn=0& goto not_backup
	) else (
		if !Bin_Reading! neq %2 set rtn=255& goto not_backup
		if !Adc_Reading! LEQ %3 echo less than value& set rtn=1& goto not_backup
		if !Adc_Reading! GEQ %4 echo greater than value& set rtn=2& goto not_backup
		set rtn=0& goto not_backup
	)
	exit /b 255

:SystemPowerControl
	set TestItem=%TestItems_Count%_SystemPowerControl
	set BFLogFile=SendPowerCommand
	if /I "%2"=="Shutdown" set PwrStates=Shutdown&set CtlCommand=POWER_CONTROL_COMMAND_SHUTDOWN
	if /I "%2"=="Reboot" set PwrStates=Reboot&set CtlCommand=POWER_CONTROL_COMMAND_REBOOT
	set LogFile=SendPwrCtl!PwrStates!Command.txt
	
	if exist %LogFile% del /q %LogFile%
	echo grpcurl.exe -insecure -d "{ \"command\": \"%CtlCommand%\"  }" %DUT_IP%:%ServicePorts% SystemPowerControlService/SendPowerControlCommand > %LogFile%
	grpcurl.exe -insecure -d "{ \"command\": \"%CtlCommand%\"  }" %DUT_IP%:%ServicePorts% SystemPowerControlService/SendPowerControlCommand >> %LogFile%
	if %errorlevel% equ 0 (
		goto pass
	) else (
		goto fail
	)
	rem Check for below info?
    rem "tpm_id": "1229870147",
    rem "tpm_version": "700.21.0.1155",
    rem "tpm_mode": "TPM_MODE_D_TPM"
	
:Get_POST_Time	
	set TestItem=%TestItems_Count%_Get_POSTTime
	set BFLogFile=GetPOSTTime
	set LogFile=GetPOSTTime.txt

	if exist %LogFile% del /q %LogFile%
	if exist UEFIPostTime.txt del /q UEFIPostTime.txt
	grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\Windows\\System32\\reg.exe\", \"arguments\": \"query \\\"HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Power\\\" /v fwPOSTTime\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable > %LogFile%
	powershell -ex bypass .\ReplaceLineBreaks.ps1 -InputFile "GetPOSTTime.txt" -OutputFile "GetPOSTTime_Modified.txt"
	findstr /c:"fwPOSTTime    REG_DWORD"  "GetPOSTTime_Modified.txt" > tmp.txt
	for /f "delims=x tokens=1,2*" %%i in (tmp.txt) do (
		set POSTTime_Hex=%%j	
	)
	set /a POSTTime=0x%POSTTime_Hex%
	echo  "%POSTTime%"
	echo %POSTTime% >UEFIPostTime.txt
	goto pass
	REM exit /b 0
	
:BT_PID_CHECK
	Set TestItem=%TestItems_Count%_Bluetooth_PID_VID_check
	set LogFile=GetHardwareComponents.txt 
	IF not exist %LogFile% exit /b 255
	find /i %2 %LogFile%

	if %errorlevel% equ 0 goto pass	
	goto fail

:TPM_Switch
	set TestItem=%TestItems_Count%_SetTPMType
	set BFLogFile=SetTPMType
	set LogFile=SetTPMType.txt


	if exist %LogFile% del /q %LogFile%
	if "%2"=="" set TPMType=dTPM
	rem %2 support dTPM , fTPM
	echo -----grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\Tools\\tpmconfiguration\\GetTpmType.cmd\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable---- > %LogFile%
	grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\Tools\\tpmconfiguration\\GetTpmType.cmd\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable >> %LogFile%
	findstr /c:"Current TPM configuration is dTPM" %LogFile%
	if %errorlevel% equ 0 goto pass	
	
	echo -----grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\Tools\\tpmconfiguration\\SetTpmType.cmd\", \"arguments\": \"!TPMType!\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable----- >> %LogFile%
	grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\Tools\\tpmconfiguration\\SetTpmType.cmd\", \"arguments\": \"!TPMType!\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable >> %LogFile%
	if %errorlevel% equ 0 (
	goto pass
	) else (
	REM TPMSwitch may reboot too fast, grpc errorlevel could not be 0, check DUT is dTPMType after auto-reboot
	REM goto fail
	goto pass
	)
	
:TPM_Switch_Check
	set TestItem=%TestItems_Count%_CheckTPMType
	set BFLogFile=CheckTPMType
	set LogFile=CheckTPMType.txt


	if exist %LogFile% del /q %LogFile%
	if "%2"=="" set checkTPMType=dTPM
	rem %2 support dTPM , fTPM
	if "%2"=="fTPM" set checkTPMType=fTPM
	if "%2"=="dTPM" set checkTPMType=dTPM
	
	echo -----grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\Tools\\tpmconfiguration\\GetTpmType.cmd\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable---- > %LogFile%
	grpcurl.exe -insecure -d "{ \"executablePath\": \"C:\\Tools\\tpmconfiguration\\GetTpmType.cmd\" }" %DUT_IP%:%ServicePorts% ExecutableService/RunExecutable >> %LogFile%
	if %checkTPMType%==fTPM goto fTPM_check
	findstr /c:"Current TPM configuration is dTPM" %LogFile%
	if %errorlevel% equ 0 goto pass	
	goto fail
	:fTPM_check
	findstr /c:"Current TPM configuration is fTPM" %LogFile%
	if %errorlevel% equ 0 goto pass	
	goto fail
	
:RebootTest
	set TestItem=%TestItems_Count%_Reboot
	set BFLogFile=Reboot Device_Configure
	set LogFile=Reboot.txt
	DevInfo-diag.exe /cmd "RebootTest true" -cmp Done > %LogFile%
	if %errorlevel% neq 0 goto fail 
	goto pass
	
:Shutdown	
	set TestItem=%TestItems_Count%_Shutdown
	set BFLogFile=Shutdown
	set LogFile=Shutdown.txt
	DevInfo-diag.exe /cmd "Shutdown true" -cmp Done > %LogFile%
	if %errorlevel% neq 0 goto fail 
	goto pass

:DiskSmartTest
set TestItem=%TestItems_Count%_DiskSmartStatus
set BFLogFile=PingDiskSmartStatus
set LogFile=PingDiskSmartStatus.txt

DevInfo-diag.exe -SN %SN% /cmd PingDiskSmartStatus -cmp "Done" > %LogFile%
if %errorlevel% equ 0 goto pass	
goto fail
	
:NoParameter
echo no Parameter enter.
goto End




:fail
echo fail
REM PAUSE
cd %~dp0
REM if not exist ..\Tools\Temp\MISClog\%TestItem% MKDIR ..\Tools\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Temp\
..\Tools\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleSystem" -to "..\Temp" -w -e 0 -timeout 10
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
REM if not exist ..\Tools\Temp\MISClog\%TestItem% MKDIR ..\Tools\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Temp\
..\Tools\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleSystem" -to "..\Temp" -w -e 0 -timeout 10
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