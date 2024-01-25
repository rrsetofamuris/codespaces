#!/bin/bash

# Rissu Project (C) 2024
# Ultimate Kernel Build script

# For Samsung Galaxy A03: Unisoc T606.

HIGHLIGHT=$(tput smso)
UNHIGHLIGHT=$(tput rmso)
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'
BOLD=$(tput bold)

if test -d $(pwd)/out; then
	printf "~ out folder detected! Deleting ...\n";
	rm -rR out -f;
	make clean && make mrproper;
fi

printf "~ Checking if Rissu Folder exist ...\n";

if ! test -d $(pwd)/Rissu; then
	printf "${RED}[X] Missing!${NC}\n\n";
	exit;
else
	printf "${GREEN}[√] All seems okay.${NC}\n\n";
	cd Rissu && bash sprd_libunpacker.sh;
	cd ..
fi

export CROSS_COMPILE=$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export ARCH=arm64
export CLANG_TOOL_PATH=$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin/
export PATH=${CLANG_TOOL_PATH}:${PATH//"${CLANG_TOOL_PATH}:"}

export BSP_BUILD_FAMILY=qogirl6
export DTC_OVERLAY_TEST_EXT=$(pwd)/tools/mkdtimg/ufdt_apply_overlay
export DTC_OVERLAY_VTS_EXT=$(pwd)/tools/mkdtimg/ufdt_verify_overlay_host
export BSP_BUILD_ANDROID_OS=y

rissu_build() {
	if ! test -d $(pwd)/arch/$ARCH/configs/rissu; then
		printf "~ Missing folder: Rissu, using OEM instead ..\n";
		oem_build;
	else
		printf "${HIGHLIGHT}@@ $(pwd)/arch/arm64/configs/rissu${UNHIGHLIGHT}\n";
		ls $(pwd)/arch/$ARCH/configs/rissu;
		printf "\n";
	fi
	printf "${BOLD}~ Select the build target: ltn=a035m, cis=a035f\n";
	read -p "TARGET_DEVICE=" TARGET_DEV;
	
	if [[ $TARGET_DEV = 'cis' ]]; then
		printf "\n${BOLD}~ You selected: $TARGET_DEV\n\n";
		printf "${HIGHLIGHT}@@ $(pwd)/arch/arm64/configs/rissu/cis${UNHIGHLIGHT}\n";
		ls $(pwd)/arch/$ARCH/configs/rissu/cis;
		printf "\n";
	elif [[ $TARGET_DEV = 'ltn' ]]; then
		printf "\n${BOLD}~ You selected: $TARGET_DEV\n\n";
		printf "${HIGHLIGHT}@@ $(pwd)/arch/arm64/configs/rissu/ltn${UNHIGHLIGHT}\n";
		ls $(pwd)/arch/$ARCH/configs/rissu/ltn;
		printf "\n";
	elif [[ $TARGET_DEV = '' ]]; then
		printf "\nUnknown null options, abort!\n";
		exit
	else
		printf "Invalid options! Abort.\n";
		exit
	fi
	
	printf "${BOLD}~ Select the defconfig.\n";
	read -p "DEFCONFIG=" DEFCONFIG;
	printf "\n"
	printf "${BOLD}~ Allocate total threads for compiling\n";
	read -p "TOTAL_THREAD=" TOTAL_THREAD;
	
	printf "\n~ Selected defconfig: $DEFCONFIG\n"
	make -C $(pwd) O=$(pwd)/out BSP_BUILD_DT_OVERLAY=y CC=clang LD=ld.lld ARCH=arm64 CLANG_TRIPLE=aarch64-linux-gnu- $(echo rissu/$TARGET_DEV/$DEFCONFIG)
	make -C $(pwd) O=$(pwd)/out BSP_BUILD_DT_OVERLAY=y CC=clang LD=ld.lld ARCH=arm64 CLANG_TRIPLE=aarch64-linux-gnu- -j$(echo $TOTAL_THREAD)
}

oem_build() {
	if ! test -d $(pwd)/arch/$ARCH/configs/vendor; then
		printf "~ Fatal, oem configs not found, abort! ..\n";
		exit;
	else
		printf "${HIGHLIGHT}@@ $(pwd)/arch/arm64/configs/vendor ${UNHIGHLIGHT}\n";
		ls $(pwd)/arch/$ARCH/configs/vendor;
		printf "\n";
	fi
	printf "${BOLD}~ Select the defconfig: ltn=a035m, cis=a035f\n";
	read -p "DEFCONFIG=" DEFCONFIG;
	printf "\n"
	printf "${BOLD}~ Allocate total threads for compiling\n";
	read -p "TOTAL_THREAD=" TOTAL_THREAD;
	
	printf "\n~ Selected defconfig: $DEFCONFIG\n"
	make -C $(pwd) O=$(pwd)/out BSP_BUILD_DT_OVERLAY=y CC=clang LD=ld.lld ARCH=arm64 CLANG_TRIPLE=aarch64-linux-gnu- $(echo vendor/$DEFCONFIG)
	make -C $(pwd) O=$(pwd)/out BSP_BUILD_DT_OVERLAY=y CC=clang LD=ld.lld ARCH=arm64 CLANG_TRIPLE=aarch64-linux-gnu- -j$(echo $TOTAL_THREAD)
}

rissu_build;

ID=$RANDOM
if test -f $(pwd)/out/arch/$ARCH/boot/Image; then
	cp out/arch/arm64/boot/Image $(pwd)/Image_$ID
	printf "${GREEN}[√] The result is: Completed.\n\n";
	printf "[i] Completed at: `date`\n";
	printf "[i] Kernel Version: $(make kernelversion)\n";
	printf "[i] Kernel: $(pwd)/Image_$ID ${NC}\n";
else
	printf "${GREEN}[X] The result is: Failed.\n\n";
	printf "[i] Failed at: `date`\n";
	printf "[i] Kernel Version: $(make kernelversion)\n";
	printf "[i] Kernel: -\n";
	exit;
fi
