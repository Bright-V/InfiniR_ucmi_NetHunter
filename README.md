# Kernel Characteristics

### Compiler

**Clang**: [ZyCromerZ/Clang 17.0.0](https://github.com/ZyCromerZ/Clang/releases/tag/17.0.0-20230725-release)

## KenrelSU

Please run the following step before building.

```bash
cd /path/to/kernel/source
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
```

## NetHunter

I've completed the steps below, so you don't have to do again.

```bash
cd /path/to/kernel/source
git clone https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernel.git
patch -p1 < kali-nethunter-kernel/patches/4.19/add-rtl88xxau-5.6.4.2-drivers.patch
patch -p1 < kali-nethunter-kernel/patches/4.19/add-wifi-injection-4.14.patch
patch -p1 < kali-nethunter-kernel/patches/4.19/fix-ath9k-naming-conflict.patch
```

# For Rom Devs

## Warnig: Use [upstream source](https://github.com/toraidl/InfiniR_kernel_ucmi) instead, If you don't know what the NetHunter Kernel is.

If you want to inline this kernel in your Roms then do this before building ( In kernel root directory ):

```bash
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
```

Do this Everytime you clone the repo bcz this kernel has the support for Kernel-SU and it needs to be recloned and checkout to latest stable tag.

# For Kenrel Devs

## Before Building

Please install all the dependencies.

``For ArchLinux/Manjaro ( ArchLinux based Linux )``

```bash
sudo pacman -S clang gcc llvm bc bison base-devel ccache curl flex gcc-multilib git git-lfs gnupg gperf imagemagick lib32-readline lib32-zlib elfutils lz4 sdl openssl libxml2 lzop pngcrush rsync schedtool squashfs-tools libxslt zip zlib lib32-ncurses wxgtk3 ncurses inetutils cpio z3
```

``For others``
```bash
# use relevant package manager ( apt, yum... )
```

## Building Kernel

I'v made a fully automated script from scratch to the packaged kernel.

```bash
cd /path/to/kernel/source
./build.sh
```

- Template example ( ``kali-nethunter-project/nethunter-installer/devices/devices.cfg`` )

```bash
# Xiaomi 10 for HyperOS Android 14
[ucmi]
author = "Yttehs"
arch = arm64
version = "${KERNEL_VERSION}"
flasher = anykernel
modules = 1
slot_device = 0
block = /dev/block/bootdevice/by-name/boot
devicenames = umi,cmi,Mi10,Mi10pro
```

Finally, get the zip in ``kali-nethunter-project/nethunter-installer/kernel-nethunter-YYYYMMDD_HHMMSS-ucmi-thirteen.zip``.
