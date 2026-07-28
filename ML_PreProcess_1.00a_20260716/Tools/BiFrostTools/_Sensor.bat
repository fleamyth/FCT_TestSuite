@ECHO ON
cd %~dp0
setlocal EnableDelayedExpansion
rem grpcui.exe -insecure 192.168.1.51:16140

:Start
SET DUT_IP=192.168.1.51
SET ServicePorts=16140
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
if /I "%1"=="Accel_SEC" goto GetAccelSecSamples
if /I "%1"=="Accel_PRISelfTest" goto AccelPriSelftest
if /I "%1"=="Accel_SECSelfTest" goto AccelSecSelftest
if /I "%1"=="Gyro" goto GetGyroSamples
if /I "%1"=="Gyro_SelfTest" goto GyroSelfTest
if /I "%1"=="ACS" goto GetACSSamples
if /I "%1"=="ACS_SelfTest" goto ACSSelfTest
if /I "%1"=="Mag" goto GetMagSamples
if /I "%1"=="Mag_SelfTest" goto MagSelfTest
if /I "%1"=="Hall_Pri" goto GetHallPriState
if /I "%1"=="Hall_Sec" goto GetHallSecState
if /I "%1"=="" goto NoParameter
goto NoParameter


:GetAccelPriSamples
	set TestItem=%TestItems_Count%_Get_Accel_Primary_Samples
	set BFLogFile=GetAccelPriSamples
	set LogFile=GetAccelPriSamples.txt
	set SensorName=PRIMARY ACCELEROMETER
	goto GetAccelSamples

:GetAccelSecSamples
	set TestItem=%TestItems_Count%_Get_Accel_Second_Samples
	set BFLogFile=GetAccelSecSamples
	set LogFile=GetAccelSecSamples.txt
	set SensorName=SECONDARY ACCELEROMETER
	goto GetAccelSamples

:AccelPriSelfTest
	set TestItem=%TestItems_Count%_Get_Accel_Primary_SelfTest
	set BFLogFile=GetAccelPriSelfTest
	set LogFile=GetAccelPriSelfTest.txt
	set SensorName=PRIMARY ACCELEROMETER
	goto SelfTestCheck

:AccelSecSelfTest
	set TestItem=%TestItems_Count%_Get_Accel_Second_SelfTest
	set BFLogFile=GetAccelSecSelfTest
	set LogFile=GetAccelSecSelfTest.txt
	set SensorName=SECONDARY ACCELEROMETER
	goto SelfTestCheck
	
:GetAccelSamples
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
	grpcurl.exe -insecure -d "{ \"sensorName\": \"%SensorName%\" , \"samplingRate\": \"%samplingRate%\" , \"numOfSamples\": \"%numOfSamples%\"}" %DUT_IP%:%ServicePorts% SensorService/GetAccelSamples > %LogFile%
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

:GetGyroSamples
	set TestItem=%TestItems_Count%_Get_Gyro_Samples
	set BFLogFile=GetGyroSamples
	set LogFile=GetGyroSamples.txt
	
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
	grpcurl.exe -insecure -d "{ \"sensorName\": \"GYROSCOPE\" , \"samplingRate\": \"%samplingRate%\" , \"numOfSamples\": \"%numOfSamples%\"}" %DUT_IP%:%ServicePorts% SensorService/GetGyroSamples > %LogFile%
	if %errorlevel% equ 0 (
		findstr /c:"gyro_sensor_samples" %LogFile% 
		if !errorlevel! equ 0 (
			goto pass
		) else (
			goto fail
		)
	) else (
		goto fail
	)

:GetMagSamples
	set TestItem=%TestItems_Count%_Get_Mag_Samples
	set BFLogFile=GetMagSamples
	set LogFile=GetMagSamples.txt
	
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
	grpcurl.exe -insecure -d "{ \"sensorName\": \"MAGNETOMETER\" , \"samplingRate\": \"%samplingRate%\" , \"numOfSamples\": \"%numOfSamples%\"}" %DUT_IP%:%ServicePorts% SensorService/GetGyroSamples > %LogFile%
	if %errorlevel% equ 0 (
		findstr /c:"gyro_sensor_samples" %LogFile% 
		if !errorlevel! equ 0 (
			goto pass
		) else (
			goto fail
		)
	) else (
		goto fail
	)


:GyroSelfTest
	set TestItem=%TestItems_Count%_Get_Gyro_SelfTest
	set BFLogFile=GetGyroSelfTest
	set LogFile=GetGyroSelfTest.txt
	set SensorName=GYROSCOPE
	goto SelfTestCheck

:GetACSSamples
	set TestItem=%TestItems_Count%_Get_ACS_Samples
	set BFLogFile=GetACSSamples
	set LogFile=GetACSSamples.txt
	
	del /q %LogFile%
	if /I "%2"=="" (
		set numOfSamples=100
	) else (
		set numOfSamples=%2
	)
	grpcurl.exe -insecure -d "{ \"numOfSamples\": \"%numOfSamples%\"}" %DUT_IP%:%ServicePorts% SensorService/GetACSSamples > %LogFile%
	if %errorlevel% equ 0 (
		findstr /c:"acs_sensor_samples" %LogFile% 
		if !errorlevel! equ 0 (
			goto pass
		) else (
			goto fail
		)
	) else (
		goto fail
	)

:ACSSelfTest
	set TestItem=%TestItems_Count%_Get_ACS_SelfTest
	set BFLogFile=GetACSSelfTest
	set LogFile=GetACSSelfTest.txt
	set SensorName=ACS
	goto SelfTestCheck
	
:MagSelfTest
	set TestItem=%TestItems_Count%_Get_MAG_SelfTest
	set BFLogFile=GetMagSelfTest
	set LogFile=GetMagSelfTest.txt
	set SensorName=MAGNETOMETER
	goto SelfTestCheck
	
:SelfTestCheck
	del /q %LogFile%

	grpcurl.exe -insecure -d "{ \"sensorName\": \"%SensorName%\" }" %DUT_IP%:%ServicePorts% SensorService/SensorSelfCheck > %LogFile%
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)

:GetHallPriState
	set TestItem=%TestItems_Count%_Get_Hall_Primary_State
	set BFLogFile=GetHallPriState
	if /I "%2"=="1" set HallStates=Off
	if /I "%2"=="0" set HallStates=On
	set LogFile=GetHallPri!HallStates!State.txt
	set SensorName=PRIMARY HALL
	goto GetHallState

:GetHallSecState
	set TestItem=%TestItems_Count%_Get_Hall_Second_State
	set BFLogFile=GetHallSecState
	if /I "%2"=="1" set HallStates=Off
	if /I "%2"=="0" set HallStates=On
	set LogFile=GetHallSec!HallStates!State.txt
	set SensorName=SECONDARY HALL
	goto GetHallState

:GetHallState
	del /q %LogFile%

	rem powershell -ex bypass .\DateTime.ps1
	rem set /p DateTime=<IPC_DateTime.txt
	rem echo %DateTime%
	
	rem grpcurl.exe -insecure -d "{ \"targetPath\": \"c:\\data\\BiFrost\\Logs\\BiFrostModuleSensor\\logBiFrostModuleSensor%datetime:~0,4%%datetime:~5,2%%datetime:~8,2%.txt\" }" %DUT_IP%:16137 FileSystemService/GetFileBytes > BFLogFile_BeforeTest.txt
	rem if not exist BFLogFile_BeforeTest.txt echo. > BFLogFile_BeforeTest.txt
	
	rem powershell .\ConvertFromBase64.ps1 -ex bypass -base64FilePathAndName "%~dp0BFLogFile_BeforeTest.txt"
	rem set /p Base64Data=< ConvertFromBase64.txt
	
	grpcurl.exe -emit-defaults -insecure -d "{ \"sensorName\": \"%SensorName%\" }" %DUT_IP%:%ServicePorts% SensorService/GetHallState  > %LogFile%
	
	rem grpcurl.exe -insecure -d "{ \"targetPath\": \"c:\\data\\BiFrost\\Logs\\BiFrostModuleSensor\\logBiFrostModuleSensor%datetime:~0,4%%datetime:~5,2%%datetime:~8,2%.txt\" }" %DUT_IP%:%ServicePorts% FileSystemService/GetFileBytes > BFLogFile_AfterTest.txt
	if /I "%2"=="" exit /b 255	
	findstr /c:"\"hall_state\": %2" %LogFile% 
	if !errorlevel! equ 0 (
		goto pass
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
..\Tools\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleSensor" -to "..\Temp" -w -e 0 -timeout 10
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
..\Tools\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleSensor" -to "..\Temp" -w -e 0 -timeout 10
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