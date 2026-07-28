@ECHO ON
cd %~dp0
setlocal EnableDelayedExpansion
rem grpcui.exe -insecure 192.168.1.51:16132

:Start
SET DUT_IP=192.168.1.51
SET ServicePorts=16132
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
if /I "%1"=="Push_Button" goto StreamButtonState
if /I "%1"=="" goto NoParameter
goto NoParameter
	
:StreamButtonState
	set TestItem=%TestItems_Count%_Get_Button_State
	set BFLogFile=GetButtonState
	set LogFile=GetButtonState.txt
	
	if exist %LogFile% del /q %LogFile%
	set Second_For_Wait_keyInput=4
	if "%2"=="" (
		echo parameter should be VolumeDown,VolumeUp or others....
		exit /b 255
	) else (
		start Screen-diag.exe -nl /Show %2.jpg
		set LogFile=Get%2ButtonState.txt
		grpcurl.exe -vv -emit-defaults -max-time %Second_For_Wait_keyInput% -insecure -d "{\"buttonName\": \"%2\"}" %DUT_IP%:%ServicePorts% ButtonService/StreamButtonState > !LogFile! 2>&1 
	)
	rem timeout %Second_For_Wait_keyInput%
	findstr /c:"\"button_name\": \"%2\"" !LogFile! 
	if !errorlevel! equ 0 (
		echo Find %2
		findstr /c:"\"pressed\": false" !LogFile! 
		if !errorlevel! equ 0 (
			echo Find "pressed": false
			findstr /c:"\"pressed\": true" !LogFile! 
			if !errorlevel! equ 0 (
				goto pass
			) else (
				goto fail
			)
		) else (
			goto fail
		)
	) else (
		goto fail
	)

	
:NoParameter
taskkill /im "Screen-diag.exe"
echo no Parameter enter.
goto End


:fail
echo fail
cd %~dp0
if not exist ..\Temp\MISClog\%TestItem% MKDIR ..\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Temp\MISClog\%TestItem%
..\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleButton" -to "..\Temp" -w -e 0 -timeout 10
REM for %%D in (!BFLogFile!) do move /y C:\DeviceBridgeLogs\%SN%_%TSRID_DB%\*%%D*.* ..\Tools\Temp\MISClog\%TestItem%\
taskkill /im "Screen-diag.exe"
echo rtn="%rtn%"
if defined rtn (
	exit /b %rtn% 
) else (
	exit /b 255
)

:pass
echo pass
cd %~dp0
if not exist ..\Temp\MISClog\%TestItem% MKDIR ..\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Temp\MISClog\%TestItem%
..\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleButton" -to "..\Temp" -w -e 0 -timeout 10
REM for %%D in (!BFLogFile!) do move /y C:\DeviceBridgeLogs\%SN%_%TSRID_DB%\*%%D*.* ..\Tools\Temp\MISClog\%TestItem%\
taskkill /im "Screen-diag.exe"
exit /b 0

:not_backup
if defined rtn (
	echo %rtn%
	exit /b %rtn%
) else ( 
	exit /b 255
)

:End