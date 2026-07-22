@ECHO ON
cd %~dp0
setlocal EnableDelayedExpansion

:Start
SET DUT_IP=192.168.1.51
SET ServicePorts=16135
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
if /I "%1"=="Accel_PRI" goto GetAccelPriSamples
if /I "%1"=="" goto NoParameter
goto NoParameter
	
:GetAccelPriSamples
	set TestItem=%TestItems_Count%_Get_Accel_Primary_Samples
	set BFLogFile=GetAccelPriSamples
	set LogFile=GetAccelPriSamples.txt
	
	del /q %LogFile%
	if /I "%2"=="" (
		set samplingRate=100
	) else (
		set samplingRate=%2
	)
	if /I "%3"=="" (
		set numOfSamples=100
	) else (
		set numOfSamples=%3
	)
	grpcurl.exe -insecure -d "{ \"sensorName\": \"PRIMARY ACCELEROMETER\" , \"samplingRate\": \"%samplingRate%\" , \"numOfSamples\": \"%numOfSamples%\"}" %DUT_IP%:%ServicePorts% SensorService/GetAccelSamples > %LogFile%
	if %errorlevel% equ 0 (
		findstr /c:"accel_sensor_samples" %LogFile% 
		if !errorlevel! equ 0 (
			goto pass
		) else (
			goto fail
		)
	) else (
		goto fail
	)

	
:NoParameter
echo no Parameter enter.
goto End


:fail
echo fail
cd %~dp0
if not exist ..\Tools\Temp\MISClog\%TestItem% MKDIR ..\Tools\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Temp\
..\Tools\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleDisplay" -to "..\Temp" -w -e 0 -timeout 10
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
if defined LogFile copy /y %LogFile% ..\Temp\
..\Tools\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleDisplay" -to "..\Temp" -w -e 0 -timeout 10
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