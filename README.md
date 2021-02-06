## **Language**
 - [**简体中文**](https://github.com/norenet/reBSD/blob/master/Chinese.md)

## **What is reBSD?**
 - reBSD is a mini operating system based on FreeBSD's custom kernel. It is mainly used to maintain cloud instances/VPS based on KVM or XEN.
 - It is mainly used to maintain some of my VPS. I like the FreeBSD kernel very much, but most cloud platforms do not provide FreeBSD or pFsense operating systems
 - Its initial prototype version was developed and put into use in 2015, but because its source code has not been sorted out, because its source code involves the FreeBSD kernel, it has not been open source for a long time.
 - Currently reBSD does not support third-party scripts. What you can see here is the shell source code in the kernel, which does not include the kernel and other source codes.

**Features?**
 1. Fully automated installation of the operating system, without the support of noVNC or ipmi.
 2. Visual operating system installation process
 3. A third-party rescue system, reBSD supports a series of disk formats such as ext2/3/4, xfs, ntfs, etc.
 4. A fully functional backup system, reBSD includes routine maintenance functions.

**Requirement**
 1. Disk: 20Mb
 2. Memory: 32Mb
 3. Installing FreeBSD/pFsense requires> 256Mb of RAM
 4. Installing Linux/Windows requires> 512Mb of RAM

**Auto-installed operating system?**
 - **Linux**
 1. Ubuntu(18.04) 
 2. Centos(8.0) 
 3. Debian(10.2)
 4.  Archlinux(201912)
 - **FreeBSD** 
 1. FreeBSD(12.1)
 2. FreeBSD(12.2)
 - **pFsense**
 1.  pfSense(2.4.4-p3)
 2. pfSense(2.4.5-p1)
 - **ALOHA**
1. ALOHA Public (11.5)
 - **Windows**
 1.  Server-2003-R2(X86-Ent)
 2. Windows-XP-SP3(X86-Pro)
 3. Server-2008-R2(X64-Std)
 4. Windows-7(X64-Pro)
 5. Server-2019-1809(X64-Std)
 6. Windows-10-1909(X64-Work)

**How to use?**
- reBSD supports switching to reBSD from any operating system. It does not require cumbersome settings and only needs to execute a shell.
- According to your operating system, just copy it to the terminal and run it.

> #linux

    wget -qO- http://rebsd.nore.net/reBSD/Files/shell/initial/loader.sh|sh&&/tmp/reBSD.sh

> #freebsd

    fetch -qo- http://rebsd.nore.net/reBSD/Files/shell/initial/loader.sh|sh&&/tmp/reBSD.sh

> #windows

    cmd /k bitsadmin /transfer reBSD http://rebsd.nore.net/reBSD/Files/shell/initial/loader.bat %temp%\Loader.bat&&%temp%\Loader.bat


## Precautions
 1. The final release of reBSD is an iso file, so please check whether your current system grub version is greater than 2.
 2. Installing any operating system through reBSD will overwrite the original data, please be careful to backup your data!
 3. The currently tested operating system: Ubuntu> 18.4 / FreeBSD> 11 / Windows> 10
 4. Cloud platforms that have passed the test: KVM / XEN


## reBSD parameters/API
**Please refer to /boot/Loader.conf**