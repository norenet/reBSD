#!/bin/sh
# ----------------
# reBSD based initial script
# reBSD.nore.net @FS 2019/12/07
# ----------------

centos(){
ver=$(echo $distro | cut -f3 -d' ')
if [ "$ver" \> "7" ];then
echo "Sorry,only suport Centos 6 now."
exit 1
fi
if [ -x "$(command -v grub-mkconfig)" ]; then
echo "update is date." 
exit 0
else
printf '\033[1;32m%-6s\e[m%s' "-> Do you want auto upgrade grub to v2.0? [y/N]: "
read TMP_YN
if [ `expr "x$TMP_YN" : 'x[Yy]'` -gt 1 ]; then
[ -x "$(command -v sudo)" ] && SUDO=`which sudo`

$SUDO yum -y install bison gcc gettext binutils ncurses libusb SDL flex fuse-devel freetype-devel device-mapper-devel nc xz
$SUDO yum -y update glibc
wget -c http://ftp.gnu.org/gnu/grub/grub-2.00.tar.gz -O /tmp/grub-2.00.tar.gz
pushd /tmp/
tar -xzvf grub-2.00.tar.gz
pushd /tmp/grub-2.00
#$SUDO ./configure
$SUDO rpm -e grub
$SUDO ./configure --sbindir=/sbin --prefix=/usr
#./configure --sbindir=/sbin --prefix=/usr --target=x86_64
$SUDO make && make install
if [ "$?" != 0 ]; then
echo "Build Grub error."
exit 1
fi
$SUDO ldconfig
pushd /
$SUDO rm -rf /tmp/grub-2.00
#if [ ! -f /boot/grub/video.lst ];then
#$SUDO cat > /boot/grub/video.lst <<EOF
#vbe
#vga
#video_bochs
#video_cirrus
#EOF
#fi
script="/tmp/reBSD.sh"
bdisk=$(df /boot | grep -Eo '/dev/[^ ]+'|sed 's/[0-9]//g')
$SUDO grub-install $bdisk
echo "Get grub core based on reBSD."
wget --no-check-certificate "http://rebsd.nore.net/reBSD/Base/reBSD/Mods/grub2.txz" -qO- | tar  -xJ -C / -f - 
while [ "$?" != 0 ] 
do
echo "download error,try again.."
sleep 3
wget --no-check-certificate "http://rebsd.nore.net/reBSD/Base/reBSD/Mods/grub2.txz" -qO- | tar  -xJ -C / -f - 
done
$SUDO grub-mkconfig -o /boot/grub/grub.cfg
$SUDO mv -v /boot/grub/grub.conf /boot/
echo "Grub upgrade finsh,please try again."
echo "Start download reBSD loader shell for ${distro}."
url="http://rebsd.nore.net/reBSD/Files/shell/linux/generic.sh"
wget --no-check-certificate $url -qO $script
if [ "$?" != 0 ]; then
echo "Error downloading: ${url}"
exit 1
else
echo "Saved to ${script}"
fi
$SUDO chmod +x $script
$SUDO $script
fi
fi
}

linux(){
echo $distro
case "$distro" in
	*CentOS*)  centos;;
*) echo "Sorry.reBSD cannot currently work on ${distro}";exit 1;;
esac
}

system="$(uname -s)"
case "${system}" in
Linux*)
if type lsb_release >/dev/null 2>&1 ; then
   distro=$(lsb_release -d -s)
elif [ -e /etc/os-release ] ; then
   distro=$(awk -F= '$1 == "PRETTY_NAME" {print $2}' /etc/os-release)
elif [ -e /etc/system-release ] ; then
   distro=$(cat /etc/system-release)
elif [ -e /etc/redhat-release ] ; then
   distro=$(cat /etc/redhat-release)
elif [ -e /etc/centos-release ] ; then
   distro=$(cat /etc/centos-release)
fi
linux
;;
*) echo "Sorry.reBSD cannot currently work on ${system}!";exit 1;;
esac