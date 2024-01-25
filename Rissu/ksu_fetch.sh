#!/bin/sh
cd ..

ROOT=$(pwd)

echo "[i] Kernel Tree: $ROOT"

if test -d "$ROOT/KernelSU"; then
	rm -rR KernelSU -f
fi

if test -d "$ROOT/common/drivers"; then
     DRIVER_DIR="$ROOT/common/drivers"
elif test -d "$ROOT/drivers"; then
     DRIVER_DIR="$ROOT/drivers"
else
     echo '[X] "drivers/" directory is not found.'
     echo '[i] You should modify this script by yourself.'
     exit 127
fi

if test -d "$ROOT/drivers/kernelsu"; then
	rm -rR $DRIVER_DIR/kernelsu -f;
fi

test -d "$ROOT/KernelSU" || git clone https://github.com/tiann/KernelSU
cd "$ROOT/KernelSU"
git stash
if [ "$(git status | grep -Po 'v\d+(\.\d+)*' | head -n1)" ]; then
     git checkout main
fi
git pull
if [ -z "${1-}" ]; then
    git checkout "$(git describe --abbrev=0 --tags)"
else
    git checkout "$1"
fi
cd "$ROOT"

echo "[i] Copying KernelSU driver to $DRIVER_DIR"

cd "$DRIVER_DIR"
if test -d "$ROOT/common/drivers"; then
     ln -sf "../../KernelSU/kernel" "kernelsu"
elif test -d "$ROOT/drivers"; then
     ln -sf "../KernelSU/kernel" "kernelsu"
fi
cd "$ROOT"

echo '[i] Add KernelSU driver to Makefile'

DRIVER_MAKEFILE=$DRIVER_DIR/Makefile
DRIVER_KCONFIG=$DRIVER_DIR/Kconfig

grep -q "kernelsu" "$DRIVER_MAKEFILE" || printf "obj-\$(CONFIG_KSU) += kernelsu/\n" >> "$DRIVER_MAKEFILE"
grep -q "kernelsu" "$DRIVER_KCONFIG" || sed -i "/endmenu/i\\source \"drivers/kernelsu/Kconfig\"" "$DRIVER_KCONFIG"

echo '[i] Done.'
