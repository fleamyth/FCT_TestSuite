@ECHO ON
cd %~dp0
setlocal EnableDelayedExpansion
rem grpcui.exe -insecure 192.168.1.51:16136

:Start
SET DUT_IP=192.168.1.51
SET ServicePorts=16136
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
if /I "%1"=="CaptureFrontRgbImage" goto Capture_FrontRgb_Image
if /I "%1"=="CaptureRearRgbImage" goto Capture_RearRgb_Image
if /I "%1"=="CaptureFrontIrImage" goto Capture_FrontIr_Image
if /I "%1"=="" goto NoParameter
goto NoParameter

	
:Capture_FrontRgb_Image
	set TestItem=%TestItems_Count%_Capture_Front_Image
	set BFLogFile=CaptureTestPattern
	set LogFile=CaptureTestPattern.txt
	set CamaraName=FrontRgb
	set width=3844
	set height=2640
	set NoOfFrameToDrop=15
	goto CaptureTestPattern
	
:Capture_RearRgb_Image
	set TestItem=%TestItems_Count%_Capture_Rear_Image
	set BFLogFile=CaptureTestPattern
	set LogFile=CaptureTestPattern.txt
	set CamaraName=RearRgb
	set width=4076
	set height=2806
	set NoOfFrameToDrop=15
	goto CaptureTestPattern
	
:Capture_FrontIr_Image
	set TestItem=%TestItems_Count%_Capture_IR_Image
	set BFLogFile=CaptureTestPattern
	set LogFile=CaptureTestPattern.txt
	set CamaraName=FrontIr
	set width=644
	set height=604
	set NoOfFrameToDrop=15
	goto CaptureTestPattern
		
:CaptureTestPattern
	if exist %LogFile% del /q %LogFile%
	set Second_For_Wait_keyInput=5
	set LogFile=Capture%CamaraName%TestPattern.txt
	grpcurl.exe -max-msg-sz 674217728 -insecure -d "{ \"cameraName\": \"%CamaraName%\", \"framesToDrop\": \"%NoOfFrameToDrop%\"}" %DUT_IP%:%ServicePorts% CameraService/CaptureTestPattern > !LogFile! 2>&1 
	findstr /c:"\"width\": %width%" !LogFile! 
	if !errorlevel! equ 0 (
		findstr /c:"\"height\": %height%" !LogFile! 
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
REM if not exist ..\Temp\MISClog\%TestItem% MKDIR ..\Temp\MISClog\%TestItem%
copy /y %LogFile% ..\Temp
REM copy /y %LogFile% ..\Temp\MISClog\%TestItem%
..\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleCamera" -to "..\Temp" -w -e 0 -timeout 10
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
copy /y %LogFile% ..\Temp
REM copy /y %LogFile% ..\Temp\MISClog\%TestItem%
..\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModuleCamera" -to "..\Temp" -w -e 0 -timeout 10
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