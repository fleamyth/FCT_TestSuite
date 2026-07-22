REM Program Description
REM Copyright by Pegatron, Build Date:2016-11-02 Rev1.01f, Diagnostics
REM ============================================================
@echo on
IF EXIST op.dat DEL op.dat
REM ===== Version Setting =====
SET Ver=1.00a
SET DateVer=20260716
REM ===========================
SET TYPE=%1
SET MODE=%2
SET TEST_MODE=Online
IF "%MODE%" EQU "D" SET TEST_MODE=Offline
SET PROJECT=Shawville
SET SUITE_NAME=ML_Calibration
SET BUILD=MP
SET CSV_NAME=%PROJECT%_%TYPE%.csv
SET CFG_NAME=config.xml
IF "%DebugXML%" equ "True" SET CFG_NAME=config_Deb.xml
SET SN_LEN=12
SET FOLDER=%SUITE_NAME%_%Ver%_%DateVer%
SET on_Drive=N:
SET SFIS_IP=172.27.76.10
SET Connect=FALSE
rem CALL DHCP.BAT
SET /a SCAN=0

:START_OP
IF NOT EXIST C:\MFGlog\%TYPE%log\event mkdir C:\MFGlog\%TYPE%log\event
IF EXIST MISClog.dat DEL MISClog.dat
IF "%MODE%" NEQ "D" ECHO C:\MISClog>MISClog.dat

SET Result=
cd %~dp0
IF EXIST %CSV_NAME% DEL %CSV_NAME%
IF EXIST *KoreVer.log DEL *KoreVer.log
IF EXIST PN.log DEL PN.log
IF EXIST PN.txt DEL PN.txt
IF EXIST op.dat GOTO SCANSN

DiagPGM\Chopper-diag.exe /SB "^[Ss][0-9]{2}[0-9,AaBbCc][0-9]{5}$" -SIF op.jpg -EMF sb_msg_OP.msgdat -SFN ..\OP.dat -FS 30 -st "Please scan operator number\nPlease Enter Operator Number" -sbsize 800 300
IF %ERRORLEVEL% NEQ 0 GOTO START_OP

:START
DiagPGM\Screen-diag.exe -nl -enter /SS 55 "<br>Please connect the device.<br> <br>Press [Enter] to start the test." 0xFFFFFF -bg 0x223366

adb get-state 2>nul | findstr /X /C:"device" >nul
IF %ERRORLEVEL% NEQ 0 GOTO START

SET ScanTime=0

:GetDutSN
REM Get SN from DUT
IF EXIST SN.dat DEL SN.dat

REM Make sure the DUT is connected over adb, then read its serial number.
adb wait-for-device
TIMEOUT 1

SET "DUT_SN="
FOR /F "usebackq delims=" %%S IN (`adb get-serialno 2^>nul`) DO SET "DUT_SN=%%S"

REM Retry if no valid serial was returned.
IF NOT DEFINED DUT_SN GOTO GetDutSN
IF /I "%DUT_SN%"=="unknown" GOTO GetDutSN

REM Ensure the serial number is exactly 12 characters.
IF NOT "%DUT_SN:~12%"=="" GOTO GetDutSN
IF "%DUT_SN:~11,1%"=="" GOTO GetDutSN

ECHO %DUT_SN%>SN.dat


IF %ERRORLEVEL% EQU 0 GOTO SetVar
GOTO GetDutSN

GOTO SetVar

:setvar
REM cd DiagPGM
REM Screen-diag.exe -nl -enter /spt "plug1.png"
REM cd..
IF EXIST OP.dat SET /p OP=<OP.dat
IF EXIST SN.dat SET /p SN=<SN.dat
COPY OP.dat DiagPGM\OP.dat
COPY SN.dat DiagPGM\SN.dat

:netuse
IF EXIST %on_Drive% GOTO timesync
net use /delete %on_Drive%
net use %on_Drive% \\%SFIS_IP%\%PROJECT% #*c1234 /user:testuser /persistent:yes


:timesync
DiagPGM\ping-auto.exe /C %SFIS_IP%
IF %ERRORLEVEL% EQU 0 GOTO sync
DiagPGM\Screen-diag.exe -nl -enter /SS 55 "SFIS Connection Error<br> <br>PING SFIS IP:%SFIS_IP% FAILED<br>SFIS connection failed. Please check the network and retry!" 0xFFFFFF -bg 0x882222
GOTO InteruptErr


:sync
tzutil /s "China Standard Time"
net time \\%SFIS_IP% /SET /y
IF %ERRORLEVEL% NEQ 0 DiagPGM\Screen-diag.exe -nl -enter /SS 55 "Time Sync Error<br> <br>Please check the network connection or time sync setting.<br> <br>Press [Enter] to retry time sync..." 0xFFFFFF -bg 0x882222 & GOTO netuse


:GetDeviceID
call DeviceID_chk.bat
IF %ERRORLEVEL% NEQ 0 goto START
IF "%deviceID%" EQU "" set /p deviceID=<deviceID.ini

:chkroute
IF "%MODE%" EQU "D" goto TID_Catch
DiagPGM\KINGSFIS-Diags.exe -d %deviceID% -op %OP% -SN %SN% /c
IF %ERRORLEVEL% EQU 0 GOTO TID_Catch
IF %ERRORLEVEL% neq 0 GOTO CRfail


:CRfail
REM Check Route Fail
DiagPGM\Screen-diag.exe -nl -enter /SS 55 "SFIS Error - Check Route Failure !!<br>Please check DUT route status !! <br>See SFISLOG\YYYYMMDD.log for details.<br>OP: %op% <br> SN: %SN%" 0xFFFFFF -bg 0x882222
GOTO InteruptErr


REM ============= start disable function for current stage =============
REM IF "%MODE%"=="D" GOTO Non_TID
:TID_Catch
echo Get TIDs...
DiagPGM\KINGSFIS-Diags.exe -d %deviceID% /GTID -SN %SN% -op %op% -f tid.dat
IF %ERRORLEVEL% EQU 255 GOTO Non_TID
IF %ERRORLEVEL% EQU 254 GOTO GTfail
IF NOT EXIST tid.dat GOTO GTfail
IF %ERRORLEVEL% EQU 0 SET /p tid=<tid.dat
GOTO getconfig

:GTfail
REM Get TID Fail
DiagPGM\Screen-diag.exe -nl -enter /SS 55 "SFIS Error - Get TID Failure !!<br>Please check the SFIS system !! <br>See SFISLOG\YYYYMMDD.log for details.<br>OP: %OP% <br> SN: %SN%" 0xFFFFFF -bg 0x882222
goto TID_Catch

:Non_TID
SET tid=
echo.>tid.dat

:Getver
goto getconfig
IF "%MODE%" EQU "D" goto getconfig
DiagPGM\KINGSFIS-Diags.exe -d %deviceID% -op %op% -SN %SN% /GKVER -f KoreVer.log
IF %ERRORLEVEL% EQU 0 GOTO Ver
echo Get TS Ver Error
DiagPGM\Screen-diag.exe -nl -enter /ss 120 "Get TS Ver Error" 0xFFFFFF -bg 0xFF7F25
GOTO InteruptErr

:Ver
IF NOT EXIST KoreVer.log GOTO Getver
DiagPGM\PT-diags.exe /gstr KoreVer.log -start_comma 0 -end_comma 1 >%TYPE%KoreVer.log
SET /p FOLDER=<%TYPE%KoreVer.log
REM ============= end disable function for current stage =============

:getconfig
IF "%SFISCONN%" EQU "True" Call config.bat 1 online %FOLDER%
IF "%SFISCONN%" NEQ "True" Call config.bat 1 offline %FOLDER%
IF "%SFISCONN%" NEQ "True" GOTO NoSFISTid
GOTO clean
:NoSFISTid
rem DiagPGM\Screen-diag.exe -nl -enter /ss 35 "Reminder<br> <br> SFISCONN Setting is not True<br>SFISCONN must be set to True<br> <br> TicketID will show [Debug] <br>TicketID will display Debug<br> <br> Press [Enter] to start the test <br>Please confirm and press Enter to continue." 0xFFFFFF -bg 0xFF7F25
echo Debug>tid.dat

:clean
IF EXIST %FOLDER% GOTO enterTS
DiagPGM\Screen-diag.exe -enter /ss 50 "Please check folder "%FOLDER%" exist <br> <br>Press [Enter] to Jig Up" 0xFFFFFF -bg 0xFF0000
GOTO InteruptErr

:enterTS
rd /s /q %FOLDER%\TypeCTester\log_csv\
rd /s /q %FOLDER%\TypeCTester\log\
cd %~dp0
cd %FOLDER%
rd /s /q Tools\DeviceBridge\MISClog

rmdir /s /q Tools\Temp
rd /s /q Tools\MISClog

if not exist Tools\Temp mkdir Tools\Temp

del online.flg
IF "%DebugXML%" neq "True" echo flg > online.flg
IF "%DebugXML%" equ "True" echo debug>debug.flg
IF EXIST %CSV_NAME% DEL %CSV_NAME%
rem IF EXIST %CSV_Steps% DEL %CSV_Steps%
IF EXIST .chopper RMDIR /S /Q .chopper
IF EXIST *.log DEL *.log
IF EXIST *.wav DEL *.wav
IF EXIST *.dat DEL *.dat
IF EXIST deviceID.ini DEL deviceID.ini
IF EXIST err_string.* DEL err_string.*
move ..\*.dat .
copy op.dat ..
copy ..\Config.ini .
copy ..\deviceID.ini .

:test
set /p SN=<SN.dat

echo %SN%>SN.DAT
cd %~dp0%FOLDER%
Chopper-diag.exe -NoHotKey -LD TcsTestSuiteDuration %PROJECT% -c -si -CGV -opf op.dat -SNF SN.dat -sip -TSRID -lock -RL -f %CFG_NAME% -as -ae -SNP "^[0-9,A-Z]{%SN_LEN%}$" -tidf tid.dat -lf ..\DiagPGM\tidlog.xml /r
IF %ERRORLEVEL% EQU 0 GOTO TestPass
IF %ERRORLEVEL% EQU 255 GOTO TestFail
IF %ERRORLEVEL% NEQ 0 pause
IF %ERRORLEVEL% EQU 250 GOTO InteruptErr
IF %ERRORLEVEL% EQU 251 GOTO InteruptErr
IF %ERRORLEVEL% EQU 252 GOTO InteruptErr
IF %ERRORLEVEL% EQU 253 GOTO InteruptErr
IF %ERRORLEVEL% EQU 254 GOTO InteruptErr

:InteruptErr
ECHO Interupt Error
REM Pause
GOTO START

:TestFail
find /i "%PROJECT%,80" %CSV_NAME%
IF %ERRORLEVEL% equ 0 goto ShowFail
find /i "%PROJECT%,8F" %CSV_NAME%
IF %ERRORLEVEL% equ 0 goto ShowFail
find /i "%PROJECT%,C" %CSV_NAME%
IF %ERRORLEVEL% equ 0 goto ShowFail
find /i "%PROJECT%,N" %CSV_NAME%
IF %ERRORLEVEL% equ 0 goto ShowFail
find /i "%PROJECT%,M" %CSV_NAME%
IF %ERRORLEVEL% equ 0 goto ShowFail
cls
call Screen-diag.exe -enter /ss 70 "unexpected exit or unknow error code happens." 0xFFFFFF -bg 0xBB2222
goto START

:ShowFail
SET Result=FAIL

cd %~dp0%FOLDER%
IF "%Result%" EQU "FAIL" Tools\UILogResult-auto.exe -log %CSV_NAME% /F
GOTO jigup

:TestPass
cd %~dp0
cd %FOLDER%
SET Result=PASS

:jigup
SET /p TSRID=<TSRID.dat
cd %~dp0%FOLDER%

:CHKTimeSync
IF "%MODE%" EQU "D" Tools\CSV-diag.exe /debug %CSV_NAME% & GOTO Backup
IF "%SFISCONN%" NEQ "True" goto DateCHK
tzutil /s "China Standard Time"
net time \\%SFIS_IP% /SET /y
IF %ERRORLEVEL% NEQ 0 Tools\Screen-diag.exe -nl -enter /SS 55 "Time Sync Error<br> <br>Please check the network connection or time sync setting.<br> <br>Press [Enter] to retry time sync..." 0xFFFFFF -bg 0x882222 & GOTO CHKTimeSync

:DateCHK
Tools\DateChk-auto.exe /FILE %CSV_NAME%
IF %ERRORLEVEL% NEQ 0 GOTO CHKFAIL
goto Backup

:CHKFAIL
echo %date%_%time% ***(%SN%_%TSRID%)-%CSV_NAME% Time Sync Error,*** >> C:\MFGlog\%TYPE%log\event\_DateChkerror.log
type DateChk.log >> C:\MFGlog\%TYPE%log\event\_DateChkerror.log
Tools\Screen-diag.exe -nl -enter /SS 40 "Log Time Error!!<br> <br> Log time is out of sync for SN:%SN%<br>This log will not upload or back up.<br> Please check time sync and retest." 0xFFFFFF -bg 0x882222
GOTO InteruptErr

:Backup
LogTransfer-auto.exe -nl /de
call setdate.bat
SET Dest=C:\MFGlog\%TYPE%log\Online
REM SET Dest2=C:\MFGlog\%TYPE%log\Online\SequencerLog\%Result%
SET MISC=C:\MISClog\%PROJECT%\%BUILD%\Online\%datepath%\%Result%
REM SET TestItem=SmokeTest
SET /p TSRID=<TSRID.dat
IF "%MODE%" EQU "D" SET Dest=C:\MFGlog\%TYPE%log\Debug
REM IF "%MODE%" EQU "D" SET Dest2=C:\MFGlog\%TYPE%log\Debug\SequencerLog\%Result%
IF "%MODE%" EQU "D" SET MISC=C:\MISClog\%PROJECT%\%BUILD%\Debug\%datepath%\%Result%

COPY /y /v %CSV_NAME% .\tools\Temp\

cd tools
del .\MISCLog.zip

rename temp MISCLog
7z\7za.exe a -tzip .\MISCLog.zip .\MISCLog
IF NOT EXIST %MISC% MKDIR %MISC%
copy /y .\MISCLog.zip %MISC%\%SN%_%TSRID%.zip


REM TASKKILL /F /IM DB-diag.exe /T
cd..
Tools\LogTransfer-auto.exe -nl -d %Dest% -F %Result% /L %CSV_NAME%
REM COPY %CSV_NAME% %Dest2%\%sn%_%TSRID%.csv
IF "%MODE%" EQU "D" GOTO END
GOTO N_UP

:N_UP
cd %~dp0%FOLDER%

:DUT1_UP
IF %Result% EQU FAIL goto DUT1_UP_fail
:DUT1_UP_pass
Tools\LogTransfer-auto.exe -nl -U connection.ok -D %on_Drive%\Log\%TYPE%\ -tester -F PASS /L %CSV_NAME%
IF %ERRORLEVEL% NEQ 0 GOTO ReConnect
goto SFIS_UP
:DUT1_UP_fail
Tools\LogTransfer-auto.exe -nl -U connection.ok -D %on_Drive%\Log\%TYPE%\ -tester -F FAIL /L %CSV_NAME%
IF %ERRORLEVEL% NEQ 0 GOTO ReConnect
goto SFIS_UP

:ReConnect
IF "%Connect%" EQU "True" GOTO LAN_fail
net use /delete %on_Drive%
net use %on_Drive% \\%SFIS_IP%\%PROJECT% #*c1234 /user:testuser /persistent:yes
SET Connect=True
REM GOTO %Result%
GOTO N_UP

:LAN_fail
ECHO %date%_%time%_%SN%_%TSRID% Upload Online Log Failed Error  >>C:\MFGlog\%TYPE%log\event\_UploadError.log

GOTO SFIS_UP

:SFIS_UP
SET SFISerror=0

:SFIS
IF "%Result%" NEQ "PASS" GOTO SFIS1
Tools\PT-diags.exe /CLS %CSV_NAME% > csvline.log
Tools\PT-diags.exe /GV csvline.log "Total Lines in File = " 36 36
if %errorlevel% neq 0 goto LOGfail

:SFIS1
Tools\KINGSFIS-Diags.exe -d %deviceID% -krown /up -tid -sfec -log %CSV_NAME%
IF %ERRORLEVEL% NEQ 0 GOTO SFIS_fail
GOTO END

:SFIS_FAIL
SET /a SFISerror=%SFISerror% + 1
echo SFIS Upload Fail
Tools\Screen-diag.exe -nl -enter /ss 70 "SFIS Upload FAIL(%SFISerror%)! <br> <br>Please Check SFIS!<br> <br>Press [Enter] to Retry"  0xFFFFFF -bg 0xBB2222
GOTO SFIS

:LOGfail
Tools\Screen-diag.exe -nl -enter /SS 40 "%CSV_NAME% Log line check fail, please check the log line!!" 0xFFFFFF -bg 0x882222

:END
IF "%Result%" NEQ "PASS" GOTO Record
IF EXIST TSRID.dat DEL TSRID.dat
START Tools\Screen-diag.exe -nl -enter /ss 200 "PASS"  0xFFFFFF -bg 0x008800
Chopper-diag.exe /delay 500 2>nul
taskkill /IM Screen-diag.exe

:Record
IF "%MODE%" EQU "D" GOTO Record1
cd %~dp0
if exist %CSV_NAME% del %CSV_NAME%
copy %FOLDER%\%CSV_NAME% %CSV_NAME%
REM IF "%Result%" EQU "FAIL" Record-diag.exe /FAIL
REM IF "%Result%" EQU "PASS" Record-diag.exe /PASS

:Record1
cd %~dp0%FOLDER%
cd %~dp0
IF "%MODE%" EQU "D" GOTO END_TIP


:chk2Aroute
IF "%Result%" EQU "PASS" GOTO END_TIP
Start DiagPGM\Screen-diag.exe -enter /SS 55 "Checking SN %SN% SFIS 2A status<br>Please wait... <br> <br>Checking 2A Status from SFIS<br>Please wait a moment..." 0xFFFFFF -bg 0x223366
DiagPGM\KINGSFIS-Diags.exe -d %deviceID% -op %OP% -SN %SN% /c
IF %ERRORLEVEL% EQU 0 DiagPGM\Screen-diag.exe -enter /SS 40 "SN (2A) not allowed!!<br> <br>Please change another tester to do SN (2A) test!!<br><br>Press [ENTER] to continue..." 0xFFFFFF -bg 0x773399
taskkill /IM Screen-diag.exe
GOTO START


:END_TIP
DiagPGM\Screen-diag.exe -nl -enter /SS 55 "<br>Testing complete.<br> <br>Release the WBAT PWR button and verify it is restored.<br> <br>Prepare the next test item.<br> <br>Replace the jig main power switch.<br> <br>Press [ENTER] to exit..." 0xFFFFFF -bg 0x0000FF
GOTO START
