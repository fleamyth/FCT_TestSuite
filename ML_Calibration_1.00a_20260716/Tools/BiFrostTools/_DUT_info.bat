@ECHO ON
cd %~dp0
setlocal EnableDelayedExpansion

:Start
if EXIST ..\sn.dat IF "%SN%" EQU "" SET /p SN=<..\sn.dat
if EXIST ..\TSRID.dat IF "%TSRID%" EQU "" SET /p TSRID=<..\TSRID.dat
if EXIST ..\TSRID_DB.dat IF "%TSRID_DB%" EQU "" SET /p TSRID_DB=<..\TSRID_DB.dat
if EXIST ..\TestItems_Count.flg SET /p TestItems_Count=<..\TestItems_Count.flg  & SET TestItems_Count=!TestItems_Count: =!
if defined TSRID_DB set TSRID_DB=%TSRID_DB: =%
SET SkipCountAdd=False
SET RTN=
if /I "%1"=="MODE" goto UEFI_Mode
if /I "%1"=="Unlock" goto UEFI_Unlock
if /I "%1"=="MTEOS" goto MTEOS
if /I "%1"=="DBVer" goto DB_Ver
if /I "%1"=="UEFI" goto UEFI_Ver
if /I "%1"=="SAM" goto SAM_Ver
if /I "%1"=="ME" goto ME_Ver
if /I "%1"=="ME_RPMC" goto ME_RPMC_Check
rem if /I "%1"=="TPM" goto TPM_Ver
if /I "%1"=="PCBA" goto PCBA_SN
if /I "%1"=="SetPCBA_SN" goto Set_PCBA_SN
if /I "%1"=="SetTime" goto SetSystemTimeUTC
if /I "%1"=="YB" goto Yellow_bang
if /I "%1"=="SetPTMAC" goto W_PTlan_MAC
if /I "%1"=="PTMAC" goto R_PTlan_MAC
if /I "%1"=="WMAC" goto Wlan_MAC
if /I "%1"=="BTMAC" goto BT_MAC
if /I "%1"=="MAC" goto NIC_MAC
if /I "%1"=="CPU" goto CPU
if /I "%1"=="SSD" goto SSD
if /I "%1"=="MEM" goto Memory
if /I "%1"=="PCI" goto PCI_Info
if /I "%1"=="Temp" goto Temperature
if /I "%1"=="SL" goto SurfLink_RID
if /I "%1"=="POST_T" goto POST_Time
if /I "%1"=="BoardID" goto Get_BoardID
if /I "%1"=="NFCChipID" goto Get_NFCChipID
if /I "%1"=="NFC_AntSelfTest1" goto NFC_AntSelfTest1
if /I "%1"=="NFC_AntSelfTest2" goto NFC_AntSelfTest2
if /I "%1"=="Reboot" goto RebootTest
if /I "%1"=="Shutdown" goto Shutdown
if /I "%1"=="DiskSmart" goto DiskSmartTest
if /I "%1"=="" goto NoParameter
goto NoParameter

:UEFI_Mode
	del ..\Tools\UnlockUEFI.fpc
	set TestItem=%TestItems_Count%_UEFI_Mode_Check_BeforeUnlock
	if "%3"=="RTNcheck" set TestItem=%TestItems_Count%_UEFI_Mode_Check_AfterUnlock
	set DBLogFile=GetUefiMode
	set LogFile=GetUefiMode.txt
	del /q %LogFile%
	DevInfo-diag.exe -sn %SN% /cmd GetUefiMode -cmp %2 > %LogFile%
	if %errorlevel% equ 0 (
		goto pass
	) else (
		if "%3"=="RTNcheck" goto showUEFI_Mode_Fail
		echo Need to Unlock UEFI to MFG Mode > ..\Tools\UnlockUEFI.fpc
		goto pass		
	)

:showUEFI_Mode_Fail
..\Tools\Screen-diag.exe -nl -enter /SS 55 "Check UEFI as manufacturing mode failed.<br>請通知FA取SSD分析event log異常!!" 0xFFFFFF -bg 0x882222
taskkill /IM Screen-diag.exe
goto fail	

:UEFI_Unlock
	if "%2"=="UefiUnlockProxyService" goto UEFI_Unlock2
	set TestItem=%TestItems_Count%_UEFI_Unlock
	set DBLogFile=GetUefiMode GetUefiMfgUnlockBlob TriggerUefiMfgUnlock
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
	..\Tools\Screen-diag.exe -nl -enter /SS 55 "保留機板和SSD勿動!!<br>並通知FA確認收集Event log" 0xFFFFFF -bg 0x882222
    taskkill /IM Screen-diag.exe
	goto fail

:UEFI_Unlock2
	set TestItem=%TestItems_Count%_UEFI_Unlock
	set DBLogFile=RunExecutable
	set LogFile=DevMfgUnlock_trace.txt 
	DevInfo-diag.exe /cmd "RunExecutable C:\Tools\MfgUnlock\Gaviota\DevMfgUnlock.cmd" -para " " > %LogFile%
	find "Successfully unlocked TestSigned Gaviota Manufacturing Mode" %LogFile%
	if %errorlevel% equ 0 goto pass
	..\Tools\Screen-diag.exe -nl -enter /SS 55 "保留機板和SSD勿動!!<br>並通知FA確認收集Event log" 0xFFFFFF -bg 0x882222
    taskkill /IM Screen-diag.exe
	goto fail
	
:MTEOS
	set TestItem=%TestItems_Count%_MTEOS_Version_Check
	set DBLogFile=GetOsVersion
	set LogFile=GetOsVersion.txt
	
	del /q %LogFile%
	DevInfo-diag.exe -sn %SN% /cmd GetOSVersion -cmp %2 > %LogFile%
	if %errorlevel% equ 0 goto pass
	goto fail


:DB_Ver
	set TestItem=%TestItems_Count%_DBRuntime_Version
	set DBLogFile=GetRuntimeVersion
	set LogFile=GetRuntimeVersion.txt
	DevInfo-diag.exe -sn %SN% /cmd GetRuntimeVersion -cmp %2 %2 > %LogFile%
	if %errorlevel% equ 0 (
		goto pass
	) else (
		goto fail
	)

:UEFI_Ver
	set TestItem=%TestItems_Count%_UEFI_Version_Check
	set DBLogFile=GetUefiVersion
	set LogFile=GetUefiVersion.txt
	
	del /q GetUefiVersion.txt
	DevInfo-diag.exe -sn %SN% /cmd GetUefiVersion > %LogFile%
	findstr /c:"Response" %LogFile% > tmp.log
	rem Check if DeviceBridge Log Error
	if %errorlevel% neq 0 goto fail
	for /F "tokens=1,2* delims==" %%i in (tmp.log) do (
		set Reading=%%j
	)
	if defined Reading set Reading=%Reading: =%
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

:SAM_Ver
	set TestItem=%TestItems_Count%_SAM_Version_Check
	set DBLogFile=GetSamFwVersion
	set LogFile=GetSamFwVersion.txt
	DevInfo-diag.exe -sn %SN% /cmd GetSamFWVersion  > %LogFile%
	findstr /c:"Response" %LogFile% > tmp.log
	rem Check if DeviceBridge Log Error
	if %errorlevel% neq 0 goto fail
	for /F "tokens=1,2* delims==" %%i in (tmp.log) do (
		set Reading=%%j
	)
	if defined Reading set Reading=%Reading: =%
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

:ME_Ver
	set TestItem=%TestItems_Count%_ME_Version
	set DBLogFile=RunExecutable
	set LogFile=MEInfo.txt
	
	del /q %LogFile%
	del /q ME_Version.txt
	DevInfo-diag.exe -sn %SN% /cmd "RunExecutable C:\Tools\Intel\MEInfo\MEInfoWin64.exe" -para "-verbose" > %LogFile%
	findstr /C:"    FW Version" %LogFile% > tmp.txt
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
		set DBLogFile=RunExecutable
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
	set DBLogFile=GetPcbaSerialNumber
	set LogFile=GetPcbaSerialNumber.txt
	DevInfo-diag.exe -sn %SN% /cmd GetPcbaSerialNumber > %LogFile%
	findstr /c:"Response" %LogFile% > tmp.log
	FOR /F "tokens=1,2* delims==" %%i in (tmp.log) do (
		set Reading=%%j
	)
	if defined Reading set Reading=%Reading: =%
	echo SerialNumber > ..\Tools\Temp\sn.txt
	echo %Reading% >> ..\Tools\Temp\sn.txt
	goto pass


:Set_PCBA_SN
	set TestItem=%TestItems_Count%_Set_PCBA_SerialNumber
	set DBLogFile=SetPcbaSerialNumber
	set LogFile=SetPcbaSerialNumber.txt
	del %LogFile%
	if not exist ..\SN.dat goto fail
	set /p SN=< ..\SN.dat
	DevInfo-diag.exe /cmd "SetPcbaSerialNumber %SN%" > %LogFile%
	findstr /i /c:"Response" %LogFile%> tmp.txt
	find /i "SetPcbaSerialNumber=%SN%" tmp.txt
	if %errorlevel% neq 0 goto fail
	goto pass

:Yellow_bang
	set TestItem=%TestItems_Count%_Device_Yellow_Bang_Check
	set DBLogFile=DevNodeInfo
	set LogFile=Yellow_bang.txt 
	set RTN=0
	if exist Yellow_bang.txt del Yellow_bang.txt 
	rem below command will create "GetHardwareComponents.txt"
	DevInfo-diag.exe -SN %SN% /cmd l
	timeout 1
	FOR /F "tokens=1,2,3,4,5,6* delims=," %%i in (GetHardwareComponents.txt) do (
		set Reading=%%k
		if "!Reading!" NEQ " Device Status: 0" (
			echo %%m >>Yellow_bang.txt 
		set RTN=255
		)
	)
	if %RTN% equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:SetSystemTimeUTC
	set TestItem=%TestItems_Count%_SetSystemTimeUTC
	set LogFile=SetSystemTimeUTC.txt
	DevInfo-diag -SN %SN% /cmd setsystemtimeutc -cmp Done > %LogFile%
	if %errorlevel% equ 0 (
		goto pass
	) else (
		goto fail
	)


:R_PTlan_MAC
	set TestItem=%TestItems_Count%_Get_PassThroughLan_MacAddress
	set DBLogFile=ReadPassThroughMacAddress
	set LogFile=ReadPassThroughMacAddress.txt
	DevInfo-diag.exe -SN %SN% /cmd ReadPassThroughMacAddress > %LogFile%
	findstr /c:"index=" %LogFile% > tmp.log
	if errorlevel 1 echo NA >..\Tools\Temp\__Mac_PTLAN.txt & goto fail
	FOR /F "tokens=1,2* delims==" %%i in (tmp.log) do (
		set Reading=%%j
	)
	if defined Reading set Reading=%Reading: =%
	if defined Reading set MacAddress=%Reading::=%
	echo %MacAddress% > ..\Tools\Temp\__Mac_PTLAN.txt
	echo %MacAddress% > ..\Temp\__Mac_PTLAN.txt
	find /i "000000000000" ..\Tools\Temp\__Mac_PTLAN.txt
	if %errorlevel% neq 1 goto fail
	find /i "FFFFFFFFFFFF" ..\Tools\Temp\__Mac_PTLAN.txt
	if %errorlevel% neq 1 goto fail
	find /i "888888888888" ..\Tools\Temp\__Mac_PTLAN.txt
	if %errorlevel% neq 1 goto fail
	goto pass

:W_PTlan_MAC
	set TestItem=%TestItems_Count%_Set_PassThroughLan_MacAddress
	set DBLogFile=WritePassThroughMacAddress
	set LogFile=WritePassThroughMacAddress.txt
	if not exist ..\..\PTLan_MacAddress.txt goto fail
	set /p PT_Mac=< ..\..\PTLan_MacAddress.txt
	DevInfo-diag.exe -SN %SN% /cmd "WritePassThroughMacAddress %PT_Mac%" -cmp Done > %LogFile%
	if %errorlevel% neq 0 goto fail
	goto pass

:Wlan_MAC
	set TestItem=%TestItems_Count%_Get_WLan_MacAddress
	set DBLogFile=GetWLanMacAddress
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
	set DBLogFile=GetBtMacAddress
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
	set DBLogFile=GetCpuInfo
	set LogFile=GetCpuInfo.txt
	
	del /q %LogFile%
	del /q cpu_check.txt
	del /q cpu_read.txt
	DevInfo-diag.exe -sn %SN% /cmd GetCpuInfo > %LogFile%
	PT-diags.exe -nc -nl /find %LogFile% "CPUINFO NAME" > cpu_read.txt
	for /f "tokens=1,2,3 delims==" %%i in (cpu_read.txt) do (
		set Reading=%%k
	)
	echo %Reading%>cpu_read.txt
	rem if defined Reading set Reading=%Reading: 13th=13th%
	rem if defined Reading set Reading=%Reading: GENU=GENU%
	echo %2 %3 > cpu_check.txt
	find /i "%Reading%" cpu_check.txt
	if !errorlevel! equ 0 (
		rem goto CPU_Freq
		goto pass
	) else (
		goto fail
	)
rem :CPU_Freq
rem 	findstr /c:"MaximumFrequencyInMhz" %LogFile%>tmp.txt
rem 	findstr /c:"%3" tmp.txt
rem 	if %errorlevel% equ 0 goto pass
rem 	goto fail	
	
:SSD
	set TestItem=%TestItems_Count%_GetHardDiskInformation
	set DBLogFile=GetHardDiskInfos
	set LogFile=GetHardDiskInfos.txt
	set RTN=0
	if exist HDD_Vendor.txt del HDD_Vendor.txt
	if exist HDD_FW.txt del HDD_FW.txt
	DevInfo-diag.exe -SN %SN% /cmd GetHardDiskInfos > %LogFile%
	PT-diags.exe -nc -nl /find %LogFile% "ModelName=" > HDD_Vendor.txt
	FOR /F "tokens=1,2* delims==" %%i in (HDD_Vendor.txt) do (
		set Reading=%%j
	)
	echo %2 > HDD_List.txt
	if defined Reading set Reading=%Reading: MODELNAME==%
	find /i "%Reading%" HDD_List.txt
	if !errorlevel! neq 0 (
		set RTN=255
	)

	PT-diags.exe -nc -nl /find %LogFile% "FirmwareVersion: " > HDD_FW.txt
	FOR /F "tokens=1,2* delims==" %%i in (HDD_FW.txt) do (
		set Reading=%%j
	)
	echo %3 > HDD_List.txt
	if defined Reading set Reading=%Reading: FIRMWAREVERSION: =%
	if defined Reading set Reading=%Reading: =%
	find /i "%Reading%" HDD_List.txt
	if !errorlevel! neq 0 (
		set RTN=255
	)
	
	if %RTN% equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:Memory
	set TestItem=%TestItems_Count%_GetMemoryInformation
	set DBLogFile=GetPhysicalMemoryInfo
	set LogFile=GetPhysicalMemoryInfo.txt
	set rtn=0
	
	del /q %LogFile%
	del /q Memory_Vendor.txt
	del /q Memory_Size.txt
	del /q Memory_Freq.txt	
	DevInfo-diag.exe -SN %SN% /cmd GetPhysicalMemoryInfo > %LogFile%
	PT-diags.exe -nc -nl /find %LogFile% "Manufacturer" > Memory_Vendor.txt
	for /f "tokens=1,2* delims==" %%i in (Memory_Vendor.txt) do (
		set Reading=%%k
	)
	find /i %2 Memory_Vendor.txt
	if %errorlevel% neq 0 (
		set rtn=255
	)

	PT-diags.exe -nc -nl /find %LogFile% "MemorySize=" > Memory_Size.txt
	for /f "tokens=1,2* delims==" %%i in (Memory_Size.txt) do (
		set Reading=%%k
	)
	if defined Reading set Reading=%Reading: =%
	if "%Reading%" neq %3 (
		set rtn=255
	)
	
	PT-diags.exe -nc -nl /find %LogFile% "MemoryFreq" > Memory_Freq.txt
	for /f "tokens=1,2* delims==" %%i in (Memory_Freq.txt) do (
		set Reading=%%k
	)
	if defined Reading set Reading=%Reading: =%
	if "%Reading%" neq %4 (
		set rtn=255
	) 
	
	if %rtn% equ 0 (
		goto pass
	) else (
		goto fail
	)
	
:PCI_Info
	set TestItem=%TestItems_Count%_GetPCIInformation
	set DBLogFile=GetHardwareComponents DevNodeInfo
	set LogFile=GetHardwareComponents.txt
	set rtn=0
	
	del /q %LogFile%
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
	set DBLogFile=GetThermals
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

:SurfLink_RID
	set TestItem=%TestItems_Count%_GetSurfLinkInformation
	set DBLogFile=GetSurfLinkRid
	set LogFile=GetSurfLinkRidAdc.txt
	if "%2"=="Get" (
		del %LogFile%
		del SLRidBin_Result.log
		del SLRidAdc_Result.log
		DevInfo-diag.exe -SN %SN% /cmd GetSurfLinkRid > %LogFile%
		if not exist %LogFile% goto fail
		goto pass
	)
	Set SkipCountAdd=True
	PT-diags.exe -nc -nl /find %LogFile% "Rid%2=" > SLRid%2_Result.log
	FOR /F "tokens=1,2* delims==" %%i in (SLRid%2_Result.log) do (
		set Reading=%%k
	)
	if defined Reading set Reading=%Reading: =%
	echo !Reading!> SLRid%2_Result.log

	if "%2"=="Adc" (
		if !Reading! LEQ %3 echo less than value& set rtn=1& goto not_backup
		if !Reading! GEQ %4 echo greater than value& set rtn=2& goto not_backup
		set rtn=0& goto not_backup
	)
	if "%2"=="Bin" (
		if !Reading! neq %3 set rtn=255& goto not_backup
		set rtn=0& goto not_backup
	)

:POST_Time	
	del /q UEFIPostTime.txt
	
	call _DeviceBridge.bat Run C:\Windows\System32\reg.exe "query ""HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power"" /v fwPOSTTime" fwPOSTTime
	
	if not exist fwPOSTTime.txt exit /b 255
	findstr /c:"fwPOSTTime    REG_DWORD" fwPOSTTime.txt > tmp.txt
	for /f "delims=x tokens=1,2*" %%i in (tmp.txt) do (
		set POSTTime_Hex=%%j	
	)
	set /a POSTTime=0x%POSTTime_Hex%
	echo %POSTTime%>UEFIPostTime.txt
	exit /b 0
	
:Get_NFCChipID
	set TestItem=%TestItems_Count%_NFC_ChipID
	set DBLogFile=GetNfcChipId
	set LogFile=NFC_ChipID.txt
	DevInfo-diag.exe -SN %SN% /cmd GetNfcChipId -cmp %2 %3 %4 > %LogFile%
	if %errorlevel% neq 0 goto fail 
	goto pass
	
:NFC_AntSelfTest1
	set TestItem=%TestItems_Count%_NFC_AntSelfTest1
	set DBLogFile=NfcAntennaSelfTestLoop1
	set LogFile=NFC_AntSelfTest1.txt
	del /q %LogFile%
	DevInfo-diag.exe /cmd NfcAntennaSelfTestLoop1 > %LogFile%
	findstr /c:"NfcAntennaSelfTestLoop1 NfcAntennaTxLdoCurrent=" %LogFile%>tmp.txt
	for /f "tokens=1,2 delims==" %%i in (tmp.txt) do (
		set tx=%%j
	)
	if %tx% geq %2 goto pass
	goto fail 
	
:NFC_AntSelfTest2	
	set TestItem=%TestItems_Count%_NFC_AntSelfTest2
	set DBLogFile=NfcAntennaSelfTestLoop2
	set LogFile=NFC_AntSelfTest2.txt
	del /q %LogFile%
	DevInfo-diag.exe /cmd NfcAntennaSelfTestLoop2 > %LogFile%
	findstr /c:"NfcAntennaSelfTestLoop2 NfcAntennaRssi=" %LogFile%>tmp.txt
	for /f "tokens=1,2 delims==" %%i in (tmp.txt) do (
		set rssi=%%j
	)
	if %rssi% geq %2 goto pass
	goto fail 
	
:RebootTest
	set TestItem=%TestItems_Count%_Reboot
	set DBLogFile=Reboot Device_Configure
	set LogFile=Reboot.txt
	DevInfo-diag.exe /cmd "RebootTest true" -cmp Done > %LogFile%
	if %errorlevel% neq 0 goto fail 
	goto pass
	
:Shutdown	
	set TestItem=%TestItems_Count%_Shutdown
	set DBLogFile=Shutdown
	set LogFile=Shutdown.txt
	DevInfo-diag.exe /cmd "Shutdown true" -cmp Done > %LogFile%
	if %errorlevel% neq 0 goto fail 
	goto pass

:DiskSmartTest
set TestItem=%TestItems_Count%_DiskSmartStatus
set DBLogFile=PingDiskSmartStatus
set LogFile=PingDiskSmartStatus.txt

DevInfo-diag.exe -SN %SN% /cmd PingDiskSmartStatus -cmp "Done" > %LogFile%
if %errorlevel% equ 0 goto pass	
goto fail
	
:NoParameter
echo no Parameter enter.
goto End


:fail
echo fail
cd %~dp0
If "%SkipCountAdd%"=="False" (
	set /a TestItems_Count+=1
	echo !TestItems_Count! > ..\TestItems_Count.flg
)
if not exist ..\Tools\Temp\MISClog\%TestItem% MKDIR ..\Tools\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Tools\Temp\MISClog\%TestItem%\
copy /y DB_initial.log ..\Tools\Temp\MISClog\%TestItem%\%TestItem%_DB_initial.log
for %%D in (!DBLogFile!) do move /y C:\DeviceBridgeLogs\%SN%_%TSRID_DB%\*%%D*.* ..\Tools\Temp\MISClog\%TestItem%\
echo rtn="%rtn%"
if defined rtn (
	exit /b %rtn% 
) else (
	exit /b 255
)

:pass
echo pass
cd %~dp0
If "%SkipCountAdd%"=="False" (
	set /a TestItems_Count+=1
	echo !TestItems_Count! > ..\TestItems_Count.flg
)
if not exist ..\Tools\Temp\MISClog\%TestItem% MKDIR ..\Tools\Temp\MISClog\%TestItem%
if defined LogFile copy /y %LogFile% ..\Tools\Temp\MISClog\%TestItem%\
copy /y DB_initial.log ..\Tools\Temp\MISClog\%TestItem%\%TestItem%_DB_initial.log
for %%D in (!DBLogFile!) do move /y C:\DeviceBridgeLogs\%SN%_%TSRID_DB%\*%%D*.* ..\Tools\Temp\MISClog\%TestItem%\
exit /b 0

:not_backup
if defined rtn (
	echo %rtn%
	exit /b %rtn%
) else ( 
	exit /b 255
)

:End