@ECHO ON
cd %~dp0
setlocal EnableDelayedExpansion
rem grpcui.exe -insecure 192.168.1.51:16138

:Start
SET DUT_IP=192.168.1.51
SET ServicePorts=16138
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
if /I "%1"=="GetCurrent" goto Get_Battery_Current
if /I "%1"=="GetCC" goto Get_Battery_CycleCount
if /I "%1"=="GetHVT" goto Get_Battery_HVT
if /I "%1"=="GetRsoc" goto Get_Battery_rsoc
if /I "%1"=="GetInfo" goto Get_Battery_Info
if /I "%1"=="GetBatTemp" goto Get_Battery_Temp
if /I "%1"=="GetMFGDate" goto Get_MFG_Date
if /I "%1"=="SetLevel" goto Set_Battery_Level
if /I "%1"=="GetLevel" goto Get_Battery_Level
if /I "%1"=="GetSkinTemp" goto Get_Skin_Temp
if /I "%1"=="FanToggle" goto Fan_Toggle
if /I "%1"=="GetFanSpeed" goto Get_Fan_Speed
if /I "%1"=="SetFanSpeed" goto Set_Fan_Speed
if /I "%1"=="SetFanPWM" goto Set_Fan_PWM
if /I "%1"=="" goto NoParameter
goto NoParameter

:Get_Battery_Current
	set TestItem=%TestItems_Count%_Get_Battery_Current
	set BFLogFile=GetBatteryCurrent
	set LogFile=GetBatteryCurrent.txt
	
	if exist %LogFile% del /q %LogFile%
	rem %2 should be MainBattery or others....
	if "%2"=="" (
		echo parameter should be MainBattery or others....
		exit /b 255
	) else (
		set LogFile=Get%2Current.txt
		grpcurl.exe -emit-defaults -insecure -d "{\"batteryName\": \"%2\"}" %DUT_IP%:%ServicePorts% BatteryService/GetBatteryCurrent > !LogFile!
	)
	findstr /c:"\"battery_current\": 0" !LogFile! 
	if !errorlevel! equ 0 (
		goto fail
	) else (
		goto pass
	)
	REM findstr /c:"\"battery_current\": %3" !LogFile! 
	REM if !errorlevel! equ 0 (
		REM goto pass
	REM ) else (
		REM goto fail
	REM )

:Get_Battery_CycleCount
	set TestItem=%TestItems_Count%_Get_Battery_CycleCount
	set BFLogFile=GetBatteryCycleCount
	set LogFile=GetBatteryCycleCount.txt
	
	if exist %LogFile% del /q %LogFile%
	rem %2 should be MainBattery or others....
	if "%2"=="" (
		echo parameter should be MainBattery or others....
		exit /b 255
	) else (
		set LogFile=Get%2CycleCount.txt
		grpcurl.exe -emit-defaults -insecure -d "{\"batteryName\": \"%2\"}" %DUT_IP%:%ServicePorts% BatteryService/GetBatteryCycleCount > !LogFile!
	)
	findstr /c:"\"cycle_count\": %3" !LogFile! 
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)

:Get_Battery_HVT
	set TestItem=%TestItems_Count%_Get_Battery_HVT
	set BFLogFile=GetBatteryHVT
	set LogFile=GetBatteryHVT.txt
	
	if exist %LogFile% del /q %LogFile%
	rem %2 should be MainBattery or others....
	if "%2"=="" (
		echo parameter should be MainBattery or others....
		exit /b 255
	) else (
		set LogFile=Get%2HVT.txt
		grpcurl.exe -emit-defaults -insecure -d "{\"batteryName\": \"%2\"}" %DUT_IP%:%ServicePorts% BatteryService/GetBatteryHVT > !LogFile!
	)
	findstr /c:"\"hvt\": %3" !LogFile! 
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)

:Get_Battery_Temp
	set TestItem=%TestItems_Count%_Get_Battery_Temp
	set BFLogFile=GetBatteryTemperature
	set LogFile=GetBatteryTemperature.txt
	
	if exist %LogFile% del /q %LogFile%
	rem %2 should be MainBattery or others....
	if "%2"=="" (
		echo parameter should be MainBattery or others....
		exit /b 255
	) else (
		set LogFile=Get%2Temperature.txt
		grpcurl.exe -insecure -d "{\"batteryName\": \"%2\"}" %DUT_IP%:%ServicePorts% BatteryService/GetBatteryTemperature > !LogFile!
	)
	findstr /c:"\"temperature\": %3" !LogFile! 
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:Get_Battery_rsoc
	set TestItem=%TestItems_Count%_Get_Battery_RSOC
	set BFLogFile=GetBatteryLevel
	set LogFile=GetBatteryLevel.txt
	
	if exist %LogFile% del /q %LogFile%
	rem %2 should be MainBattery or others....
	if "%2"=="" (
		echo parameter should be MainBattery or others....
		exit /b 255
	) else (
		set LogFile=Get%2Level.txt
		grpcurl.exe -insecure -d "{\"batteryName\": \"%2\"}" %DUT_IP%:%ServicePorts% BatteryService/GetBatteryLevel > !LogFile!
	)
	findstr /c:"\"rsoc\": %3" !LogFile! 
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)

:Set_Battery_Level
	set TestItem=%TestItems_Count%_Set_Battery_Level
	set BFLogFile=SetBatteryLevel
	set LogFile=SetBatteryLevel.txt
	
	if exist %LogFile% del /q %LogFile%
	if "%3"=="" (
		set LowLevel=65
	) else (
		set LowLevel=%3
	)
	if "%4"=="" (
		set HighLevel=65
	) else (
		set HighLevel=%4
	)
	rem %2 should be MainBattery or others....
	if "%2"=="" (
		echo parameter should be MainBattery or others....
		exit /b 255
	) else (
		set LogFile=Set%2Level.txt
		echo grpcurl.exe -insecure -d "{\"batteryName\": \"%2\",\"lowLevel\": \"%LowLevel%\",\"highLevel\": \"%HighLevel%\"}" %DUT_IP%:%ServicePorts% BatteryService/SetChargingLevel > !LogFile!
		grpcurl.exe -insecure -d "{\"batteryName\": \"%2\",\"lowLevel\": \"%LowLevel%\",\"highLevel\": \"%HighLevel%\"}" %DUT_IP%:%ServicePorts% BatteryService/SetChargingLevel >> !LogFile!
		if !errorlevel! equ 0 (
			goto pass
		) else (
			goto fail
		)		
	)

:Get_Battery_Level
	set TestItem=%TestItems_Count%_Set_Battery_Level
	set BFLogFile=SetBatteryLevel
	set LogFile=GetBatteryLevel.txt
	
	if exist %LogFile% del /q %LogFile%
	if "%3"=="" (
		set LowLevel=65
	) else (
		set LowLevel=%3
	)
	if "%4"=="" (
		set HighLevel=65
	) else (
		set HighLevel=%4
	)
	rem %2 should be MainBattery or others....
	if "%2"=="" (
		echo parameter should be MainBattery or others....
		exit /b 255
	) else (
		set LogFile=Get%2Level.txt
		grpcurl.exe -insecure -d "{\"batteryName\": \"%2\"}" %DUT_IP%:%ServicePorts% BatteryService/GetChargingLevel > !LogFile!
		if !errorlevel! equ 0 (
			findstr /c:"\"low_level\": %LowLevel%" !LogFile!
			if !errorlevel! equ 0 (
				findstr /c:"\"high_level\": %HighLevel%" !LogFile!
				if !errorlevel! equ 0 (
					goto pass
				) else (
					SET RTN=255
					goto fail
				)
			) else (
				SET RTN=254
				goto fail
			)
		) else (
			goto fail
		)		
	)
	
:Get_Battery_Info
	set TestItem=%TestItems_Count%_Get_Battery_Info
	set BFLogFile=GetBatteryInfo
	set LogFile=GetBatteryInfo.txt
	
	if exist %LogFile% del /q %LogFile%
	rem %2 should be MainBattery or others....
	if "%2"=="" (
		echo parameter should be MainBattery or others....
		exit /b 255
	) else (
		set LogFile=Get%2Info.txt
		grpcurl.exe -insecure -d "{\"batteryName\": \"%2\"}" %DUT_IP%:%ServicePorts% BatteryService/GetBatteryInfo > !LogFile!
	)
	findstr /c:"\"serial_number\":" !LogFile! 
	if !errorlevel! equ 0 (
		if "%3"=="" goto pass
		if "%3"=="ChargingCheck" findstr /c:"IsCharging: True" !LogFile!
			if !errorlevel! equ 0 (
				goto pass
			) else (
				SET RTN=255
				goto fail
			)
	) else (
		goto fail
	)
	

:Get_MFG_Date
	set TestItem=%TestItems_Count%_Get_MFG_Date
	set BFLogFile=GetBatteryMFGDate
	set LogFile=GetBatteryMFGDate.txt
	
	if exist %LogFile% del /q %LogFile%
	rem %2 should be MainBattery or others....
	if "%2"=="" (
		echo parameter should be MainBattery or others....
		exit /b 255
	) else (
		set LogFile=Get%2MFGDate.txt
		grpcurl.exe -insecure -d "{\"batteryName\": \"%2\"}" %DUT_IP%:%ServicePorts% BatteryService/GetBatteryManufacturerDate > !LogFile!
	)
	findstr /c:"\"manufacture_date\": " !LogFile! 
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)

:Get_Skin_Temp
	set TestItem=%TestItems_Count%_Get_Skin_Temp
	set BFLogFile=GetSkinTemp
	set LogFile=GetSkinTemp.txt
	
	if exist %LogFile% del /q %LogFile%
	grpcurl.exe -insecure -d "{ }" %DUT_IP%:%ServicePorts% ThermalService/GetThermals > !LogFile!
	
	findstr /c:"\"samples\": " !LogFile! 

	powershell -ex bypass .\SkinTempCompare.ps1
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:Fan_Toggle
	set TestItem=%TestItems_Count%_Fan_Toggle
	set BFLogFile=FanToggle
	set LogFile=GetFanToggle.txt
	
	if exist %LogFile% del /q %LogFile%
	if exist Fan?Toggle.txt del /q Fan?Toggle.txt
	rem %2 FainId
	if "%2"=="" (
		set FanID=1
	) else (
		set FanID=%2
	)
	set LogFile=Fan%2Toggle.txt
	rem %2 on=true or false
	if "%3"=="" (
		set on=true
	) else (
		set on=%3
	)
	grpcurl.exe -emit-defaults -insecure -d "{\"fanId\": \"%FanID%\",\"on\": \"%on%\"}" %DUT_IP%:%ServicePorts% FanService/ToggleFan > !LogFile!
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:Get_Fan_Speed
	set TestItem=%TestItems_Count%_Get_Fan_Speed
	set BFLogFile=GetFanSpeed
	set LogFile=GetFanSpeed.txt
	
	if exist %LogFile% del /q %LogFile%
	rem %2 FainId
	if "%2"=="" (
		set FanID=1
	) else (
		set FanID=%2
	)
	set LogFile=GetFan%2Speed.txt
	grpcurl.exe -emit-defaults -insecure -d "{\"fanId\": \"%FanID%\"}" %DUT_IP%:%ServicePorts% FanService/GetFanSpeed > !LogFile!
	findstr /c:"\"speed\": " !LogFile! 
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:Set_Fan_Speed
	set TestItem=%TestItems_Count%_Set_Fan_Speed
	set BFLogFile=SetFanSpeed
	set LogFile=SetFanSpeed.txt
	
	if exist %LogFile% del /q %LogFile%
	rem %2 FainId
	if "%2"=="" (
		set FanID=1
		set Speed=3000
	) else (
		set FanID=%2
		set Speed=%3
	)
	set LogFile=SetFan%2Speed.txt
	grpcurl.exe -insecure -d "{\"fanId\": \"%FanID%\", \"speed\": \"%Speed%\"}" %DUT_IP%:%ServicePorts% FanService/SetFanSpeed > !LogFile!
	if !errorlevel! equ 0 (
		goto pass
	) else (
		goto fail
	)

:Set_Fan_PWM
	set TestItem=%TestItems_Count%_Set_Fan_PWM
	set BFLogFile=SetFanPWM
	set LogFile=SetFanPWM.txt
	
	if exist %LogFile% del /q %LogFile%
	rem %2 FainId
	if "%2"=="" (
		set FanID=1
		set PWM=50
	) else (
		set FanID=%2
		set PWM=%3
	)
	set LogFile=SetFan%2SPWM.txt
	grpcurl.exe -insecure -d "{\"fanId\": \"%FanID%\", \"pwmDutyCycle\": \"%PWM%\"}" %DUT_IP%:%ServicePorts% FanService/SetFanPulseWidthModulatation > !LogFile!
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
if not exist ..\Temp\MISClog\%TestItem% MKDIR ..\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Temp\MISClog\%TestItem%
..\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModulePower" -to "..\Temp" -w -e 0 -timeout 10
REM for %%D in (!BFLogFile!) do move /y C:\DeviceBridgeLogs\%SN%_%TSRID_DB%\*%%D*.* ..\Tools\Temp\MISClog\%TestItem%\
echo rtn="%rtn%"
if defined rtn (
	exit /b !rtn! 
) else (
	exit /b 255
)

:pass
echo pass
cd %~dp0
if not exist ..\Temp\MISClog\%TestItem% MKDIR ..\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Temp\MISClog\%TestItem%
..\LANRS-Diags.exe /QD -ip 192.168.1.51 -rf "C:\Data\BiFrost\Logs\BiFrostModulePower" -to "..\Temp" -w -e 0 -timeout 10
REM for %%D in (!BFLogFile!) do move /y C:\DeviceBridgeLogs\%SN%_%TSRID_DB%\*%%D*.* ..\Tools\Temp\MISClog\%TestItem%\
exit /b 0

:not_backup
if defined rtn (
	echo !rtn!
	exit /b !rtn!
) else ( 
	exit /b 255
)

:End