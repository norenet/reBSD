## **预览**
**Shell**
![Shell](https://github.com/norenet/reBSD/raw/master/shell.gif)
**reBSD**
![reBSD](https://github.com/norenet/reBSD/raw/master/reBSD.gif)


## **什么是reBSD?**
 - reBSD是一个基于FreeBSD自定义内核开发的迷你操作系统,它可以用于维护基于KVM或XEN的云实例/VPS.
 - 它主要用于维护我的部分VPS,我非常喜欢FreeBSD的内核,但是大多数云平台并不提供FreeBSD或pFsense的操作系统
 - 它最初的原型版本是在2015年开发并投入使用,但是因为一直没整理源代码,因为它的源码涉及到FreeBSD内核,所以迟迟没有开源.
 - reBSD暂时不支持第三方脚本,你能在这看到的是内核里的shell源码,它不包含内核和其他的源码.

**特点**
 1. 全自动化安装操作系统,全程无需noVNC或者ipmi的支持.
 2. 兼容专用服务器/KVM/XEN/vmware/Hyper-V,支持UEFI
 3. 可视化的操作系统安装过程
 4. 第三方救援系统,reBSD支持ext2/3/4,xfs,ntfs等一系列磁盘格式.
 5. 功能齐全的备用系统,reBSD包含了日常维护的功能.
 6. 支持安装第三方软件(pkg)

**需求**
 1. 磁盘:24Mb
 2. 内存:32Mb
 3. 安装FreeBSD/pFsense 需要 > 256Mb的内存
 4. 安装Linux/Windows 需要 > 512Mb的内存

**自动安装的操作系统**
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
1. ALOHA Public (latest)
 - **Windows**
 1.  Server-2003-R2(X86-Ent)
 2. Windows-XP-SP3(X86-Pro)
 3. Server-2008-R2(X64-Std)
 4. Windows-7(X64-Pro)
 5. Server-2019-1809(X64-Std)
 6. Windows-10-1909(X64-Work)

**如何使用?**
 - reBSD支持从任意操作系统上切换到reBSD,它无需繁琐的设置,只需要执行一个shell即可. 
 - 根据你的操作系统,复制至终端运行即可.

> #linux

    wget -qO- http://rebsd.nore.net/reBSD/Files/shell/initial/loader.sh|sh&&/tmp/reBSD.sh

> #freebsd

    fetch -qo- http://rebsd.nore.net/reBSD/Files/shell/initial/loader.sh|sh&&/tmp/reBSD.sh

> #windows

    cmd /k bitsadmin /transfer reBSD http://rebsd.nore.net/reBSD/Files/shell/initial/loader.bat %temp%\Loader.bat&&%temp%\Loader.bat


## 注意事项
 1. reBSD最终发行的是iso文件,它需要grub2,如果你原有操作系统grub版本过低,请手动升级.
 2. 通过reBSD安装任意操作系统会覆盖原有的数据,请注意备份你的数据!
 3. 目前通过测试的操作系统: Ubuntu > 18.4 / FreeBSD > 11 / Windows > 7
 4. 目前通过测试的云平台: KVM / XEN / vmware / Hyper-V
 
**

## reBSD的参数/API
**请查阅/boot/Loader.conf**

## reBSD licenses
** TODO **
