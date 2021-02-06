#!/bin/sh
# ----------------------------------------------------------------
# reBSD initial script for ubuntu version >= 18 
# reBSD.nore.net @FS 2019/12/12
# Do not change anything here until you know what you are doing
# ----------------------------------------------------------------
#########>Script-configuration<#########
def_init_name="reBSD"
def_rebsd_url="http://rebsd.nore.net/reBSD/Files/iso/reBSD-latest-RELEASE-amd64.iso"
def_rebsd_sum="http://rebsd.nore.net/reBSD/Files/iso/reBSD-latest-RELEASE-amd64.iso.sha1"
def_rebsd_save="/boot/reBSD.iso"
def_rebsd_sums="/tmp/reBSD.sum"
def_sum_exec="sha1sum"
def_sum_len=42
def_grub="/etc/default/grub"
def_grub_cfg="/boot/grub/grub.cfg"
def_grub_custom="/etc/grub.d/40_custom"
#########>Download-functions<#########
down_sum(){
count=0 && sums=0
wget --no-check-certificate $def_rebsd_sum -qO $def_rebsd_sums && sums=`cat $def_rebsd_sums`
while [ "$?" != 0 ] | [ ${#sums} != $def_sum_len ] && [ "$count" -lt 3 ]
do
        echo "Error downloading checksum. try again"
        sleep 2
        count=$((count+1))
        wget --no-check-certificate $def_rebsd_sum -qO $def_rebsd_sums && sums=`cat $def_rebsd_sums`
done
}
down_core(){
count=0
wget --no-check-certificate $def_rebsd_url --show-progress -qO- | tee $def_rebsd_save | $def_sum_exec -c $def_rebsd_sums && rm -f $def_rebsd_sums || rm -f $def_rebsd_save
while [ "$?" != 0 ] | [ ! -f $def_rebsd_save ] && [ "$count" -lt 1 ]
do
        echo "Error downloading reBSD file. try again"
        sleep 3
        count=$((count+1))
        wget --no-check-certificate $def_rebsd_url --show-progress -qO- | tee $def_rebsd_save | $def_sum_exec -c $def_rebsd_sums && rm -f $def_rebsd_sums && break || rm -f $def_rebsd_save
done
}
sum_check(){
echo "start downloading checksum file."
down_sum
while  [ ${#sums} != $def_sum_len ]
do
printf 'There was a problem downloading the sha1sum.\n\e[1;32m%-6s\e[m%s' "-> Do you want to try again [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
echo "\033[1;38mOk let's try again.\033[0m"
count=0&&down_sum
else
echo "Good bye \033[1;38m:(\033[0m"
exit 1
fi
done
}
down_check(){
echo "start downloading reBSD core file."
down_core 
while  [ ! -f $def_rebsd_save ]
do
printf 'There was a problem downloading the reBSD.\n\e[1;32m%-6s\e[m%s' "-> Do you want to try again [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
echo "\033[1;38mOk let's try again.\033[0m"
sum_check && down_core
else
echo "Good bye \033[1;38m:(\033[0m"
exit 1
fi
done
}
#########>reBSD-sysprep<#########
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
srv_name="reBSD"
#->network paste,only supports a single eth.
if [ -x "$(command -v ip)" ]; then
echo '"ip" command available.'
def_dhcp=$(ip r l 0/0 | head -n 1 | cut -f7 -d' ')
[ "$def_dhcp" = "dhcp" ] && def_auto_dhcp="YES"
def_eth=$(ip r l 0/0 | head -n 1 | cut -f5 -d' ' | tr "[A-Z]" "[a-z]")
gateway=$(ip r l 0/0 | head -n 1 | cut -f3 -d' ')
#->static or dhcp
def_ipaddr=$(ip -o -f inet addr show $def_eth | cut -f7 -d' ')
def_mac=$(ip link show $def_eth | grep link/ether |  cut -f6 -d' ' | tr "[A-Z]" "[a-z]")
else
echo "we can't find \"ip\" command,stop now."
exit 1;
fi
if [ -f /run/systemd/resolve/resolv.conf ]; then
def_dns=$(grep "nameserver" /run/systemd/resolve/resolv.conf | cut -f2 -d ' ' | tr '\n' ' ')
else
def_dns=$(grep "nameserver" /etc/resolv.conf | cut -f2 -d ' ')
fi
nameservers="${def_dns}${def_dnsname}"
#->Host name.
printf '\e[1;32m%-6s\e[m%s' "-> Do you want to change the hostname? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf '\e[1;38m%-6s\e[m%s' "-> Enter new hostname: "
read TMP_HN
srv_name=$TMP_HN
echo "reBSD new hostname: \033[1;38m${srv_name}\033[0m"
else
echo "reBSD hostname: \033[1;38m${srv_name}\033[0m"
fi
#->root password.
printf '\e[1;32m%-6s\e[m%s'  "-> Do you want to change reBSD root password? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf '\e[1;38m%-6s\e[m%s' "-> Enter new reBSD root password: "
read TMP_PW
def_rootpass=$TMP_PW
echo "reBSD new root password: \033[1;38m${def_rootpass}\033[0m"
else
echo "reBSD root password: \033[1;38m${def_rootpass}\033[0m"
fi
#->SSH services
printf '\e[1;32m%-6s\e[m%s'  "-> Do you want to change SSH port? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
printf '\e[1;38m%-6s\e[m%s' "-> Enter new SSH Port: "
read TMP_PR
if [ "$TMP_PR" -ge 10 ] && [ "$TMP_PR" -le 65535 ]; then
def_ssh_port=$TMP_PR
echo "reBSD new SSH Port: \033[1;38m${def_ssh_port}\033[0m"
else
echo "Not a valid port number, try again!"
echo "\033[1;31mPlease enter a number in the range of [10-65535]\033[0m"
exit 1
fi
else
echo "reBSD SSH Port: \033[1;38m${def_ssh_port}\033[0m"
fi
#->auto-install
printf '\e[1;36m%-6s\e[m%s'  "-> Do you want run auto-install a system?! [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
echo ""
echo " 1) Install FreeBSD       2) Install pfSense"
echo " 3) Install Linux         4) Install Windows"
echo ""
printf '\e[1;38m%-6s\e[m%s' "-> Please select a system [1,2,3,4]: "
read TMP_SYS
if [ `expr "x$TMP_SYS" : 'x[1234]'` -gt 1 ]; then
case "$TMP_SYS" in
1)
def_auto_scp="Freebsd"
;;
2)
def_auto_scp="pfSense"
;;
3)
#linux lists
echo ""
echo " 1) Ubuntu(18.04.3)            2) Debian(10.2)"
echo " 3) Cenots(8.0)                4) Archlinux(201912)"
echo ""
printf '\e[1;38m%-6s\e[m%s' "-> Please select a system [1,2,3,4]: "
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
echo ""
echo -e " 1) Server-2003-R2(X86-Ent)    2) Server-2008-R2(X64-Std)"
echo -e " 3) Server-2019-1809(X64-Std)  4) Windows-XP-SP3(X86-Pro)"
echo -e " 5) Windows-7-SP1(X64-Pro)     6) Windows-10-1909(X64-Work)"
echo ""
printf '\e[1;38m%-6s\e[m%s' "-> Please select a system [1,2,3,4]: "
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
fi
###
;;
*)
exit 1
;;
esac

if [ ! "$def_auto_scp" = "NO" ];then
echo ""
echo  "\033[1;35m-> What I should do immediately after installing ${def_auto_scp} ?\033[0m"
echo ""
echo " 1) reboot                2) shutdown"
echo " 3) none *(default)"
echo ""
printf '\e[1;38m%-6s\e[m%s' "-> Please choose an action [1,2]: "
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
echo  "\033[1;35m-> What to do if the reBSD fails to check the network?\033[0m"
echo ""
echo " 1) None(Debug mode.)"
echo " *) Boot to old system *(default)"
echo ""
printf '\e[1;38m%-6s\e[m%s' "-> Please choose an action [1]: "
read TMP_TYPE
case "$TMP_TYPE" in
1)
def_auto_type="None"
;;
esac
###
#->show config.
echo "Config list:
---------------------------------------------
reBSD hostname: ${srv_name}
reBSD internet DHCP Mode: ${def_auto_dhcp}
reBSD internet eth: ${def_eth}
reBSD internet IP: ${def_ipaddr}
reBSD internet MAC: ${def_mac}
reBSD internet Gateway: ${gateway}
reBSD internet DnsServers: ${nameservers}
reBSD root Password: ${def_rootpass}
reBSD SSH Port: ${def_ssh_port}
reBSD auto installer: ${def_auto_scp}
reBSD auto Complete action: ${def_auto_act}
reBSD check network action: ${def_auto_type}
---------------------------------------------"
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
")
}
#########>GRUB-functions<#########
ToGRUB()
{
        GRUB_Partition=$(echo $1 | cut -c 9)
        case $(echo -n $1 | cut -c 8) in
                a)GRUB_Disk="hd0";;
                b)GRUB_Disk="hd1";;
                c)GRUB_Disk="hd2";;
                d)GRUB_Disk="hd3";;
                e)GRUB_Disk="hd4";;
                f)GRUB_Disk="hd5";;
                g)GRUB_Disk="hd6";;
                h)GRUB_Disk="hd7";;
                i)GRUB_Disk="hd8";;
                j)GRUB_Disk="hd9";;
                *)GRUB_Disk="unknow";;
        esac
}

init_grub(){
if [ -z "$ENTRY" ]; then
test -d /sys/firmware/efi/ && echo "efi mode" || echo "bios mode"
sysdisk=`df /boot | grep -Eo '/dev/[^ ]+'`
ToGRUB $sysdisk
if [ "$GRUB_Disk" = "unknow" ];then
echo "Can't find Partition."
else
grub_plus="(${GRUB_Disk},${GRUB_Partition})"
fi
sudo cat <<EOF >>$def_grub_custom
menuentry "reBSD" {
        set root=$grub_plus
        if [ -f "/boot/reBSD.iso" ];then 
        set isofile="/boot/reBSD.iso"
        else
        set isofile="/reBSD.iso"
        fi
        loopback loop \$isofile
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
sed -i 's/^.*RUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' "$def_grub"
sed -i 's/^.*RUB_TIMEOUT_STYLE=.*$/GRUB_TIMEOUT_STYLE=menu/g' "$def_grub"
sudo grub-mkconfig -o $def_grub_cfg > /dev/null 2>&1
sudo grub-reboot $def_init_name
else
echo "can't find grub cfg file."
exit 1
fi
}
#########>Main<#########
#->check command
if ! [ -x "$(command -v wget)" ]; then
echo "we need \"wget\" or \"curl\" command."
echo "Maybe you can try use the command \"sudo apt-get install wget\""
exit
fi
if ! [ -x "$(command -v openssl)" ]; then
echo "we need \"openssl\" this command."
exit
fi
#->check exits
if grep -q 'submenu' ${def_grub_cfg}; then
        ENTRY=$(grep '^menuentry ' ${def_grub_cfg} | grep -n $def_init_name | cut -f1 -d:)
else
        ENTRY=$(($(grep 'menuentry ' ${def_grub_cfg} | grep -n $def_init_name | cut -f1 -d:)-1))
fi

if [ ! -z "$ENTRY" ]; then
echo " Ah,reBSD configuration file exists."
printf '\e[1;33m%-6s\e[m%s'  "-> So do we need to reconfigure the reBSD?! [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
echo "got it this, It takes some time though."
sudo cat <<EOF >$def_grub_custom
#!/bin/sh
exec tail -n +3 \$0
EOF
sudo grub-mkconfig -o $def_grub_cfg > /dev/null 2>&1
ENTRY=
echo "Cleaning is done."
else
##############
if [ ! $(grub-editenv list | grep $def_init_name | cut -d "=" -f2) ];then
printf '\e[1;33m%-6s\e[m%s'  "-> as well as RebSD Add to next-boot? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
#########
echo  "\033[1;34mwe Need to check reBSD files once.\033[0m"
if [ -f $def_rebsd_save ]; then
sum_check
echo "`cat $def_rebsd_sums | awk '{print $1}'` ${def_rebsd_save}" | $def_sum_exec -c  && rm -f $def_rebsd_sums || rm -f $def_rebsd_save
#>
if [ ! -f $def_rebsd_save ]; then
sum_check && down_check
fi
fi
#########
sudo grub-reboot $def_init_name
echo  "\033[1;35mNow you can boot to the reBSD system.\033[0m"
echo ""
printf '\e[1;31m%-6s\e[m%s'  "-> Do you want to reboot now?! [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
sudo reboot
fi
fi
fi
##############
echo "Have a good day!"
exit 1
fi
fi
#->config reBSD
sysprep
echo "\033[1;38mPlease check the configuration before proceeding\033[0m"
printf '\e[1;32m%-6s\e[m%s'  "-> So, shall we continue? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -lt 1 ]; then
exit 0
fi
#->download reBSD
echo "check internet ..."
check_internet="bing.com"
if nc -Ndzw3 $check_internet 443 >/dev/null 2>&1 && echo |openssl s_client -connect $check_internet:443 2>&1 |awk '
        handshake && $1 == "Verification" { if ($2=="OK") exit; exit 1 }
$1 $2 == "SSLhandshake" { handshake = 1 }'
then
##############
if [ -f $def_rebsd_save ]; then
sum_check
echo "`cat $def_rebsd_sums | awk '{print $1}'` ${def_rebsd_save}" | $def_sum_exec -c  && rm -f $def_rebsd_sums || rm -f $def_rebsd_save
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
echo  "\033[1;35mNow you can boot to the reBSD system.\033[0m"
echo ""
printf '\e[1;31m%-6s\e[m%s'  "-> Do you want to reboot now?! [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
sudo reboot
fi
#->reBSD init scripts done.
exit 0