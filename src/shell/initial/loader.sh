#!/bin/sh
# ----------------
# reBSD based loader script.
# reBSD.nore.net @FS 2020/02/02
# ----------------
linux(){
if [ -s /boot/grub/grub.cfg ] && [ -x "$(command -v grub-mkconfig)" ] && [ -x "$(command -v grub-reboot)" ] && [ -x "$(command -v grub-editenv)" ]; then
if [ -x "$(command -v ip)" ]  && [ -x "$(command -v nc)" ] && [ -x "$(command -v openssl)" ] && [ -x "$(command -v sha1sum)" ] ;then
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
else
echo "Requires \"ip\" ,\"nc\" , \"openssl\" commands"
echo "exit 1">$script
$SUDO chmod +x $script
fi
else
echo "Please upgrade grub version to 1.x"
echo "Start download reBSD loader shell for ${distro}."
url="http://rebsd.nore.net/reBSD/Files/shell/linux/grub.sh"
wget --no-check-certificate $url -qO $script
if [ "$?" != 0 ]; then
echo "Error downloading: ${url}"
exit 1
else
echo "Saved to ${script}"
fi
$SUDO chmod +x $script
if [ "$?" != 0 ]; then
echo "Error upgrade grub"
exit 1
fi
fi
}

freebsd(){
echo "Start download reBSD loader shell for ${distro}."
url="http://rebsd.nore.net/reBSD/Files/shell/freebsd/generic.sh"
fetch --timeout=60 --no-verify-hostname --no-verify-peer $url -qo $script
if [ "$?" != 0 ]; then
echo "Error downloading: ${url}"
exit 1
else
echo "Saved to ${script}"
fi
$SUDO chmod +x $script
}

script="/tmp/reBSD.sh"
system="$(uname -s)"
[ -x "$(command -v sudo)" ] && SUDO=`which sudo`
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
FreeBSD*)
distro=`uname -sr`
freebsd
;;
*) echo "Sorry.reBSD cannot currently work on ${system}!";exit 1;;
esac