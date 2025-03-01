#!/bin/bash

# CHANGE THE PATH TO YOUR TOOLCHAINS

# ===----------------------------------------------=== #
# This script is used to build android kernel for mi10 #
# ===----------------------------------------------=== #

KERNEL_VERSION="2.8"
DEFCONFIG="ucmi_nethunter_apatch_defconfig"

# ===------------=== #
# Clone Dependencies #
# ===------------=== #

echo "[+] prepare dependencies"

NETHUNTER_KERNEL_DIR="kali-nethunter-kernel"
NETHUNTER_PROJECT_DIR="kali-nethunter-project"

if [ -d "$NETHUNTER_KERNEL_DIR" ]; then
    echo "[+] $NETHUNTER_KERNEL_DIR exits"
    cd $(pwd)/$NETHUNTER_KERNEL_DIR
    git pull
    cd ..
else
    echo "[!] $NETHUNTER_KERNEL_DIR not exits, start cloning..."
    git clone https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernel.git
fi

echo -n "[!] Adding patch add-rtl88xxau-5.6.4.2-drivers? [y/N]"
read -r add_rtl88xxau_drivers
if [ "$add_rtl88xxau_drivers" == "Y" ] || [ "$add_rtl88xxau_drivers" == "y" ]; then
    patch -p1 < kali-nethunter-kernel/patches/4.19/add-rtl88xxau-5.6.4.2-drivers.patch
fi

echo -n "[!] Adding patch add-wifi-injection-4.14.patch? [y/N]"
read -r add_wifi_injection
if [ "$add_wifi_injection" == "Y" ] || [ "$add_wifi_injection" == "y" ]; then
    patch -p1 < kali-nethunter-kernel/patches/4.19/add-wifi-injection-4.14.patch
fi

echo -n "[!] Adding patch fix-ath9k-naming-conflict.patch? [y/N]"
read -r fix_ath9k_naming_conflict
if [ "$fix_ath9k_naming_conflict" == "Y" ] || [ "$fix_ath9k_naming_conflict" == "y" ]; then
    patch -p1 < kali-nethunter-kernel/patches/4.19/fix-ath9k-naming-conflict.patch
fi

if [ -d "$NETHUNTER_PROJECT_DIR" ]; then
    echo "[+] $NETHUNTER_PROJECT_DIR exits"
    cd $(pwd)/$NETHUNTER_PROJECT_DIR
    git pull
    cd ..
else
    echo "[!] $NETHUNTER_PROJECT_DIR not exits, start cloning..."
    git clone https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project --depth=1
fi

mkdir -p $(pwd)/kali-nethunter-project/nethunter-installer/devices

cat << EOL > kali-nethunter-project/nethunter-installer/devices/devices.cfg
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
EOL

echo "[+] fetch KenrelSU"
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -

echo "[+] copy defconfig"
cp $(pwd)/${DEFCONFIG} $(pwd)/arch/arm64/configs/${DEFCONFIG}

# ===-----------------=== #
# Buiding Kernel & Module #
# ===-----------------=== #

echo "[+] check toolchain"

CURRENT_PATH=$(pwd)

CLANG_VERSION="17"

CLANG_TAR_NAME="Clang-17.0.0-20230725.tar.gz"

TOOLCHAINS_DIR="$(pwd)/../toolchains"

CLANG_DIR="${TOOLCHAINS_DIR}/zyc-${CLANG_VERSION}"

if [ ! -d "$CLANG_DIR" ]; then
    echo "[!] clang 17.0.0 not found"
    echo "[+] start downloading"
    mkdir -p $CLANG_DIR
    wget -P $CLANG_DIR https://github.com/ZyCromerZ/Clang/releases/download/17.0.0-20230725-release/Clang-17.0.0-20230725.tar.gz
    tar -xzvf $CLANG_DIR/${CLANG_TAR_NAME} -C $CLANG_DIR
    rm "$CLANG_DIR/$CLANG_TAR_NAME"
    echo "[+] finish"
else
    echo "[+] clang 17.0.0 already exits"
fi

CURRENT_PATH=$(pwd)

cd $CLANG_DIR

CLANG_PATH="${CLANG_DIR}/bin"

cd $CURRENT_PATH

O="out"
ARCH="arm64"

echo "[!] setting up environment"

echo "[+] clang path: ${CLANG_PATH}"

export PATH="${CLANG_PATH}:${PATH}"

args="-j$(nproc --all) \
O=${O} \
ARCH=${ARCH} \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
CLANG_TRIPLE=aarch64-linux-gnu- \
CC=clang \
LD=ld.lld \
AR=llvm-ar \
NM=llvm-nm \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
READELF=llvm-readelf \
OBJSIZE=llvm-size \
STRIP=llvm-strip \
LDGOLD=aarch64-linux-gnu-ld.gold \
LLVM_AR=llvm-ar \
LLVM_DIS=llvm-dis"

echo "[!] cleanning old configuration"
make mrproper

echo "[!] executing defconfig"
make ${args} ${DEFCONFIG}

echo "[!] compiling"
make ${args} 2>&1

echo "[!] compiling modules"
make ${args} INSTALL_MOD_PATH="." INSTALL_MOD_STRIP=1 modules_install

# ===-----------------------------=== #
# | Create NetHunter-Anykernel3 Zip | #
# ===-----------------------------=== #

echo "[+] start packaging"

O=out
ARCH=arm64
KERNEL_VERSION="4.19.306-InfiniR-X-NetHunter-APatch"
DEVICE=ucmi
ANDROID_VERSION=thirteen

echo "[+] create dirs"
mkdir -p $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE
mkdir -p $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE/modules/system/lib/modules

echo "[!] clean pre files"
rm -rf $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE/Image
rm -rf $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE/Image-dtb
rm -rf $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE/Image-dtb-hdr
rm -rf $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE/dtbo.img
rm -rf $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE/dtb
rm -rf $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE/modules/system/lib/modules/*

echo "[+] copy Image"
cp $(pwd)/$O/arch/$ARCH/boot/Image $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE

echo "[+] copy Image-dtb"
cp $(pwd)/$O/arch/$ARCH/boot/Image-dtb $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE

echo "[+] copy Image-dtb-hdr"
cp $(pwd)/$O/arch/$ARCH/boot/Image-dtb-hdr $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE

# echo "[+] copy dtbo.img"
# cp $(pwd)/$O/arch/$ARCH/boot/dtbo.img $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE

echo "[+] copy dtb"
cp $(pwd)/$O/arch/$ARCH/boot/dtb $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE

echo "[!] delete links"
rm -rf $(pwd)/$O/lib/modules/$KERNEL_VERSION/source
rm -rf $(pwd)/$O/lib/modules/$KERNEL_VERSION/build

echo "[+] copy modules"
cp -r $(pwd)/$O/lib/modules/$KERNEL_VERSION/* $(pwd)/kali-nethunter-project/nethunter-installer/devices/$ANDROID_VERSION/$DEVICE/modules/system/lib/modules/

cd $(pwd)/kali-nethunter-project/nethunter-installer/
python3 build.py -d ucmi --thirteen --kernel
