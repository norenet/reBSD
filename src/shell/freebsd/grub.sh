#!/bin/sh
# ----------------
# reBSD grub init for FreeBSD
# rebsd.nore.net @FS 2020/02/04
# ----------------
#mkdir -p /boot/grub
#sysctl kern.geom.debugflags = 16
#https://forums.freebsd.org/threads/how-to-install-grub2-on-freebsd.28443/
#awk '{if($2=="/"){print $1}}' /etc/fstab  | awk '/^\/dev/ {print $1}'
#dmesg | grep "mount root"
#glabel status
#sysctl kern.disks
#/dev/da0s1a
#sha1
#https://forums.freebsd.org/threads/sha1sum-c.22509/
PATH=/sbin:/bin/:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

kenv -q rebsd.dist_mirror="http://local.nore.net" >/dev/null

mirror=`kenv -q rebsd.dist_mirror`
grub_pkg="/tmp/grub2-2.00_14.txz"
grub_name="grub2"

find_root(){
mount=`awk '{if($2=="/"){print $1}}' /etc/fstab | sed 's/\/dev\///g'`
for disk in `sysctl -n kern.disks`;do
if echo $mount | grep -e "$disk" >/dev/null ;then
root_disk=$disk
return 0
fi
return 1
done
}

inst_pkg(){
if ! pkg info $grub_name 2>/dev/null >/dev/null ;then
if [ ! -f "$grub_pkg" ];then
echo "Downloading grub2..."
fetch --timeout=60 --no-verify-hostname --no-verify-peer "${mirror}/Base/reBSD/pkg/grub2-2.00_14.txz" -qo "$grub_pkg" 2>&1
	if [ $? -ne 0 ];then
		echo -e "\033[1;31mDownload grub2 failed,Please try again.\033[0m"
		return 1
	fi
fi
echo "Install dependencies..."
for pkginfo in `pkg info -dqeF $grub_pkg`;do
pkg install -qy $pkginfo
done
pkg add -q $grub_pkg
return $?
fi
return 0
}

init_grub(){
mkdir -p /boot/grub
cp -Rpf /usr/local/lib/grub/i386-pc /boot/grub
$GRUB_INSTALL "/dev/${1}"
$GRUB_MKCONFIG -o "/boot/grub/grub.cfg"
}


error(){
echo "[ERR]:${1}"
exit 1
}


if find_root && inst_pkg ;then
GRUB_INSTALL=`which grub-install`  || error "Missing grub-install"
GRUB_MKCONFIG=`which grub-mkconfig` || error "Missing grub-mkconfig"
GRUB_REBOOT=`which grub-reboot` || error "Missing grub-reboot"
GRUB_MKCONFIG=`which grub-mkconfig` || error "Missing grub-mkconfig"
GRUB_EDITENV=`which grub-editenv` || error "Missing grub-editenv"
init_grub $root_disk 
fi



#cp-Rf /usr/local/lib/grub/i386-pc /boot/grub
#grub-install $bdisk
#grub-mkconfig -o /boot/grub/grub.cfg