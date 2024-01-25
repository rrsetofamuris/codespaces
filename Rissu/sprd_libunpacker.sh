#! /bin/sh

# Rissu Project (C) 2024
# Basically unpack libart.so

cd ..

RISSU_ROOT="$(pwd)/Rissu"
KERNEL_ROOT="$(pwd)"

# Old method use tar.xz
USE_TAR=n

check_files() {
	if [ -f $KERNEL_ROOT/tools/lib64/libart.so ] || [ -f $KERNEL_ROOT/tools/lib64/libart-compiler.so ] || [ -f $KERNEL_ROOT/tools/lib64/libplatformprotos.so ]; then
		printf "";
	else
		check_directory;
	fi
}

check_tar() {
	if ! test -f $RISSU_ROOT/tools/compressions/tar; then
		printf "[SPRD_UNPACK] Using system's default\n";
		use_system_tar;
	else
		printf "[SPRD_UNPACK] Using prebuilt decompressor\n";
		use_tar;
	fi
}

check_unzip() {
	if ! test -f $RISSU_ROOT/tools/compressions/unzip; then
		printf "[SPRD_UNPACK] Using system's default\n";
		use_system_unzip;
	else
		printf "[SPRD_UNPACK] Using prebuilt decompressor\n";
		use_unzip;
	fi
}

check_directory() {
	if [ $USE_TAR = y ]; then
		if ! test -f $KERNEL_ROOT/tools/lib64/splits.tar.xz; then
			printf "! Fatal Error, Required files not found. Aborting ...\n";
			exit;
		else
			check_tar;
		fi
	else
		if ! test -f $RISSU_ROOT/vendor/sprd/libart.zip; then
			printf "! Fatal Error, libart.zip is missing, Aborting ...\n";
			exit;
		elif ! test -f $RISSU_ROOT/vendor/sprd/libart-compiler.zip; then
			printf "! Fatal Error, libart-compiler.zip is missing, Aborting ...\n";
			exit;
		elif ! test -f $RISSU_ROOT/vendor/sprd/libplatformprotos.zip; then
			printf "! Fatal Error, libplatformprotos.zip is missing, Aborting ...\n";
			exit;
		else
			check_unzip;
		fi
	fi			
}

#START OF TAR
use_tar() {
	chmod +x $RISSU_ROOT/tools/compressions/tar
	$RISSU_ROOT/tools/tar/tar -xvf $RISSU_ROOT/vendor/sprd/SPLITS.tar.xz -C $KERNEL_ROOT/tools/lib64
}

use_system_tar() {
	tar -xvf $RISSU_ROOT/vendor/sprd/SPLITS.tar.xz -C $KERNEL_ROOT/tools/lib64
}
#END OF TAR

#START OF ZIP
use_unzip() {
	chmod +x $RISSU_ROOT/tools/compressions/unzip
	$RISSU_ROOT/tools/compressions/unzip $RISSU_ROOT/vendor/sprd/libart.zip -d $KERNEL_ROOT/tools/lib64 2>/dev/null
	$RISSU_ROOT/tools/compressions/unzip $RISSU_ROOT/vendor/sprd/libart-compiler.zip -d $KERNEL_ROOT/tools/lib64 2>/dev/null
	$RISSU_ROOT/tools/compressions/unzip $RISSU_ROOT/vendor/sprd/libplatformprotos.zip -d $KERNEL_ROOT/tools/lib64 2>/dev/null
}

use_system_unzip() {
	unzip $RISSU_ROOT/vendor/sprd/libart.zip -d $KERNEL_ROOT/tools/lib64 2>/dev/null
	unzip $RISSU_ROOT/vendor/sprd/libart-compiler.zip -d $KERNEL_ROOT/tools/lib64 2>/dev/null
	unzip $RISSU_ROOT/vendor/sprd/libplatformprotos.zip -d $KERNEL_ROOT/tools/lib64 2>/dev/null
}

execute() {
	check_files;
}

execute;
