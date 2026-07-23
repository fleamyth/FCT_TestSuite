@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PRE_PROCESS_BAT=C:\Users\TEST\Desktop\glasses_scripts\pre_post\pre_process_single - noAudio.bat"
set "OPERATION=OP1"
set "BACKUP_ROOT=C:\Users\TEST\Desktop\RoboGRR"
set "SOURCE_DIR=C:\Users\TEST\Desktop\logs\robocal_output"

if not "%~1" == "" set "PRE_PROCESS_BAT=%~1"
if not "%~2" == "" set "OPERATION=%~2"
if not "%~3" == "" set "BACKUP_ROOT=%~3"
if not "%~4" == "" set "SOURCE_DIR=%~4"

if "%~2" == "" (
  set "OPERATION_INPUT="
  set /p "OPERATION_INPUT=Enter operation [OP1]: "
  if defined OPERATION_INPUT set "OPERATION=!OPERATION_INPUT!"
)

echo Operation: !OPERATION!

if not exist "!PRE_PROCESS_BAT!" (
  echo ERROR: Pre-process batch file not found: "!PRE_PROCESS_BAT!"
  exit /b 2
)

set "ADB_DEVICES_FILE=%TEMP%\robocal_adb_devices_%RANDOM%_%RANDOM%.tmp"
call adb devices >"!ADB_DEVICES_FILE!"
if errorlevel 1 (
  echo ERROR: Failed to run adb devices.
  del /q "!ADB_DEVICES_FILE!" 2>nul
  exit /b 3
)

set "SERIAL="
set /a DEVICE_COUNT=0
for /f "usebackq skip=1 tokens=1,2" %%A in ("!ADB_DEVICES_FILE!") do (
  if "%%B" == "device" (
    set /a DEVICE_COUNT+=1
    set "SERIAL=%%A"
  )
)
del /q "!ADB_DEVICES_FILE!" 2>nul

if not "!DEVICE_COUNT!" == "1" (
  echo ERROR: Expected exactly one connected ADB device, found !DEVICE_COUNT!.
  echo Check adb devices and ensure the device state is device.
  exit /b 4
)

echo ADB serial: !SERIAL!

set "SOURCE_LOG_BEFORE="
if exist "!SOURCE_DIR!" (
  for /f "delims=" %%F in ('dir /b /a-d /o-d "!SOURCE_DIR!\log_file_*.log" 2^>nul') do if not defined SOURCE_LOG_BEFORE set "SOURCE_LOG_BEFORE=%%F"
)

echo Running pre-process: "!PRE_PROCESS_BAT!"
call "!PRE_PROCESS_BAT!"
set "PRE_PROCESS_EXITCODE=!ERRORLEVEL!"

set "SOURCE_LOG="
if exist "!SOURCE_DIR!" (
  for /f "delims=" %%F in ('dir /b /a-d /o-d "!SOURCE_DIR!\log_file_*.log" 2^>nul') do if not defined SOURCE_LOG set "SOURCE_LOG=%%F"
)

if /i "!SOURCE_LOG!" == "!SOURCE_LOG_BEFORE!" set "SOURCE_LOG="

if not defined SOURCE_LOG (
  echo ERROR: No new pre-process log was found at "!SOURCE_DIR!".
  echo Pre-process exit code: !PRE_PROCESS_EXITCODE!
  exit /b 6
)

set "DESTINATION_DIR=!BACKUP_ROOT!\!SERIAL!\!OPERATION!\Pre"
set "LOG_NAME=!SOURCE_LOG!"
set "SOURCE_LOG=!SOURCE_DIR!\!SOURCE_LOG!"
set "DESTINATION_LOG=!DESTINATION_DIR!\!LOG_NAME!"

if exist "!DESTINATION_LOG!" (
  echo ERROR: Destination already exists: "!DESTINATION_LOG!"
  exit /b 7
)

if not exist "!DESTINATION_DIR!\" mkdir "!DESTINATION_DIR!" 2>nul
if not exist "!DESTINATION_DIR!\" (
  echo ERROR: Could not create "!DESTINATION_DIR!".
  exit /b 8
)

copy /b /y "!SOURCE_LOG!" "!DESTINATION_LOG!" >nul
if errorlevel 1 (
  echo ERROR: Failed to copy "!SOURCE_LOG!".
  exit /b 9
)

echo Pre-process log backed up successfully.
echo Source:      !SOURCE_LOG!
echo Destination: !DESTINATION_LOG!
echo Pre-process exit code: !PRE_PROCESS_EXITCODE!
exit /b !PRE_PROCESS_EXITCODE!

:usage
echo Usage: %~nx0 [PRE_PROCESS_BAT] [OP] [BACKUP_ROOT] [SOURCE_DIR]
echo.
echo Run without arguments to select OP interactively.
echo PRE_PROCESS_BAT optionally overrides the configured pre-process batch file.
echo SERIAL is detected automatically from adb devices. Exactly one device
echo must be connected with the state device.
echo If BACKUP_ROOT is omitted, Desktop\RoboGRR is used.
echo If SOURCE_DIR is omitted, this TEST user directory is used:
echo C:\Users\TEST\Desktop\logs\robocal_output
echo.
echo Example:
echo %~nx0
echo %~nx0 "C:\TestTools\run_pre_process.bat" OP1
exit /b 1
