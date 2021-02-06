#!/bin/sh
# ----------------------------------------------------------------
# reBSD initial script for Linux kernel > 2.6x
# reBSD.nore.net @FS 2020/02/02
# Do not change anything here until you know what you are doing.
# ----------------------------------------------------------------
HOME=/
PATH=/sbin:/bin/:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export HOME PATH
error(){
echo "[ERR]: ${1}"
exit 1
}
test -d /sys/firmware/efi/ && error "the Loader does not support UEFI."
dmesg | grep -Fq "EFI v" && error "the Loader does not support UEFI."
#########>Script-configuration<#########
def_init_name="reBSD"
def_rebsd_url="http://rebsd.nore.net/reBSD/Files/iso/reBSD-latest-RELEASE-amd64.iso"
def_rebsd_sum="http://rebsd.nore.net/reBSD/Files/iso/reBSD-latest-RELEASE-amd64.iso.sha1"
def_rebsd_save="/boot/reBSD.iso"
def_rebsd_sums="/tmp/reBSD.sum"
def_sum_exec=`command -v sha1sum`
def_sum_len=43
def_grub_cfg="/boot/grub/grub.cfg"
def_grub=""
def_grub_custom=""
GRUB_REBOOT=`command -v grub-reboot`
GRUB_MKCONFIG=`command -v grub-mkconfig`
GRUB_EDITENV=`command -v grub-editenv`
[ -x "$(command -v sudo)" ] && SUDO=`command -v sudo`
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
[ -x "$(command -v lsb_release)" ] && _DISTRIB="\`lsb_release -i -s 2> /dev/null || echo Debian\`"|| _DISTRIB="\`cat /etc/centos-release 2> /dev/null | awk '{print \$1}' || echo RedHat\`"
$SUDO cat > $def_grub <<EOF
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=3
GRUB_DISTRIBUTOR=$_DISTRIB
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
EOF
fi
#########>Download-functions<#########
down_sum(){
count=0 && sums=0
$SUDO wget --no-check-certificate $def_rebsd_sum -qO $def_rebsd_sums && sums=`cat $def_rebsd_sums`
while [ "$?" != 0 ] | [ ${#sums} != $def_sum_len ] && [ "$count" -lt 3 ]
do
        echo "Error downloading checksum. try again"
        sleep 2
        count=$((count+1))
        $SUDO wget --no-check-certificate $def_rebsd_sum -qO $def_rebsd_sums && sums=`cat $def_rebsd_sums`
done
}
down_core(){
count=0
# set progress option accordingly
wget --help | grep -q '\--show-progress' && _PROGRESS_OPT="--show-progress -qO-" || _PROGRESS_OPT="-qO-"

$SUDO wget --no-check-certificate $def_rebsd_url $_PROGRESS_OPT | $SUDO tee $def_rebsd_save | $def_sum_exec -c $def_rebsd_sums && rm -f $def_rebsd_sums || $SUDO rm -f $def_rebsd_save
while [ "$?" != 0 ] | [ ! -f $def_rebsd_save ] && [ "$count" -lt 1 ]
do
        echo "Error downloading reBSD file. try again"
        sleep 3
        count=$((count+1))
       $SUDO wget --no-check-certificate $def_rebsd_url $_PROGRESS_OPT | $SUDO tee $def_rebsd_save | $def_sum_exec -c $def_rebsd_sums && rm -f $def_rebsd_sums && break || $SUDO rm -f $def_rebsd_save
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

get_dhcp(){
#for ubuntu > 18
for _dhcp in `ip r l 0/0`; do
[ "$_dhcp" = "static" ] && return 1
[ "$_dhcp" = "dhcp" ] && return 0
done
#other linux :(
_eth="$1"
_gateway="${2};"
lease=""
find_route="option routers "
find_ip="fixed-address "
if [ -s "/var/lib/dhcp/dhclient.${_eth}.leases" ]; then
        lease="/var/lib/dhcp/dhclient.${_eth}.leases"
elif [ -s /var/lib/dhcp/dhclient.leases ]; then
        lease="/var/lib/dhcp/dhclient.leases"
elif [ -s "/var/lib/dhcpd/dhclient.${_eth}.leases" ]; then
        lease="/var/lib/dhcpd/dhclient.${_eth}.leases"
elif [ -s /var/lib/dhcpd/dhclient.leases ]; then
        lease="/var/lib/dhcpd/dhclient.leases"
elif [ -s "/var/lib/dhcp3/dhclient.${_eth}.leases"  ]; then
        lease="/var/lib/dhcp3/dhclient.${_eth}.leases"
elif [ -s /var/lib/dhcp3/dhclient.leases ]; then
        lease="/var/lib/dhcp3/dhclient.leases"
elif [ -s "/var/lib/dhclient/dhclient.${_eth}.leases" ]; then
        lease="/var/lib/dhclient/dhclient.${_eth}.leases"
elif [ -s /var/lib/dhclient/dhclient.leases ]; then
        lease="/var/lib/dhclient/dhclient.leases"
else
        #:( sorry, we can't use the dhclient command to check DHCP, because of some VPS or cloud instance DHCP service only for test.
        return 2
fi

_route=$(grep "$find_route" "$lease" | tail -1 | awk '{print $NF}')
_ips=$(grep "$find_ip" "$lease" | tail -1 | awk '{print $NF}')

for _ip in $def_ipaddr; do
_dip="`echo "$_ip" | cut -f1 -d'/'`;"
if [ "$_dip" = "$_ips" ] && [ "$_gateway" = "$_route"  ];then
return 0
fi
done
return 1
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
if [ -x "$(command -v ip)" ];then
        def_eth=$(ip r l 0/0 | head -n 1 | awk '{print $5}' | tr "[A-Z]" "[a-z]")
        gateway=$(ip r l 0/0 | head -n 1 | awk '{print $3}')
        def_ipaddr=$(ip -o -f inet addr show $def_eth | awk '{print $4}')
        if [ -s "/sys/class/net/${def_eth}/address" ];then
                def_mac=`cat "/sys/class/net/${def_eth}/address" | tail -1 | tr "[A-Z]" "[a-z]"`
        else
                def_mac=$(ip link show $def_eth | grep link/ether | awk '{print $2}' | tr "[A-Z]" "[a-z]")
        fi
        get_dhcp $def_eth $gateway $def_ipaddr && def_auto_dhcp="YES" || def_auto_dhcp="NO"
else
        echo "we can't find \"ip\" command,stop now."
        exit 1;
fi

if [ -f /run/systemd/resolve/resolv.conf ]; then
def_dns=$(grep "nameserver" /run/systemd/resolve/resolv.conf | cut -f2 -d ' ' | tr '\n' ' ')
else
def_dns=$(grep "nameserver" /etc/resolv.conf | awk '{print $2" "}')
fi
nameservers="${def_dns}${def_dnsname}"
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
else
echo "Not a valid port number, try again!"
printf "\033[1;31mPlease enter a number in the range of [10-65535]\033[0m\n"
exit 1
fi
fi
printf "pfSense Web Port: \033[1;33m${def_pf_web_port}\033[0m\n"
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
ToGRUB() {
grub_root="function rebsd_root {
load_video"
menuentry_first=`grep -rin "menuentry " "$def_grub_cfg"  | head -n 1 | cut -d ":" -f1 `|| error "grub_root err0."
menuentry_end=`sed -n "$menuentry_first, +100p" "$def_grub_cfg" | grep -in "}"  | head -n 1 | cut -d ":" -f1 `
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
menuentry_root_fxif1=`expr $menuentry_first + $menuentry_root_if` || error "grub_root err2."
menuentry_root_fxif2=`awk "NR>=$menuentry_root_fxif1 && NR <=$menuentry_fxend" "$def_grub_cfg" | grep -in "if "  | head -n 1 | cut -d ":" -f1`
menuentry_root_fxif=`expr $menuentry_root_fxif1 + $menuentry_root_fxif2 - 1` || error "grub_root err3."
menuentry_root_fi=`awk "NR>=$menuentry_root_fxif && NR <=$menuentry_fxend" "$def_grub_cfg" | grep -win "fi"  | head -n 1 | cut -d ":" -f1`
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
ToGRUB 
$SUDO cat <<EOF >>$def_grub_custom
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
        echo  'Loading reBSD form Linux kernel...'
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
$SUDO sed -i 's/^.*RUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' "$def_grub"
$SUDO sed -i 's/^.*RUB_TIMEOUT_STYLE=.*$/GRUB_TIMEOUT_STYLE=menu/g' "$def_grub"
$SUDO $GRUB_MKCONFIG -o $def_grub_cfg > /dev/null 2>&1 || error "grub mkconfig error."
[ -f "${def_grub_cfg}.new" ] && error "make grub conf file error!"
$SUDO $GRUB_REBOOT $def_init_name
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
$SUDO cat <<EOF >$def_grub_custom
#!/bin/sh
exec tail -n +3 \$0
EOF
$SUDO $GRUB_MKCONFIG -o $def_grub_cfg > /dev/null 2>&1 || error "grub mkconfig error."
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
echo "`cat $def_rebsd_sums | awk '{print $1}'`  ${def_rebsd_save}" | $def_sum_exec -c  && rm -f $def_rebsd_sums || rm -f $def_rebsd_save
#>
if [ ! -f $def_rebsd_save ]; then
sum_check && down_check
fi
fi
#########
$SUDO $GRUB_REBOOT $def_init_name
printf "\033[1;35mNow you can boot to the reBSD system.\033[0m\n"
echo ""
printf '\033[1;31m%-6s\033[m%s'  "-> Do you want to reboot now?! [y/N]: "
read TMP_YN
[ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ] && $SUDO reboot
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
if nc -zw3 $check_internet 443 >/dev/null 2>&1 && echo |openssl s_client -connect $check_internet:443 2>&1 |awk '
        handshake && $1 == "Verification" { if ($2=="OK") exit; exit 1 }
$1 $2 == "SSLhandshake" { handshake = 1 }'
then
##############
if [ -f $def_rebsd_save ]; then
sum_check
echo "`cat $def_rebsd_sums | awk '{print $1}'`  ${def_rebsd_save}" | $def_sum_exec -c  && rm -f $def_rebsd_sums || rm -f $def_rebsd_save
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
[ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ] && $SUDO reboot
echo
#->reBSD init scripts done.
exit 0