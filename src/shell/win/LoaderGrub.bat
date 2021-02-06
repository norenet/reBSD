@set @tmpvar=1 /*
@echo off
echo reBSD init core v2020(based windows 7 ~ 10)
icacls "%windir%\system32\config\system" >nul 2>&1
if [%errorlevel%] neq [0] (
powershell  -c "Start-Process \"%0\" -Verb RunAs"
exit
)

::start
setlocal EnableDelayedExpansion
cls
set "NICs=%temp%\NICs"
echo.>%NICs%
call :wmic nicconfig where "IPEnabled=TRUE and IPConnectionMetric>0" get Index^^,ipaddress^^,IPSubnet^^,macaddress^^,defaultipgateway^^,GatewayCostMetric^^,DNSServerSearchOrder^^,DHCPEnabled /format:list
exit /b

:wmic
set /a line=-1
set "defsrc="
for /f "delims=" %%A in ('wmic %*') do for /f "tokens=1,2 delims==" %%B in ("%%A") do (
	call :checks %%B
	echo %%B_!line!=%%C>>%NICs%
	)
echo NICs_Def=!defsrc:~0,-1!>>%NICs%
endlocal
call :loader
exit /b

:checks
set "cks=%1"
if "%cks%"=="DefaultIPGateway" (
	set /a line+=1
	)
if "%cks%"=="DefaultIPGateway" (
	set "defsrc=%defsrc%%line% "
	)
goto :eof

:loader
set "letter=R:"
set "grub_inst_dir=%temp%\rebsd_grub"
if not exist "%NICs%" call :error "loader_conf file not exist!"
set "mirror=http://rebsd.nore.net/reBSD"
setlocal EnableDelayedExpansion
::init_col
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "DEL=%%a"
)
<nul > X set /p ".=."

::end
::config
set "tab=       "
set "def_auto_scp=NO"
set "def_auto_act=None"
set "def_auto_type=Reboot"
set "def_auto_dhcp=NO"
set "def_rootpass=reBSD@123456"
set "def_sshport=22"
set "def_con_nopass=NO"
set "srv_name=reBSD"
::rebsd hostname
:hostname
call :color 0a "-> Do you want to change the hostname? "
set /P c_host=[y/N]:
if /I "%c_host%" EQU "Y" goto :c_hostname
goto :hostname_show

:c_hostname
call :color 0b "Enter new hostname"
set /P srv_name=: 

:hostname_show
set/p=reBSD hostname: <nul
call :color 0e "%srv_name%"
echo.
::root password.
:rootpw
call :color 0a "-> Do you want to change reBSD root password? "
set /P c_rpw=[y/N]:
if /I "%c_rpw%" EQU "Y" goto :c_rootpw
goto :rootpw_show

:c_rootpw
call :color 0b "Enter new reBSD root password"
set /P def_rootpass=: 

:rootpw_show
set/p=reBSD root password: <nul
call :color 0e "%def_rootpass%"
echo.

::SSH services
:sshport
call :color 0a "-> Do you want to change SSH port? "
set /P c_sshp=[y/N]:
if /I "%c_sshp%" EQU "Y" goto :c_sshport
goto :sshport_show

:c_sshport
call :color 0b "Enter new SSH Port"
set /P def_sshport=: 
for /f "delims=" %%i in ('echo %def_sshport%^|findstr "[^0-9]"') do (
if not "%%i"=="" (
echo Not a valid port number, try again!
goto :c_sshport
)
)
if "%def_sshport%" LEQ 10 (
echo Please enter a number in the range of [10-65535]
goto :c_sshport
)
if "%def_sshport%" GEQ 65535 (
echo Please enter a number in the range of [10-65535]
goto :c_sshport
)

:sshport_show
set/p=reBSD SSH Port: <nul
call :color 0e "%def_sshport%"
echo.

::console protect.
:con_protect
call :color 0a "-> Log in automatically to a console when boots? "
set /P c_conp=[y/N]:
if /I "%c_conp%" EQU "Y" goto :c_con_protect
goto :con_protect_show

:c_con_protect
set "def_con_nopass=YES"

:con_protect_show
set/p=Auto-login as root in console: <nul
call :color 0e "%def_con_nopass%"
echo.


::auto-installer.
:auto_inst
call :color 0b "-> Do you want run auto-install a system?! "
set /P c_ainst=[y/N]:
if /I "%c_ainst%" EQU "Y" goto :c_auto_inst
goto :auto_inst_show

:c_auto_inst
@echo.
call :color 0b "1"
set/p=) Install FreeBSD%tab%<nul
call :color 0b "3"
echo ) Install Linux
call :color 0b "2"
set/p=) Install pfSense%tab%<nul
call :color 0b "4"
echo ) Install Windows
@echo.
call :color 0d "Select a system type [1-4]"
choice /n /c:1234 /M ":"
GOTO LABEL-%ERRORLEVEL%

::auto-installer table.
:LABEL-1 FreeBSD
set "def_auto_scp=Freebsd"
goto :auto_inst_show

:LABEL-2 pfSense
set "def_auto_scp=pfSense"
set "def_pf_web_port=65088"
set "def_pfweb_id=rebsd"
set "def_pfweb_pw=rebsd@123456"
set "def_pf_bsd_repos=NO"
::pf web services
:pf_webport
call :color 0a "-> Do you want to change pfSense Web port? "
set /P c_pfwp=[y/N]:
if /I "%c_pfwp%" EQU "Y" goto :c_pf_webport
goto :pf_webport_show

:c_pf_webport
call :color 0b "Enter new pfSense Web Port"
set /P def_pf_web_port=: 
for /f "delims=" %%i in ('echo %def_pf_web_port%^|findstr "[^0-9]"') do (
if not "%%i"=="" (
echo Not a valid port number, try again!
goto :c_pf_webport
)
)
if "%def_pf_web_port%" LEQ 10 (
echo Please enter a number in the range of [10-65535]
goto :c_pf_webport
)
if "%def_pf_web_port%" GEQ 65535 (
echo Please enter a number in the range of [10-65535]
goto :c_pf_webport
)

:pf_webport_show
set/p=pfSense Web Port: <nul
call :color 0e "%def_pf_web_port%"
echo.
::pf web id.
:pf_webid
call :color 0a "-> Do you want to change pfSense Web easy-auth Username? "
set /P c_pfwid=[y/N]:
if /I "%c_pfwid%" EQU "Y" goto :c_pf_webid
goto :pf_webid_show

:c_pf_webid
call :color 0b "Enter easy-auth Username:"
set /P def_pfweb_id=: 

:pf_webid_show
set/p=pfSense Web easy-auth Username: <nul
call :color 0e "%def_pfweb_id%"
echo.

::pf web pw.
:pf_webpw
call :color 0a "-> Do you want to change pfSense Web easy-auth Username? "
set /P c_pfwpw=[y/N]:
if /I "%c_pfwpw%" EQU "Y" goto :c_pf_webpw
goto :pf_webpw_show

:c_pf_webpw
call :color 0b "Enter easy-auth Password:"
set /P def_pfweb_pw=: 

:pf_webpw_show
set/p=pfSense Web easy-auth Password: <nul
call :color 0e "%def_pfweb_pw%"
echo.

::pf repos enable.
:pf_repos
call :color 0a "-> Do you want enable FreeBSD repository? "
set /P c_pfrep=[y/N]:
if /I "%c_pfrep%" EQU "Y" goto :c_pf_repos
goto :pf_repos_show

:c_pf_repos
set "def_pf_bsd_repos=YES"

:pf_repos_show
set/p=pfSense enable FreeBSD repository: <nul
call :color 0e "%def_pf_bsd_repos%"
echo.
goto :auto_inst_show

:LABEL-3 Linux
@echo.
call :color 0e "1"
set/p=) Install Ubuntu(18.04)   <nul
call :color 0e "3"
echo ) Install Cenots(8.0)
call :color 0e "2"
set/p=) Install Debian(10.2)%tab%<nul
call :color 0e "4"
echo ) Install Archlinux(201912)
@echo.
call :color 0b "Select a system type [1-4]"
choice /n /c:1234 /M ":"
GOTO Linux-%ERRORLEVEL%

:Linux-1 Ubuntu
set "def_auto_scp=Ubuntu_18"
goto :auto_inst_show

:Linux-2 Debian
set "def_auto_scp=Debian_12"
goto :auto_inst_show

:Linux-3 Cenots
set "def_auto_scp=CentOS_8"
goto :auto_inst_show

:Linux-4 Archlinux
set "def_auto_scp=Arch_1912"
goto :auto_inst_show

:LABEL-4 Windows
@echo.
call :color 0e "1"
set/p=) Server-2003R2-Ent%tab%<nul
call :color 0e "4"
echo ) Windows-XP-SP3-Pro
call :color 0e "2"
set/p=) Server-2008R2-Std%tab%<nul
call :color 0e "5"
echo ) Windows-7-SP1-Pro
call :color 0e "3"
set/p=) Server-2019-Std%tab%<nul
call :color 0e "6"
echo ) Windows-10-Work
@echo.
call :color 0b "Select a system type [1-4]"
choice /n /c:123456 /M ":"
GOTO Win-%ERRORLEVEL%

:Win-1 Server2003
set "def_auto_scp=Win_2k3"
goto :auto_win_choice

:Win-2 Server2008
set "def_auto_scp=Win_2k8"
goto :auto_win_choice

:Win-3 Server2019
set "def_auto_scp=Win_2k19"
goto :auto_win_choice

:Win-4 WinXP
set "def_auto_scp=Win_xp"
goto :auto_win_choice

:Win-5 Win7
set "def_auto_scp=Win_7"
goto :auto_win_choice

:Win-6 Win10
set "def_auto_scp=Win_10"
goto :auto_win_choice

:auto_win_choice
set "def_rdp_port=63389"
::rdp port
:win_rdpport
call :color 0a "-> Do you want to change RDP port? "
set /P c_wrdp=[y/N]:
if /I "%c_wrdp%" EQU "Y" goto :c_win_rdpport
goto :win_rdpport_show

:c_win_rdpport
call :color 0b "Enter new RDP Port"
set /P def_rdp_port=: 
for /f "delims=" %%i in ('echo %def_rdp_port%^|findstr "[^0-9]"') do (
if not "%%i"=="" (
echo Not a valid port number, try again!
goto :c_win_rdpport
)
)
if "%def_rdp_port%" LEQ 10 (
echo Please enter a number in the range of [10-65535]
goto :c_win_rdpport
)
if "%def_rdp_port%" GEQ 65535 (
echo Please enter a number in the range of [10-65535]
goto :c_win_rdpport
)

:win_rdpport_show
set/p=Windows RDP Port: <nul
call :color 0e "%def_rdp_port%"
echo.
goto :auto_inst_show

:auto_inst_show
set/p=reBSD Auto-installer: <nul
call :color 0e "%def_auto_scp%"
echo.

::choose auto-act
:auto_act
if not "%def_auto_scp%"=="NO" goto :auto_act_ch
goto :auto_type

:auto_act_ch
call :color 0c "-> What I should do immediately after installing %def_auto_scp%? "
echo.
call :color 0e "1"
echo ) Reboot
call :color 0e "2"
echo ) Shutdown
call :color 0e "3"
echo ) none *(default)
echo.
call :color 0b "Choose an action [1-3]"
choice /n /c:123 /M ":"
GOTO Auto_act-%ERRORLEVEL%

:Auto_act-1 reboot
set "def_auto_act=reboot"
goto :auto_type
:Auto_act-2 shutdown
set "def_auto_act=shutdown"
goto :auto_type
:Auto_act-3 none
goto :auto_type

::choose auto-type
:auto_type
call :color 0d "-> What to do if the reBSD fails to check the network? "
echo.
call :color 0e "1"
echo ) None(Debug mode)
call :color 0e "2"
echo ) boot to old system *(default)
echo.
call :color 0b "Choose an action [1-2]"
choice /n /c:12 /M ":"
GOTO Auto_type-%ERRORLEVEL%

:Auto_type-1 reboot
set "def_auto_type=None"
goto :auto_inst_finish
:Auto_type-2 shutdown
goto :auto_inst_finish


:auto_inst_finish
call :network
call :show_configs
:goon
call :color 0c "-> So, shall we continue? "
set /P c_goon=[y/N]:
if /I "%c_goon%" EQU "Y" goto :c_goon
echo Have a good day.
echo good bye.
del /f /q %NICs%
del /f /q X
pause
exit
:c_goon
call :grub
:grub_back
echo all clean.
endlocal
del /f /q %NICs%
del /f /q X
rd /s /q "%grub_inst_dir%"

set /P c_rebt= ## Do you want to reboot now?[y/N]:
if /I "%c_rebt%" EQU "Y" call :reboot
echo Have a good day.
echo good bye.
pause
exit

:network
set "mac_interfaces="
set "def_auto_dhcp=NO"
set defaultrouter=""
set "dnsnames="
set "eth="
set "inet_eth="
for /f "delims=" %%a in ('type "%NICs%"') do set "%%a"
for %%d in (%NICs_Def%) do (
::def 1
for /f delims^=^"^ tokens^=2 %%b in ('echo !DefaultIPGateway_%%d!') do (
if "!GatewayCostMetric_%%d!" == "{0}" (
set "defaultrouter=%%b"
for /f delims^=^"^ tokens^=2 %%x in ('echo !DNSServerSearchOrder_%%d!') do set dnsnames=%%x
set inet_eth=eth%%d
) else if !defaultrouter! == "" (
set "defaultrouter=%%b"
for /f delims^=^"^ tokens^=2 %%x in ('echo !DNSServerSearchOrder_%%d!') do set dnsnames=%%x
set inet_eth=eth%%d
)
)
::mask_sub
for /f "tokens=2* delims==" %%m in ('wmic nic where "MACaddress='!MACAddress_%%d!'" get NetConnectionID /value ^| findstr "NetConnectionID"') do (
for /f "tokens=1,2* delims=:" %%a in ('netsh interface ipv4 show addr "%%m" ^| findstr /C:"/" /C:"(" /C:")"') do (
for /f "tokens=2 delims=/" %%a in ("%%b") do for /f "tokens=1 delims=(" %%b in ("%%a") do set "Subnet=%%b" 
)
)
::nic_conf
set "ifconfig_eth%%d_mac=!MACAddress_%%d!"
if !DHCPEnabled_%%d! == TRUE (
set "ifconfig_eth%%d=dhcp"
set "ifconfig_eth_%%d_show=DHCP"
) else (
for /f delims^=^"^ tokens^=2 %%x in ('echo !IPAddress_%%d!') do (
set "ifconfig_eth%%d=inet %%x/!Subnet:~0,-1!"
set "ifconfig_eth_%%d_show=%%x (!Subnet:~0,-1!)"
)
)
set eth=!eth!eth%%d 
)
goto :eof

:show_configs
::show config.
echo.
echo Config list:
call :color 0f "---------------------------------------------"
echo.
set/p=reBSD hostname: <nul
call :color 0e "%srv_name%"
echo.
::inet config
set/p=reBSD internet DHCP Mode: <nul
call :color 0e "%def_auto_dhcp%"
echo.
set/p=reBSD internet eth: <nul
call :color 0e "!!inet_eth!!"
echo.
::LIST nic
for %%i in (%NICs_Def%) do (
set/p= reBSD NICs <nul
call :color 0b "eth%%i "
set/p= MAC Address: <nul
call :color 0e "!ifconfig_eth%%i_mac!"
echo.
set/p= reBSD NICs <nul
call :color 0b "eth%%i "
set/p= IP Address: <nul
call :color 0e "!ifconfig_eth_%%i_show!"
echo.
)
::END
set/p=reBSD internet Gateway: <nul
call :color 0e "!defaultrouter!"
echo.
set/p=reBSD internet DnsServers: <nul
call :color 0e "8.8.8.8 !!dnsnames!!"
echo.
::inet end
set/p=reBSD root Password: <nul
call :color 0e "%def_rootpass%"
echo.
set/p=reBSD SSH Port: <nul
call :color 0e "%def_sshport%"
echo.
set/p=Auto-login as root in console: <nul
call :color 0e "%def_con_nopass%"
echo.
set/p=reBSD auto installer: <nul
call :color 0e "%def_auto_scp%"
echo.
::installer config
for /f "delims=" %%i in ('echo %def_auto_scp%^|findstr "Win_"') do (
set/p=reBSD auto script RDP Port: <nul
call :color 0e "%def_rdp_port%"
echo.
)
if "%def_auto_scp%"=="pfSense" (
set/p=reBSD auto script pfSense Web Port: <nul
call :color 0e "%def_pf_web_port%"
echo.
set/p=reBSD auto script pfSense Web easy-auth Username: <nul
call :color 0e "%def_pfweb_id%"
echo.
set/p=reBSD auto script pfSense Web easy-auth Password: <nul
call :color 0e "%def_pfweb_pw%"
echo.
set/p=reBSD auto script pfSense enable FreeBSD repository: <nul
call :color 0e "%def_pf_bsd_repos%"
echo.
)
::installer end
set/p=reBSD auto Complete action: <nul
call :color 0e "%def_auto_act%"
echo.
set/p=reBSD check network action: <nul
call :color 0e "%def_auto_type%"
echo.
call :color 0f "---------------------------------------------"
echo.
goto :eof

:grub
::find disk
@For /F Tokens^=2Delims^=^" %%A In ('WMIC LogicalDisk Where "DeviceID='%~d0'" Assoc /AssocClass:Win32_LogicalDiskToPartition 2^>Nul^|Find "n."')Do @For /F Tokens^=2Delims^=^" %%B In ('WMIC Path Win32_DiskDriveToDiskPartition 2^>Nul^|Find "%%A"')Do (
@set "drive=%%B"
@set "parts=%%A"
)
::split string
set parts=!parts:#=%!
for /F "tokens=1,2 delims=." %%a in ("%parts:, =.%") do (
	set "disk=%%a"
	set "part=%%b"
)
for /f "tokens=1,2 delims= " %%x in ("%part%") do (
set /a part=%%y+1
set /a new_part=%%y+2
)

::check rebsd part.
call :ck_part volume Where "Label='reBSD'" get FileSystem^^,Name /format:list 2^>Nul^
:ck_part
for /f "delims=" %%A in ('wmic %*') do for /f "tokens=1,2 delims==" %%B in ("%%A") do set "%%A"
if defined Name (call :grub_exists) else (call :grub_shrink_disk)

call :download
::install_grub
if not exist "%letter%\grub\grubenv" (
for /f "delims=" %%i in ('bcdedit /enum {current}^|findstr "efi"') do (
echo starting install grub2(UEFI).
%grub_inst_dir%\grub-install.exe --boot-directory=%letter%\ --efi-directory=%letter% --removable --target=x86_64-efi
goto :grub_inst_done
)
echo starting install grub2(BIOS).
%grub_inst_dir%\grub-install.exe --boot-directory=%letter%\ --target=i386-pc "%drive%"
:grub_inst_done
::set next reboot.
copy /y "%grub_inst_dir%\grub.cfg" "%letter%\grub\" >Nul
copy /y "%grub_inst_dir%\win.cfg" "%letter%\grub\" >Nul
call :grub_rebsd
)
echo set next-boot.
%grub_inst_dir%\grub-editenv.exe %letter%\grub\grubenv set next_entry=reBSD
call :grub_remove_letter
goto :grub_back

:grub_exists
echo starting check reBSD disk.
if not "%FileSystem%"=="FAT32" call :grub_rformat
for /f "delims=" %%x in ('echo %Name%^|findstr /v "%letter%\\"') do call :grub_set_letter
goto :eof

:grub_shrink_disk
echo starting shrink work: %parts%
(echo Rescan
echo List Disk
echo Select %disk%
echo List Partition
echo Select Partition %part%
echo Shrink desired=99
echo Rescan
echo Create partition primary size=99
echo Select Partition %new_part%
echo Format quick FS=fat32 label="reBSD"
echo Assign letter=%letter%
echo Rescan
echo exit
) | diskpart >nul
goto :eof


:grub_rformat
echo formating...
(echo Rescan
echo Select %disk%
echo Format quick FS=fat32 label="reBSD"
echo Assign letter=%letter%
echo Rescan
echo exit
) | diskpart >nul
goto :eof

:grub_set_letter
echo set reBSD letter...
(echo Rescan
echo Select %disk%
echo Select Partition %new_part%
echo Assign letter=%letter%
echo Rescan
echo exit
) | diskpart >nul
goto :eof

::remove letter.
:grub_remove_letter
echo remove reBSD letter...
(echo Rescan
echo Select %disk%
echo Select Partition %new_part%
echo Remove letter=%letter%
echo Rescan
echo exit
) | diskpart >nul
goto :eof

:grub_rebsd
echo Generate reBSD grub2 cfg...
(echo menuentry "reBSD" ^{
echo		if ^^! cpuid -l;then
echo		  echo -e "\nYour CPU does not implement AMD64 architecture."
echo		  sleep -i -v 5
echo		  WindowsDetect
echo		fi
echo        if [ -f "/reBSD.iso" ];then 
echo         set isofile="/reBSD.iso"
echo        elif [ -f "/reBSD/reBSD.iso" ];then 
echo         set isofile="/reBSD/reBSD.iso"
echo		else
echo		 echo -e "\nCan't find reBSD core iso file."
echo		 sleep -i -v 5
echo		 WindowsDetect
echo        fi
echo        loopback loop ^$isofile
echo        kfreebsd ^(loop^)/boot/kernel/kernel.gz -v
echo        kfreebsd_loadenv ^(loop^)/boot/loader.conf
echo        kfreebsd_module ^(loop^)/boot/kernel/ahci.ko
echo        kfreebsd_module ^(loop^)/reBSD.gz type=mfs_root
echo        set kFreeBSD.rebsd.hostname="%srv_name%"
echo        set kFreeBSD.rebsd.rootpw="%def_rootpass%"
echo        set kFreeBSD.rebsd.auto_sshd_port="%def_sshport%"
echo        set kFreeBSD.rebsd.autodhcp="%def_auto_dhcp%"
echo        set kFreeBSD.rebsd.inet_interfaces="!!inet_eth!!"
echo        set kFreeBSD.rebsd.mac_interfaces="!!eth:~0,-1!!"
::LIST nic
for %%i in (%NICs_Def%) do (
echo        set kFreeBSD.rebsd.ifconfig_eth%%i_mac="!ifconfig_eth%%i_mac!"
echo        set kFreeBSD.rebsd.ifconfig_eth%%i="!ifconfig_eth%%i!"
)
::END
echo        set kFreeBSD.rebsd.defaultrouter="!defaultrouter!"
echo        set kFreeBSD.rebsd.nameservers="8.8.8.8 !!dnsnames!!"
echo        set kFreeBSD.rebsd.auto_script="%def_auto_scp%"
echo        set kFreeBSD.rebsd.auto_finish_action="%def_auto_act%"
echo        set kFreeBSD.rebsd.auto_type="%def_auto_type%"
echo        set kFreeBSD.rebsd.auto_con_nopass="%def_con_nopass%"
::installer config
for /f "delims=" %%i in ('echo %def_auto_scp%^|findstr "Win_"') do (
echo        set kFreeBSD.rebsd.auto_rdpport="%def_rdp_port%"
)
if "%def_auto_scp%"=="pfSense" (
echo        set kFreeBSD.rebsd.auto_webd_port="%def_pf_web_port%"
echo        set kFreeBSD.rebsd.auto_pfweb_id="%def_pfweb_id%"
echo        set kFreeBSD.rebsd.auto_pfweb_pw="%def_pfweb_pw%"
echo        set kFreeBSD.rebsd.auto_pf_bsd_repos="%def_pf_bsd_repos%"
)
::installer end
echo ^}
) > "%letter%\grub\rebsd.cfg"
goto :eof
}


:download
echo download grub files...
if exist "%temp%\rebsd-grub204.cab" (
call :down_jscore GRUB_Hashsum "%mirror%/Files/shell/core/grub2/rebsd-grub204.sha1" "%temp%\rebsd-grub204.sha1"
goto :check_grub
)

:grub_core
call :down_jscore GRUB_Hashsum "%mirror%/Files/shell/core/grub2/rebsd-grub204.sha1" "%temp%\rebsd-grub204.sha1"
call :down_jscore reBSD_Grub "%mirror%/Files/shell/core/grub2/rebsd-grub204.cab" "%temp%\rebsd-grub204.cab"
:check_grub
set /p GSHA1=<%temp%\rebsd-grub204.sha1
call :sha1_sum %temp%\rebsd-grub204.cab sha1
if "%sha1%" equ "%GSHA1%" (
      echo GrubCore SHA1 identical!
) else (
	  echo GrubCore SHA1 does not match.
      goto :grub_core
)

:un_grub
IF not exist %grub_inst_dir% (mkdir %grub_inst_dir% 2> NUL)
Expand %temp%\rebsd-grub204.cab -F:* %grub_inst_dir% > NUL

::rebsd
echo download reBSD files...
if exist "%letter%\reBSD.iso" (
call :down_jscore reBSD_Hashsum "%mirror%/Files/iso/reBSD-latest-RELEASE-amd64-WIN.iso.sha1" "%temp%\reBSD.sha1"
goto :check_sum
)
:core_file
call :down_jscore reBSD_Hashsum "%mirror%/Files/iso/reBSD-latest-RELEASE-amd64.iso.sha1" "%temp%\reBSD.sha1"
call :down_jscore reBSD_Core "%mirror%/Files/iso/reBSD-latest-RELEASE-amd64.iso" "%letter%\reBSD.iso"
:check_sum
set /p RSHA1=<%temp%\reBSD.sha1
set RSHA1=!RSHA1:  -=%!
call :sha1_sum %letter%\reBSD.iso sha1
if "%sha1%" equ "%RSHA1%" (
      echo reBSD SHA1 identical!
) else (
	  echo reBSD SHA1 does not match.
      goto :core_file
)
goto :eof

:down_core
setlocal
set "t=%1"
set "d=%2"
set "s=%3"
echo downloading %t%...
:try_again
%WINDIR%\System32\WindowsPowerShell\v1.0\powershell -NoProfile -ExecutionPolicy Bypass -Command "$client = New-Object System.Net.WebClient; if (Test-Path env:HTTP_PROXY) { $client.Proxy = New-Object System.Net.WebProxy $env:HTTP_PROXY }; $client.DownloadFile('%d%', '%s%')" 1>NUL
if [%errorlevel%] neq [0] (
echo Download file error,try a again next time!
@ping 127.0.0.1 -n 5 -w 1000 > nul
goto :try_again
)
endlocal
goto :eof

:sha1_sum
setlocal enableDelayedExpansion
if "%~1" equ "" (
	echo no file passed
	exit /b 1
)
if not exist "%~1" (
	echo file %~1 does not exist
	exit /b 2
)
if exist "%~1\" (
	echo %~1 is a directory
	exit /b 3
)
for %%# in (certutil.exe) do (
	if not exist "%%~f$PATH:#" (
		echo no certutil installed
		echo for Windows XP professional and Windows 2003
		echo you need Windows Server 2003 Administration Tools Pack
		echo https://www.microsoft.com/en-us/download/details.aspx?id=3725
		exit /b 4
	)
)
set "sha1="
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "%~f1" SHA1') do (
	if not defined sha1 (
		for %%Z in (%%#) do set "sha1=!sha1!%%Z"
	)
)
if "%~2" neq "" (
	endlocal && (
		set "%~2=%sha1%"
	) 
) else (
	echo %sha1%
)
endlocal
goto :eof

:reboot
echo The system will restart and boot reBSD after 10 seconds.
shutdown -r -t 10
goto :eof

:error
echo [Error]: %1%2&&pause
goto :eof

:color
set "param=^%~2" !
set "param=!param:"=\"!"
findstr /p /A:%1 "." "!param!\..\X" nul
<nul set /p ".=%DEL%%DEL%%DEL%%DEL%%DEL%%DEL%%DEL%"
exit /b

:down_jscore
set "t=%1"
set "d=%2"
set "s=%3"
echo downloading %t%...
:jstry_again
call :jsdownload "%d%" "" "%s%"
if [%errorlevel%] neq [0] (
echo Download file error,try a again next time!
@ping 127.0.0.1 -n 5 -w 1000 > nul
goto :jstry_again
)
goto :eof


:jsdownload
cscript /nologo /e:jscript "%~f0" %*
exit /b %ERRORLEVEL%
*/
function getFileName(uri) {
    var re = /\/([^?/]+)(?:\?.+)?$/;
    var match = re.exec(uri);
    return match != null ? match[1] : "output";
}
try {
    var Source = WScript.Arguments.Item(0);
    var Proxy  = WScript.Arguments.Length > 1 ? WScript.Arguments.Item(1) : "";
    var Target = WScript.Arguments.Length > 2 ? WScript.Arguments.Item(2) : getFileName(Source);
    var Object = WScript.CreateObject('MSXML2.ServerXMLHTTP');
    if (Proxy.length > 0) {
        Object.setProxy(2/*SXH_PROXY_SET_PROXY*/, Proxy, "");
    }
    Object.open('GET', Source, false);
    Object.send();
    if (Object.status != 200) {
        WScript.Echo('Error:' + Object.status);
        WScript.Echo(Object.statusText);
        WScript.Quit(1);
    }
    var File = WScript.CreateObject('Scripting.FileSystemObject');
    if (File.FileExists(Target)) {
        File.DeleteFile(Target);
    }
    var Stream = WScript.CreateObject('ADODB.Stream');
    Stream.Open();
    Stream.Type = 1/*adTypeBinary*/;
    Stream.Write(Object.responseBody);
    Stream.Position = 0;
    Stream.SaveToFile(Target, 2/*adSaveCreateOverWrite*/);
    Stream.Close();

} catch (e) {
    WScript.Echo("--------------------");
    WScript.Echo("Error " + (e.number & 0xFFFF) + "\r\n  " + e.description.replace(/[\r\n]*$/, "\r\n"));
    for (var i = 0; i < WScript.Arguments.length; ++i) {
        WScript.Echo("  arg" + (i+1) + ": " + WScript.Arguments(i));
    }
    WScript.Echo("--------------------");
    WScript.Quit(1);
}