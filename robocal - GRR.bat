@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "DESKTOP_DIR="
for /f "usebackq delims=" %%D in (`powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP_DIR=%%D"
if not defined DESKTOP_DIR set "DESKTOP_DIR=%USERPROFILE%\Desktop"

set "ROBOCAL_BAT=!DESKTOP_DIR!\glasses_scripts\run_robocal_single - noAudio.bat"
set "OPERATION=OP1"
set "BACKUP_ROOT=!DESKTOP_DIR!\RoboGRR"
set "MASTER_OUTPUT=!DESKTOP_DIR!\logs"

if not "%~1" == "" set "ROBOCAL_BAT=%~1"
if not "%~2" == "" set "OPERATION=%~2"
if not "%~3" == "" set "BACKUP_ROOT=%~3"
if not "%~4" == "" set "MASTER_OUTPUT=%~4"

if "%~2" == "" (
  set "OPERATION_INPUT="
  set /p "OPERATION_INPUT=Enter operation [OP1]: "
  if defined OPERATION_INPUT set "OPERATION=!OPERATION_INPUT!"
)

echo Operation: !OPERATION!

if not exist "!ROBOCAL_BAT!" (
  echo ERROR: RoboCal batch file not found: "!ROBOCAL_BAT!"
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
  exit /b 4
)

set "LOG_IDENTIFIER="
for /f "usebackq delims=" %%H in (`adb shell getprop ro.serialno 2^>nul`) do set "LOG_IDENTIFIER=%%H"
if not defined LOG_IDENTIFIER set "LOG_IDENTIFIER=!SERIAL!"

echo ADB serial:     !SERIAL!
echo Log identifier: !LOG_IDENTIFIER!

if not exist "!MASTER_OUTPUT!" (
  echo ERROR: RoboCal master output directory not found: "!MASTER_OUTPUT!"
  exit /b 5
)

set "RUN_MARKER=%TEMP%\robocal_grr_%RANDOM%_%RANDOM%.tmp"
type nul >"!RUN_MARKER!"
if errorlevel 1 (
  echo ERROR: Could not create run marker "!RUN_MARKER!".
  exit /b 6
)

echo Running RoboCal: "!ROBOCAL_BAT!"
call "!ROBOCAL_BAT!"
set "ROBOCAL_EXITCODE=!ERRORLEVEL!"

set "DESTINATION_DIR=!BACKUP_ROOT!\!SERIAL!\!OPERATION!\Robocal"
if not exist "!DESTINATION_DIR!\" mkdir "!DESTINATION_DIR!" 2>nul
if not exist "!DESTINATION_DIR!\" (
  echo ERROR: Could not create "!DESTINATION_DIR!".
  del /q "!RUN_MARKER!" 2>nul
  exit /b 7
)

set "ROBOCAL_SOURCE=!MASTER_OUTPUT!\!LOG_IDENTIFIER!"
set "COPY_COUNT=0"
set "COPY_COUNT_FILE=%TEMP%\robocal_grr_count_%RANDOM%_%RANDOM%.tmp"
powershell.exe -NoProfile -Command "$marker = (Get-Item -LiteralPath $env:RUN_MARKER).LastWriteTimeUtc; $source = $env:ROBOCAL_SOURCE; $destination = $env:DESTINATION_DIR; $count = 0; if (Test-Path -LiteralPath $source) { foreach ($file in Get-ChildItem -LiteralPath $source -Recurse -File) { if ($file.LastWriteTimeUtc -ge $marker) { $relative = $file.FullName.Substring($source.Length).TrimStart('\'); $parts = $relative -split '\\'; if ($parts.Count -ge 3 -and $parts[1] -match '^\d{8}_\d{6}$') { $relative = (@($parts[0]) + $parts[2..($parts.Count - 1)]) -join '\' }; $target = Join-Path $destination $relative; $parent = Split-Path -Parent $target; New-Item -ItemType Directory -Path $parent -Force | Out-Null; Copy-Item -LiteralPath $file.FullName -Destination $target -Force; $count++ } } }; $logSource = Join-Path $env:MASTER_OUTPUT 'robocal_output'; if (Test-Path -LiteralPath $logSource) { foreach ($file in Get-ChildItem -LiteralPath $logSource -File) { if (($file.Name -like 'log_file_*.txt' -or $file.Name -like 'log_file_*.log') -and $file.LastWriteTimeUtc -ge $marker) { Copy-Item -LiteralPath $file.FullName -Destination $destination -Force; $count++ } } }; Set-Content -LiteralPath $env:COPY_COUNT_FILE -Value $count -Encoding Ascii"
set "COPY_EXITCODE=!ERRORLEVEL!"

if not "!COPY_EXITCODE!" == "0" (
  echo ERROR: Failed to back up RoboCal data.
  del /q "!RUN_MARKER!" "!COPY_COUNT_FILE!" 2>nul
  exit /b 8
)

if exist "!COPY_COUNT_FILE!" set /p "COPY_COUNT="<"!COPY_COUNT_FILE!"

del /q "!RUN_MARKER!" "!COPY_COUNT_FILE!" 2>nul

if "!COPY_COUNT!" == "0" (
  echo ERROR: No new RoboCal data was found under "!MASTER_OUTPUT!".
  echo RoboCal exit code: !ROBOCAL_EXITCODE!
  exit /b 9
)

echo RoboCal data backed up successfully.
echo Source:      !MASTER_OUTPUT!
echo Destination: !DESTINATION_DIR!
echo Files copied: !COPY_COUNT!
echo RoboCal exit code: !ROBOCAL_EXITCODE!
exit /b !ROBOCAL_EXITCODE!
