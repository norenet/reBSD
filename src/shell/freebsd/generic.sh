#!/bin/sh
# ----------------
# reBSD grub init for FreeBSD
# rebsd.nore.net @FS 2020/02/04
# ----------------
PATH=/sbin:/bin/:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

mirror="http://rebsd.nore.net/reBSD"
grub_pkg="/tmp/grub2-2.00_14.txz"
grub_name="grub2"

if efibootmgr >/dev/null 2>/dev/null ;then
echo "the Loader does not support UEFI."
exit 1
fi

#########>install-Gurb-functions<#########
find_root(){
mount=`awk '{if($2=="/"){print $1}}' /etc/fstab | sed 's/\/dev\///g'`
for disk in `sysctl -n kern.disks`;do
if echo $mount | grep -e "$disk" >/dev/null ;then
root_disk=$disk
return 0
fi
done
return 1
}

mon_inst(){
pkg_info="$1"
echo "Install ${pkg_info}..."
pkg install -qy $pkg_info
while [ $? -ne 0 ]
do
    echo "${1} install failed,try again"
    sleep 3
    pkg install -qy $pkg_info
done
}

pfpkg_inst(){
if ! pkg info binutils 2>/dev/null >/dev/null ;then
echo "Add binutils..."
pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/binutils-2.33.1_2,1.txz"
while [ $? -ne 0 ]
do
    echo "Add binutils failed,try again"
    sleep 3
    pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/binutils-2.33.1_2,1.txz"
done
fi
if ! pkg info mpfr 2>/dev/null >/dev/null ;then
echo "Add mpfr..."
pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/mpfr-4.0.2.txz"
while [ $? -ne 0 ]
do
    echo "Add mpfr failed,try again"
    sleep 3
    pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/mpfr-4.0.2.txz"
done
fi
if ! pkg info mpc 2>/dev/null >/dev/null ;then
echo "Add mpc..."
pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/mpc-1.1.0_2.txz"
while [ $? -ne 0 ]
do
    echo "Add mpc failed,try again"
    sleep 3
    pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/mpc-1.1.0_2.txz"
done
fi
if ! pkg info gcc7 2>/dev/null >/dev/null ;then
echo "Add gcc7..."
pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/gcc7-7.5.0.txz"
while [ $? -ne 0 ]
do
    echo "Add gcc7 failed,try again"
    sleep 3
    pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/gcc7-7.5.0.txz"
done
fi
if ! pkg info gettext-runtime 2>/dev/null >/dev/null ;then
echo "Add gettext-runtime..."
pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/gettext-runtime-0.20.1.txz"
while [ $? -ne 0 ]
do
    echo "Add gettext-runtime failed,try again"
    sleep 3
    pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/gettext-runtime-0.20.1.txz"
done
fi
if ! pkg info gsed 2>/dev/null >/dev/null ;then
echo "Add gsed..."
pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/gsed-4.7.txz"
while [ $? -ne 0 ]
do
    echo "Add gsed failed,try again"
    sleep 3
    pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/gsed-4.7.txz"
done
fi
if ! pkg info indexinfo 2>/dev/null >/dev/null ;then
echo "Add indexinfo..."
pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/indexinfo-0.3.1.txz"
while [ $? -ne 0 ]
do
    echo "Add indexinfo failed,try again"
    sleep 3
    pkg add "${mirror}/Base/reBSD/pkg/${bsd_ver}/indexinfo-0.3.1.txz"
done
fi
}

inst_pkg(){
echo "Update repository..."
pkg install -q -y pkg
pkg update -q
    if ! pkg info $grub_name 2>/dev/null >/dev/null ;then
        bsd_ver=`uname -r | cut -f1 -d '.'`
        if [ ! -f "$grub_pkg" ];then
            echo "Downloading grub2 form reBSD..."
            fetch --timeout=60 --no-verify-hostname --no-verify-peer "${mirror}/Base/reBSD/pkg/${bsd_ver}/grub2-2.00_14.txz" -qo "$grub_pkg" 2>&1
            if [ $? -ne 0 ];then
                printf "\033[1;31mDownload grub2 failed,Please try again.\033[0m\n"
                return 1
            fi
        fi
        if [ `uname -i` == "pfSense" ] && grep "FreeBSD" "/usr/local/share/pfSense/pkg/repos/pfSense-repo.conf" | grep "no" >/dev/null ;then
            if [ "$bsd_ver" != "11" ];then
                error "Missing repository"
            fi
        echo "Add pfSense dependencies ..."
        IGNORE_OSVERSION="yes"
        export IGNORE_OSVERSION
        pfpkg_inst
        else
        echo "Install dependencies..."
        for pkginfo in `pkg info -dqeF $grub_pkg`;do
            mon_inst $pkginfo
        done
        mon_inst "gsed"
        fi
        pkg add -q $grub_pkg
        return $?
    fi
    return 0
}

error(){
echo "[ERR]: ${1}"
exit 1
}

inst_grub(){
root_disk=""
if find_root && inst_pkg ;then
echo "Install grub to ${root_disk}"
[ -z "$root_disk" ] && error "Can't find boot disk."
GRUB_INSTALL=`which grub-install`  || error "Missing grub-install"
GRUB_MKCONFIG=`which grub-mkconfig` || error "Missing grub-mkconfig"
mkdir -p /boot/grub
cp -Rpf /usr/local/lib/grub/i386-pc /boot/grub
$GRUB_INSTALL "/dev/${root_disk}"
$GRUB_MKCONFIG -o "/boot/grub/grub.cfg" ||  error "make grub conf file error!"
[ -f "/boot/grub/grub.cfg.new" ] && error "make grub conf file error!"
else
echo "Install grub err." && exit 1
fi
}

#->config
def_init_name="reBSD"
def_rebsd_url="${mirror}/Files/iso/reBSD-latest-RELEASE-amd64.iso"
def_rebsd_sum="${mirror}/Files/iso/reBSD-latest-RELEASE-amd64.iso.sha1"
def_rebsd_save="/boot/reBSD.iso"
def_rebsd_sums="/tmp/reBSD.sum"
def_sum_exec=`which sha1` || error "Missing sha1"
def_sum_len=40
def_grub_cfg="/boot/grub/grub.cfg"
def_grub=""
def_grub_custom=""
WGET=`which fetch` || error "Missing fetch"
GRUB_MKCONFIG=`which grub-mkconfig` || inst_grub
GRUB_REBOOT=`which grub-reboot`  || error "Missing grub-reboot"
GRUB_EDITENV=`which grub-editenv` || error "Missing grub-editenv"

if [ -s /etc/default/grub ]; then
def_grub="/etc/default/grub"
elif [ -s /usr/local/etc/default/grub ]; then
def_grub="/usr/local/etc/default/grub"
else
def_grub=$(grep "and settings from" "$def_grub_cfg" | tail -1 | awk '{print $NF}')
fi
if [ -s /etc/grub.d/40_custom ]; then
def_grub_custom="/etc/grub.d/40_custom"
elif [ -s /usr/local/etc/grub.d/40_custom ]; then
def_grub_custom="/usr/local/etc/grub.d/40_custom"
else
def_grub_custom=$(grep "40_custom" "$def_grub_cfg" | tail -1 | awk '{print $3}')
fi
if [ "$def_grub" = "" ] && [ "$def_grub_custom" = "" ];then
echo "Please upgrade grub version to 1.x"
exit 1
fi

if [ ! -f "$def_grub" ];then
mkdir -p $(dirname $def_grub)
cat > $def_grub <<EOF
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=3
GRUB_DISTRIBUTOR=\`uname -o\`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
EOF
fi

#########>Download-functions<#########
down_sum(){
count=0 && sums=0
sums=`$WGET --timeout=60 --no-verify-hostname --no-verify-peer $def_rebsd_sum -qo- | awk '{print $1}'`
while [ "$?" != 0 ] | [ ${#sums} != $def_sum_len ] && [ "$count" -lt 3 ]
do
        echo "Error downloading checksum. try again"
        sleep 2
        count=$((count+1))
        sums=`$WGET --timeout=60 --no-verify-hostname --no-verify-peer $def_rebsd_sum -qo- | awk '{print $1}'`
done
}

down_core(){
count=0
# set progress option accordingly
#wget --no-check-certificate $def_rebsd_url $_PROGRESS_OPT | tee $def_rebsd_save | $def_sum_exec -c $def_rebsd_sums && rm -f $def_rebsd_sums || rm -f $def_rebsd_save
$WGET --timeout=60 --no-verify-hostname --no-verify-peer -o $def_rebsd_save $def_rebsd_url
while [ "$?" != 0 ] | [ ! -f $def_rebsd_save ] && [ "$count" -lt 1 ]
do
        echo "Error downloading reBSD file. try again"
        sleep 3
        count=$((count+1))
       $WGET --timeout=60 --no-verify-hostname --no-verify-peer -o $def_rebsd_save $def_rebsd_url
done
}

sum_check(){
echo "start downloading checksum file."
down_sum
while  [ ${#sums} != $def_sum_len ]
do
printf 'There was a problem downloading the sha1sum.\n\033[1;32m%-6s\033[m%s' "-> Do you want to try again [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf "\033[1;33mOk let's try again.\033[0m\n"
count=0&&down_sum
else
printf "Good bye \033[1;33m:(\033[0m\n"
exit 1
fi
done
}

down_check(){
echo "start downloading reBSD core file."
down_core
$def_sum_exec -qc $sums $def_rebsd_save >/dev/null && rm -f $def_rebsd_sums || rm -f $def_rebsd_save
while  [ ! -f $def_rebsd_save ]
do
printf 'There was a problem downloading the reBSD.\n\033[1;32m%-6s\033[m%s' "-> Do you want to try again [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf "\033[1;33mOk let's try again.\033[0m\n"
sum_check && down_core
else
printf "Good bye \033[1;33m:(\033[0m\n"
exit 1
fi
done
}

#########>reBSD-sysprep<#########
is_ipaddr(){
        ip=${1:-1.2.3.4}
        if expr "$ip" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
                IFS=.
                set $ip
                for quad in 1 2 3 4; do
                        if eval [ \$$quad -gt 255 ]; then
                                return 1
                        fi
                done
                return 0
        else
                return 1
        fi
}

is_cidr() {
[ "$1" -eq "$1" 2>/dev/null -o "$1" -eq 0 2>/dev/null ] || return 1
[ "$1" -lt 1 ] || [ "$1" -gt 32 ] && return 1
return 0
}


sysprep(){
def_ssh_port="22"
if [ -f "/etc/ssh/sshd_config" ];then
sys_ssh_port=`grep "Port " /etc/ssh/sshd_config | grep -v "#" | awk '{print $2}'`
if [ ! "$sys_ssh_port" = "" ] && [ "$sys_ssh_port" -ge 10 ] && [ "$sys_ssh_port" -le 65535 ]; then
def_ssh_port=$sys_ssh_port
fi
fi
def_auto_scp="NO"
def_auto_act="None"
def_auto_type="Reboot"
def_auto_dhcp="NO"
def_rootpass="reBSD@123456"
def_dnsname="1.1.1.1"
def_con_nopass="NO"
srv_name="reBSD"
#->network paste,only supports a single eth.
if [ -x "$(command -v ifconfig)" ];then
        def_eth=$(/sbin/route -n get default | /usr/bin/grep 'interface:' | /usr/bin/grep -o '[^ ]*$')
        gateway=$(/sbin/route -n get default | /usr/bin/grep 'gateway:' | /usr/bin/grep -o '[^ ]*$')
        _ipaddr=`/sbin/ifconfig $def_eth | /usr/bin/grep inet | /usr/bin/awk '/broadcast/ {print $2}' `
        _inet_mask=`/sbin/ifconfig $def_eth | /usr/bin/grep inet | /usr/bin/awk '/broadcast/ {print $4}' `
        _netmask=$(/bin/echo $_inet_mask | /usr/bin/sed 's/0x// ; s/../& /g' | /usr/bin/tr [:lower:] [:upper:] | while read B1 B2 B3 B4 ;do                             
/bin/echo "ibase=16;$B1;$B2;$B3;$B4" | /usr/bin/bc | /usr/bin/tr '\n' . | /usr/bin/sed 's/\.$//';done)
        _inet_smask=$(/bin/echo $_netmask | /usr/bin/awk -F. '{print "obase=2;" $1 "*2^24+" $2 "*2^16+" $3 "*2^8+" $4}' | /usr/bin/bc | /usr/bin/awk '{ sub("10*$","1", $0); print length($0); }')
        def_ipaddr="${_ipaddr}/${_inet_smask}"
        def_mac=`ifconfig $def_eth | /usr/bin/grep "ether" | /usr/bin/awk '{print $2}' `
        [ -f /var/run/dhclient/dhclient.${def_eth}.pid ] && def_auto_dhcp="YES" || def_auto_dhcp="NO"
        else
        echo "we can't find \"ifconfig\" command,stop now."
        exit 1;
fi
if [ -f /run/systemd/resolve/resolv.conf ]; then
def_dns=$(grep "nameserver" /run/systemd/resolve/resolv.conf | cut -f2 -d ' ' | tr '\n' ' ')
else
def_dns=$(cat /etc/resolv.conf | grep -i '^nameserver' | head -n1 | cut -d ' ' -f2)
fi
nameservers="${def_dns} ${def_dnsname}"
#->Host name.
printf '\033[1;32m%-6s\033[m%s' "-> Do you want to change the hostname? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf '\033[1;33m%-6s\033[m%s' "-> Enter new hostname: "
read TMP_HN
srv_name=$TMP_HN
printf "reBSD new hostname: \033[1;33m${srv_name}\033[0m\n"
else
printf "reBSD hostname: \033[1;33m${srv_name}\033[0m\n"
fi
#->root password.
printf '\033[1;32m%-6s\033[m%s'  "-> Do you want to change reBSD root password? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf '\033[1;33m%-6s\033[m%s' "-> Enter new reBSD root password: "
read TMP_PW
def_rootpass=$TMP_PW
printf "reBSD new root password: \033[1;33m${def_rootpass}\033[0m\n"
else
printf "reBSD root password: \033[1;33m${def_rootpass}\033[0m\n"
fi
#->SSH services
printf '\033[1;32m%-6s\033[m%s'  "-> Do you want to change SSH port? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf '\033[1;33m%-6s\033[m%s' "-> Enter new SSH Port: "
read TMP_PR
if [ "$TMP_PR" -ge 10 ] && [ "$TMP_PR" -le 65535 ]; then
def_ssh_port=$TMP_PR
printf "reBSD new SSH Port: \033[1;33m${def_ssh_port}\033[0m\n"
else
echo "Not a valid port number, try again!"
printf "\033[1;31mPlease enter a number in the range of [10-65535]\033[0m\n"
exit 1
fi
else
printf "reBSD SSH Port: \033[1;33m${def_ssh_port}\033[0m\n"
fi
#->login protect
printf '\033[1;32m%-6s\033[m%s'  "-> Log in automatically to a console when boots? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
def_con_nopass="YES"
fi
printf "Auto-login as root in console: \033[1;33m${def_con_nopass}\033[0m\n"
#->auto-install
printf '\033[1;36m%-6s\033[m%s'  "-> Do you want run auto-install a system?! [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
echo
printf " \033[1;32m1\033[0m\033[0m) Install FreeBSD       \033[1;32m3\033[0m) Install Linux\n"
printf " \033[1;32m2\033[0m) Install pfSense       \033[1;32m4\033[0m) Install Windows\n"
echo
printf '\033[1;33m%-6s\033[m%s' "-> Please select a system [1,2,3,4]: "
read TMP_SYS
if [ `expr "x$TMP_SYS" : 'x[1234]'` -gt 1 ]; then
case "$TMP_SYS" in
1)
def_auto_scp="Freebsd"
;;
2)
def_auto_scp="pfSense"

def_pf_web_port="65088"
def_pfweb_id="rebsd"
def_pfweb_pw="rebsd@123456"
def_pf_bsd_repos="NO"
#->pf web services
printf '\033[1;32m%-6s\033[m%s'  "-> Do you want to change pfSense Web port? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf '\033[1;33m%-6s\033[m%s' "-> Enter new pfSense Web Port: "
read TMP_PR
if [ "$TMP_PR" -ge 10 ] && [ "$TMP_PR" -le 65535 ]; then
def_pf_web_port=$TMP_PR
printf "pfSense new Web Port: \033[1;33m${def_pf_web_port}\033[0m\n"
else
echo "Not a valid port number, try again!"
printf "\033[1;31mPlease enter a number in the range of [10-65535]\033[0m\n"
exit 1
fi
else
printf "pfSense new Web Port: \033[1;33m${def_pf_web_port}\033[0m\n"
fi
#->pf web id 
printf '\033[1;32m%-6s\033[m%s'  "-> Do you want to change pfSense Web easy-auth Username? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf '\033[1;33m%-6s\033[m%s' "-> Enter easy-auth Username: "
read TMP_PR
def_pfweb_id=$TMP_PR
printf "pfSense Web easy-auth Username: \033[1;33m${def_pfweb_id}\033[0m\n"
else
printf "pfSense Web easy-auth Username: \033[1;33m${def_pfweb_id}\033[0m\n"
fi
#->pf web pw 
printf '\033[1;32m%-6s\033[m%s'  "-> Do you want to change pfSense Web easy-auth Password? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf '\033[1;33m%-6s\033[m%s' "-> Enter easy-auth Password: "
read TMP_PR
def_pfweb_pw=$TMP_PR
printf "pfSense Web easy-auth Password: \033[1;33m${def_pfweb_pw}\033[0m\n"
else
printf "pfSense Web easy-auth Password: \033[1;33m${def_pfweb_pw}\033[0m\n"
fi
#->pf repo 
printf '\033[1;32m%-6s\033[m%s'  "-> Do you want enable FreeBSD repository ? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
def_pf_bsd_repos="YES"
printf "pfSense enable FreeBSD repository: \033[1;33m${def_pf_bsd_repos}\033[0m\n"
else
printf "pfSense enable FreeBSD repository: \033[1;33m${def_pf_bsd_repos}\033[0m\n"
fi

;;
3)
#linux lists
echo
printf " \033[1;33m1\033[0m) Ubuntu(18.04.3)       \033[1;33m3\033[0m) Cenots(8.0)\n"
printf " \033[1;33m2\033[0m) Debian(10.2)          \033[1;33m4\033[0m) Archlinux(201912)\n"
echo
printf '\033[1;33m%-6s\033[m%s' "-> Please select a system [1,2,3,4]: "
read TMP_LX
if [ `expr "x$TMP_LX" : 'x[1234]'` -gt 1 ]; then
case "$TMP_LX" in
1)
def_auto_scp="Ubuntu_18"
;;
2)
def_auto_scp="Debian_12"
;;
3)
def_auto_scp="CentOS_8"
;;
4)
def_auto_scp="Arch_1912"
;;
*)
exit 1
;;
esac
fi
###
;;
4)
#windows lists
echo 
printf  " \033[1;33m1\033[0m) Server-2003R2-Ent     \033[1;33m4\033[0m) Windows-XP-SP3-Pro\n"
printf  " \033[1;33m2\033[0m) Server-2008R2-Std     \033[1;33m5\033[0m) Windows-7-SP1-Pro\n"
printf  " \033[1;33m3\033[0m) Server-2019-Std       \033[1;33m6\033[0m) Windows-10-Work\n"
echo
printf '\033[1;33m%-6s\033[m%s' "-> Please select a system [1,2,3,4]: "
read TMP_WIN
if [ `expr "x$TMP_WIN" : 'x[1234]'` -gt 1 ]; then
case "$TMP_WIN" in
1)
def_auto_scp="Win_2k3"
;;
2)
def_auto_scp="Win_2k8"
;;
3)
def_auto_scp="Win_2k19"
;;
4)
def_auto_scp="Win_xp"
;;
5)
def_auto_scp="Win_7"
;;
6)
def_auto_scp="Win_10"
;;
*)
exit 1
;;
esac
#->rdp services
def_rdp_port="63389"
printf '\033[1;32m%-6s\033[m%s'  "-> Do you want to change RDP port? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf '\033[1;33m%-6s\033[m%s' "-> Enter new RDP Port: "
read TMP_PR
if [ "$TMP_PR" -ge 10 ] && [ "$TMP_PR" -le 65535 ]; then
def_rdp_port=$TMP_PR
printf "Windows new RDP Port: \033[1;33m${def_rdp_port}\033[0m\n"
else
echo "Not a valid port number, try again!"
printf "\033[1;31mPlease enter a number in the range of [10-65535]\033[0m\n"
exit 1
fi
else
printf "Windows RDP Port: \033[1;33m${def_rdp_port}\033[0m\n"
fi

fi
###
;;
*)
exit 1
;;
esac

if [ ! "$def_auto_scp" = "NO" ];then
echo ""
printf  "\033[1;35m-> What I should do immediately after installing ${def_auto_scp} ?\033[0m\n"
echo ""
echo " 1) reboot                2) shutdown"
echo " 3) none *(default)"
echo ""
printf '\033[1;33m%-6s\033[m%s' "-> Please choose an action [1,2]: "
read TMP_ACT
case "$TMP_ACT" in
1)
def_auto_act="reboot"
;;
2)
def_auto_act="shutdown"
;;
esac
fi
fi
fi
#check network wrong.
echo ""
printf "\033[1;35m-> What to do if the reBSD fails to check the network?\033[0m\n"
echo ""
echo " 1) None(Debug mode)"
echo " *) Boot to old system *(default)"
echo ""
printf '\033[1;33m%-6s\033[m%s' "-> Please choose an action [1]: "
read TMP_TYPE
case "$TMP_TYPE" in
1)
def_auto_type="None"
;;
esac
###
#->show config.
printf "Config list:
\033[0;35m---------------------------------------------\033[0m
reBSD hostname: \033[1;33m${srv_name}\033[0m
reBSD internet DHCP Mode: \033[1;33m${def_auto_dhcp}\033[0m
reBSD internet eth: \033[1;33m${def_eth}\033[0m
reBSD internet IP: \033[1;33m${def_ipaddr}\033[0m
reBSD internet MAC: \033[1;33m${def_mac}\033[0m
reBSD internet Gateway: \033[1;33m${gateway}\033[0m
reBSD internet DnsServers: \033[1;33m${nameservers}\033[0m
reBSD root Password: \033[1;33m${def_rootpass}\033[0m
reBSD SSH Port: \033[1;33m${def_ssh_port}\033[0m
Auto-login as root in console: \033[1;33m${def_con_nopass}\033[0m
reBSD auto installer: \033[1;33m${def_auto_scp}\033[0m
"
echo "$def_auto_scp" | grep "Win_" > /dev/null && printf "reBSD auto script RDP Port: \033[1;33m${def_rdp_port}\033[0m"
if echo "$def_auto_scp" | grep "pfSense" > /dev/null ;then
printf "reBSD auto script pfSense Web Port: \033[1;33m${def_pf_web_port}\033[0m
reBSD auto script pfSense Web easy-auth Username: \033[1;33m${def_pfweb_id}\033[0m
reBSD auto script pfSense Web easy-auth Password: \033[1;33m${def_pfweb_pw}\033[0m
reBSD auto script pfSense enable FreeBSD repository: \033[1;33m${def_pf_bsd_repos}\033[0m
"
fi
printf "reBSD auto Complete action: \033[1;33m${def_auto_act}\033[0m
reBSD check network action: \033[1;33m${def_auto_type}\033[0m
\033[0;35m---------------------------------------------\033[0m
"
rebsd_conf=$(echo "set kFreeBSD.rebsd.hostname=\"${srv_name}\"
        set kFreeBSD.rebsd.rootpw=\"${def_rootpass}\"
        set kFreeBSD.rebsd.auto_sshd_port=\"${def_ssh_port}\"
        set kFreeBSD.rebsd.autodhcp=\"${def_auto_dhcp}\"
        set kFreeBSD.rebsd.inet_interfaces=\"eth0\"
        set kFreeBSD.rebsd.mac_interfaces=\"eth0\"
        set kFreeBSD.rebsd.ifconfig_eth0_mac=\"${def_mac}\"
        set kFreeBSD.rebsd.ifconfig_eth0=\"inet ${def_ipaddr}\"
        set kFreeBSD.rebsd.defaultrouter=\"${gateway}\"
        set kFreeBSD.rebsd.nameservers=\"${nameservers}\"
        set kFreeBSD.rebsd.auto_script=\"${def_auto_scp}\"
        set kFreeBSD.rebsd.auto_finish_action=\"${def_auto_act}\"
        set kFreeBSD.rebsd.auto_type=\"${def_auto_type}\"
        set kFreeBSD.rebsd.auto_con_nopass=\"${def_con_nopass}\""
echo "$def_auto_scp" | grep "Win_" > /dev/null && echo "        set kFreeBSD.rebsd.auto_rdpport=\"${def_rdp_port}\""
if echo "$def_auto_scp" | grep "pfSense" > /dev/null ;then
echo "        set kFreeBSD.rebsd.auto_webd_port=\"${def_pf_web_port}\"
        set kFreeBSD.rebsd.auto_pfweb_id=\"${def_pfweb_id}\"
        set kFreeBSD.rebsd.auto_pfweb_pw=\"${def_pfweb_pw}\"
        set kFreeBSD.rebsd.auto_pf_bsd_repos=\"${def_pf_bsd_repos}\""
fi
)
}
#########>GRUB-functions<#########
find_grub_root(){
first=`grep -rin "menuentry 'FreeBSD" "$def_grub_cfg"  | head -n 1 | cut -d ":" -f1 `
text_if=`sed -n "$first,+10p" "$def_grub_cfg" | grep -rin "if" | cut -d ":" -f1`
fix_if=`let text_if-=1` || error "grub_root err."
text_fi=`sed -n "$first,+10p" "$def_grub_cfg" | grep -rin "fi" | cut -d ":" -f1`
fix_fi=`let text_fi-=1` || error "grub_root err."
text_start=`let first+=$fix_if` || error "grub_root err."
text_end=`let first+=$fix_fi` || error "grub_root err."
grub_root="
"
for i in `seq $text_start $text_end`
do
grub_text=`tail -n+$i $def_grub_cfg | head -n 1`
grub_root="${grub_root} ${grub_text}
"
done
}

ToGRUB() {
grub_root="function rebsd_root {"
menuentry_first=`grep -rin "menuentry " "$def_grub_cfg"  | head -n 1 | cut -d ":" -f1 ` || error "grub_root err0."
menuentry_end=`sed -n "$menuentry_first,+100p" "$def_grub_cfg" | grep -in "}"  | head -n 1 | cut -d ":" -f1 `
menuentry_fxend=`expr $menuentry_first + $menuentry_end - 1` || error "grub_root err1."
#find insmod
grub_root="${grub_root}
`awk "NR>=$menuentry_first && NR <=$menuentry_fxend" "$def_grub_cfg" | grep "insmod"`"
#find root
grub_root="${grub_root}
`awk "NR>=$menuentry_first && NR <=$menuentry_fxend" "$def_grub_cfg" | grep "set root"`"
#find set root.
menuentry_root_if=`awk "NR>=$menuentry_first && NR <=$menuentry_fxend" "$def_grub_cfg" | grep -in "set root"  | head -1 | cut -d ":" -f1`
if [ -z $menuentry_root_if ];then
for mnline in `awk "NR>=$menuentry_first && NR <=$menuentry_fxend" "$def_grub_cfg" | grep -in "insmod "  | cut -d ":" -f1`;do
menuentry_root_if=$mnline
done
fi
menuentry_root_fxif=`expr $menuentry_first + $menuentry_root_if` || error "grub_root err2."
menuentry_root_fi=`awk "NR>=$menuentry_root_fxif && NR <=$menuentry_fxend" "$def_grub_cfg" | grep -in "fi"  | head -n 1 | cut -d ":" -f1`
menuentry_root_fxfi=`expr $menuentry_root_fxif + $menuentry_root_fi - 1` || error "grub_root err3."
grub_root="${grub_root}
`awk "NR>=$menuentry_root_fxif && NR <=$menuentry_root_fxfi" "$def_grub_cfg"`
if [ -f \"/reBSD.iso\" ];then 
        set isofile=\"/reBSD.iso\"
       elif [ -f \"/boot/reBSD.iso\" ];then 
        set isofile=\"/boot/reBSD.iso\"
    else
     echo -e \"\nCan't find reBSD core iso file.\"
     sleep -i -v 5
     reboot
       fi
}
"
}

init_grub(){
if [ -z "$ENTRY" ]; then
test -d /sys/firmware/efi/ && echo "efi mode" || echo "bios mode"
#find_grub_root
ToGRUB
cat <<EOF >>$def_grub_custom
$grub_root
menuentry "reBSD" {
        if ! cpuid -l;then
         echo -e "\nYour CPU does not implement AMD64 architecture."
         sleep -i -v 5
         reboot
        fi
        if [ -f "/reBSD.iso" ];then 
         set isofile="/reBSD.iso"
        elif [ -f "/boot/reBSD.iso" ];then 
         set isofile="/boot/reBSD.iso"
        else
         rebsd_root
        fi
        loopback loop \$isofile
        echo  'Loading reBSD form FreeBSD kernel...'
        kfreebsd (loop)/boot/kernel/kernel.gz -v
        kfreebsd_loadenv (loop)/boot/loader.conf
        kfreebsd_module (loop)/boot/kernel/ahci.ko
        kfreebsd_module (loop)/reBSD.gz type=mfs_root
        $rebsd_conf
}
EOF
echo 'Added reBSD custom list.'
fi
if [ -f $def_grub ]; then
sed -i '' 's/^.*RUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' "$def_grub"
sed -i '' 's/^.*RUB_TIMEOUT_STYLE=.*$/GRUB_TIMEOUT_STYLE=menu/g' "$def_grub"
$GRUB_MKCONFIG -o $def_grub_cfg > /dev/null 2>&1 || error "make grub list error!"
[ -f "${def_grub_cfg}.new" ] && error "make grub conf file error!"
$GRUB_REBOOT $def_init_name
else
echo "can't find grub cfg file."
exit 1
fi
}
#########>Main<#########
#->check command
if ! [ -x "$(command -v openssl)" ]; then
echo "we need \"openssl\" this command."
exit
fi
#->check exits
if grep -q 'submenu' ${def_grub_cfg}; then
        ENTRY=$(grep '^menuentry ' ${def_grub_cfg} | grep -n $def_init_name)
else
        ENTRY=$(grep 'menuentry ' ${def_grub_cfg} | grep -n $def_init_name)
fi


if [ ! -z "$ENTRY" ] || grep "reBSD" $def_grub_custom >/dev/null ; then
echo " Ah,reBSD configuration file exists."
printf '\033[1;33m%-6s\033[m%s'  "-> So do we need to reconfigure the reBSD?! [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
echo "got it this, It takes some time though."
cat <<EOF >$def_grub_custom
#!/bin/sh
exec tail -n +3 \$0
EOF
$GRUB_MKCONFIG -o $def_grub_cfg > /dev/null 2>&1  || error "make grub list error!"
[ -f "${def_grub_cfg}.new" ] && error "make grub conf file error!"
ENTRY=
echo "Cleaning is done."
else
##############
if [ -z "`$GRUB_EDITENV list | head -n 1| grep $def_init_name | cut -d "=" -f2 `" ] ;then
printf '\033[1;33m%-6s\033[m%s'  "-> as well as RebSD Add to next-boot? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
#########
printf "\033[1;34mwe Need to check reBSD files once.\033[0m\n"
if [ -f $def_rebsd_save ]; then
sum_check
$def_sum_exec -qc $sums $def_rebsd_save >/dev/null && rm -f $def_rebsd_sums || rm -f $def_rebsd_save
#>
if [ ! -f $def_rebsd_save ]; then
sum_check && down_check
fi
fi
#########
$GRUB_REBOOT $def_init_name
printf "\033[1;35mNow you can boot to the reBSD system.\033[0m\n"
echo ""
printf '\033[1;31m%-6s\033[m%s'  "-> Do you want to reboot now?! [y/N]: "
read TMP_YN
[ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ] && reboot
echo
fi
fi
##############
echo "Have a good day!"
exit 1
fi
fi
#->config reBSD
sysprep
printf "\033[1;34mPlease check the configuration before proceeding\033[0m\n"
printf '\033[1;32m%-6s\033[m%s'  "-> So, shall we continue? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -lt 1 ]; then
exit 0
fi
#->download reBSD
echo "check internet ..."
check_internet="bing.com"
if nc -Ndzw3 $check_internet 443 >/dev/null 2>&1 && echo | usropenssl s_client -connect $check_internet:443 2>&1 |awk '
    handshake && $1 == "Verification" { if ($2=="OK") exit; exit 1 }
$1 $2 == "SSLhandshake" { handshake = 1 }'
then
##############
if [ -f $def_rebsd_save ]; then
sum_check
$def_sum_exec -qc $sums $def_rebsd_save >/dev/null && rm -f $def_rebsd_sums || rm -f $def_rebsd_save
#>
fi

if [ ! -f $def_rebsd_save ]; then
sum_check && down_check
fi
##############
else
echo "we need internet to config the reBSD system."
exit 1
fi
#->initial reBSD
init_grub
#->last
echo "reBSD config finish."
printf "\033[1;35mNow you can boot to the reBSD system.\033[0m\n"
echo ""
printf '\033[1;31m%-6s\033[m%s'  "-> Do you want to reboot now?! [y/N]: "
read TMP_YN
[ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ] && reboot
echo
#->reBSD init scripts done.
exit 0