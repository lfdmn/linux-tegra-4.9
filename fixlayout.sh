SOURCE_DIR=${PWD}/sources
LINUX_TEGRA_DIR=$1
echo "Source dir: " ${SOURCE_DIR}

if [ "$LINUX_TEGRA_DIR" != "" ]; then
    echo "linux-tegra dir: " ${LINUX_TEGRA_DIR}
fi

# Download BSP for L4T 28.2
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Downloading BSP for L4T 32.2"
    wget http://connecttech.com/ftp/dropbox/cti-l4t-src-v126.tgz

    echo "Extracting sources"
    tar -xzf cti-l4t-src-v126.tgz
    rm cti-l4t-src-v126.tgz

    # Relocate folders
    echo "Relocating folders"
    mkdir ${SOURCE_DIR}/kernel/kernel-4.9/nvidia
    mv ${SOURCE_DIR}/kernel/display ${SOURCE_DIR}/kernel/kernel-4.9/nvidia
    mv ${SOURCE_DIR}/kernel/nvgpu ${SOURCE_DIR}/kernel/kernel-4.9/nvidia
    mv ${SOURCE_DIR}/kernel/nvhost ${SOURCE_DIR}/kernel/kernel-4.9/nvidia
    mv ${SOURCE_DIR}/kernel/nvmap ${SOURCE_DIR}/kernel/kernel-4.9/nvidia
    mv ${SOURCE_DIR}/kernel/nvmap-t18x ${SOURCE_DIR}/kernel/kernel-4.9/nvidia
    mv ${SOURCE_DIR}/kernel/t18x ${SOURCE_DIR}/kernel/kernel-4.9/nvidia
    mv ${SOURCE_DIR}/hardware/nvidia/platform ${SOURCE_DIR}/kernel/kernel-4.9/nvidia
    mv ${SOURCE_DIR}/hardware/nvidia/soc ${SOURCE_DIR}/kernel/kernel-4.9/nvidia

    # Create local git repo to help debugging
    echo "Creating local git repo to help debugging"
    cd ${SOURCE_DIR}
    git init
    git add *
    git commit -m "Initial import"
    cd ..
fi

# Special file behaviors are defined here
declare -a exceptions=("${SOURCE_DIR}/kernel/kernel-4.9/drivers/video/tegra/Makefile"
                       "${SOURCE_DIR}/kernel/kernel-4.9/drivers/video/tegra/camera/Makefile"
                       "${SOURCE_DIR}/kernel/kernel-4.9/drivers/media/platform/tegra/vi/Makefile"
                       "${SOURCE_DIR}/kernel/kernel-4.9/drivers/media/platform/tegra/tpg/Makefile"
                       "${SOURCE_DIR}/kernel/kernel-4.9/drivers/media/platform/tegra/camera/Makefile"
                       "${SOURCE_DIR}/kernel/kernel-4.9/drivers/media/platform/tegra/camera/vi/Makefile"
                       "${SOURCE_DIR}/kernel/kernel-4.9/drivers/media/platform/tegra/camera/csi/Makefile"
                       "${SOURCE_DIR}/kernel/kernel-4.9/drivers/gpu/host1x/Makefile"
                       "${SOURCE_DIR}/kernel/kernel-4.9/drivers/gpu/drm/tegra/Makefile")
#                       "${SOURCE_DIR}/kernel/kernel-4.4/Makefile")

# Files to exclude from mergins are defines here
declare -a do_not_merge=("/scripts/Kbuild.include"
                         "/tools/perf/config/Makefile"
                         "/tools/perf/Makefile.perf"
                         "/tools/lib/api/Makefile"
                         "/tools/build/Makefile.feature"
                         "/Makefile"
                         "/make_clean.sh"
                         "/make_script.sh"
                         "/nvidia/display/drivers/video/tegra/dc/Makefile")

function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

# Fix all include like statements and file references
files=()
while IFS=  read -r -d $'\0'; do
    files+=("$REPLY")
done < <(find ${SOURCE_DIR} -type f \( -name "Makefile*" -o -name "Kconfig*" -o -name "Kbuild*" -o -name "pwm_bl.c" -o -name "lp855x_bl.c" \) -print0)

n=0
for f in "${files[@]}"
do
    n=$((n+1))
    progress=$(((n*100) / ${#files[@]}))

    echo -ne "Fixing all include like statements and file references: $progress%\r"

    if [ $(contains "${exceptions[@]}" "$f") == "y" ]; then
        sed -i \
            -e 's/-I..\/nvhost\//-Invidia\/nvhost\//g' \
            -e 's/-I..\/t18x\//-Invidia\/t18x\//g' \
            $f
    else
        sed -i \
            -e 's/"..\/t18x\//"nvidia\/t18x\//g' \
            -e 's/-I..\/..\/..\/..\/..\/kernel-4.9\//-I$(srctree)\//g' \
            -e 's/-I..\/nvhost\//-I$(srctree)\/nvidia\/nvhost\//g' \
            -e 's/-I$(srctree)\/..\/t18x\//-I$(srctree)\/nvidia\/t18x\//g' \
            -e 's/-I..\/nvgpu\//-I$(srctree)\/nvidia\/nvgpu\//g' \
            -e 's/$(srctree)\/..\/nvgpu/$(srctree)\/nvidia\/nvgpu/g' \
            -e 's/trysource "..\/nvgpu-t19x\//trysource "nvidia\/nvgpu-t19x\//g' \
            -e 's/trysource "..\/nvhost-t19x\//trysource "nvidia\/nvhost-t19x\//g' \
            -e 's/$(srctree)\/..\/nvhost/$(srctree)\/nvidia\/nvhost/g' \
            -e 's/-I$(srctree)\/..\/display\//-I$(srctree)\/nvidia\/display\//g' \
            -e 's/wildcard $(srctree)\/..\/nvmap-t18x\//wildcard $(srctree)\/nvidia\/nvmap-t18x\//g' \
            -e 's/wildcard $(srctree)\/..\/nvmap-t19x\//wildcard $(srctree)\/nvidia\/nvmap-t19x\//g' \
            -e 's/-I$(srctree)\/..\/nvmap\//-I$(srctree)\/nvidia\/nvmap\//g' \
            -e 's/-I$(srctree)\/..\/t18x/-I$(srctree)\/nvidia\/t18x/g' \
            -e 's/-I..\/display\//-I$(srctree)\/nvidia\/display\//g' \
            -e 's/-I$(srctree)\/..\/t19x\//-I$(srctree)\/nvidia\/t19x\//g' \
            -e 's/-I..\/t18x\//-I$(srctree)\/nvidia\/t18x\//g' \
            -e 's/-I$(srctree)\/..\/t18x\//-I$(srctree)\/nvidia\/t18x\//g' \
            -e 's/-I$(srctree)\/..\/nvhost\//-I$(srctree)\/nvidia\/nvhost\//g' \
            -e 's/-I$(srctree)\/..\/display\//$(srctree)\/nvidia\/display\//g' \
            -e 's/-I$(srctree)\/..\/nvmap\//-I$(srctree)\/nvidia\/nvmap\//g' \
            -e 's/-I$(srctree)\/..\/nvgpu\//-I$(srctree)\/nvidia\/nvgpu\//g' \
            -e 's/wildcard $(srctree)\/..\/t18x\//wildcard $(srctree)\/nvidia\/t18x\//g' \
            -e 's/+= ..\/..\/..\/t18x\//+= ..\/..\/nvidia\/t18x\//g' \
            -e 's/-I$(srctree)\/..\/$(1)/-I$(srctree)\/nvidia\/$(1)/g' \
            -e 's/trysource "..\/nvhost/trysource "nvidia\/nvhost/g' \
            -e 's/trysource "..\/nvmap/trysource "nvidia\/nvmap/g' \
            -e 's/trysource "..\/display/trysource "nvidia\/display/g' \
            -e 's/#include "..\/..\/..\/..\/display\/drivers\//#include "..\/..\/..\/nvidia\/display\/drivers\//g' \
            -e 's/#include <..\/..\/..\/display\//#include <..\/..\/nvidia\/display\//g' \
            -e 's/-I$(srctree)\/..\/display/-I$(srctree)\/nvidia\/display/g' \
            -e 's/trysource "..\/nvgpu\//trysource "nvidia\/nvgpu\//g' \
            -e 's/+= ..\/..\/t18x\//+= ..\/nvidia\/t18x\//g' \
            -e 's/wildcard $(srctree)\/..\/t19x\//wildcard $(srctree)\/nvidia\/t19x\//g' \
            -e 's/+= ..\/..\/t19x\//+= ..\/nvidia\/t19x\//g' \
            -e 's/trysource ..\/t18x\//trysource nvidia\/t18x\//g' \
            -e 's/$(tegra-rel-dtstree)\/hardware\/nvidia\//$(tegra-rel-dtstree)\/nvidia\//g' \
            -e 's/EXTRAVERSION = -tegra/EXTRAVERSION =/g' \
            -e 's/$(srctree)\/..\/..\/hardware\/nvidia/$(srctree)\/nvidia/g' \
            $f
    fi
done
echo -ne '\n'


# Sync files into linux-tegra directory
if [ "$LINUX_TEGRA_DIR" != "" ]; then
    echo "Sync files into linux-tegra directory"
    excludes=""

    for f in "${do_not_merge[@]}"
    do
        excludes="$excludes --exclude $f"
        echo "-----------------------------------------_> not mergin $f"
    done

    rsync -avz $excludes --include=".config" $SOURCE_DIR/kernel/kernel-4.9/ $LINUX_TEGRA_DIR
fi

echo "Done"
