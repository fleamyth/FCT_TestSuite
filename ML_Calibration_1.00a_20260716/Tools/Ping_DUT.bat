@echo off
del C:\DeviceBridgeLogs /f /q
cd %~dp0..
set /p IP=<IP.dat
set tool_path=c:\DiagTool
SET MISC=C:\MISClog\Debug
IF EXIST MISClog.dat SET /p MISC=<MISClog.dat


Tools\ping-auto.exe /P 192.168.1.51 -t 150

set /a exitcode=%errorlevel%

:End
rem IF %EXITCODE% NEQ 0 echo reping>reping.dat
rem IF %EXITCODE% NEQ 0 call Tools\DHCP.bat
EXIT /B %exitcode%