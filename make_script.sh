#!/bin/bash

if [ -z "$TEGRA_KERNEL_OUT" ]
then

echo "TEGRA_KERNEL_OUT is not set, source the setup_crosdev.sh"

else


make O=$TEGRA_KERNEL_OUT -j8 zImage
make O=$TEGRA_KERNEL_OUT -j4 dtbs
make O=$TEGRA_KERNEL_OUT -j4 modules
make O=$TEGRA_KERNEL_OUT -j4 modules_install INSTALL_MOD_PATH=$L4T_ROOT_DIR/built_modules
echo done

fi

