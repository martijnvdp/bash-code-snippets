#!/bin/bash
# script to build latest wsl2 kernel with custom options
#
# update wsl before running with: wsl --update
CPU=2
CUSTOM_VER="-microsoft-WSL2-cilium"
IMAGEFILE="bzImage-$(date +%s)"
URL=$(curl https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest 2>/dev/null | jq -r '.tarball_url')
USERDIR=$(wslpath "$(wslvar USERPROFILE)")
TARGET="kernel"

# check jq
which jq || sudo apt install -y jq

# switch to home folder (build in /user/home bc need linux fs)
cd /home/${USER}
sudo apt update && sudo apt install -y git build-essential flex bison dwarves libssl-dev libelf-dev python3
mkdir kernel-src
cd kernel-src

# get latest wsl2 kernel
wget ${URL} -O kernel.tar.gz
tar --strip-components=1 -zxf kernel.tar.gz

# set custom version ( uname -r )
sed -i 's/-microsoft-standard-WSL2/'${CUSTOM_VER}'/' Microsoft/config-wsl
# adds support for clientIP-based session affinity 
sed -i 's/# CONFIG_NETFILTER_XT_MATCH_RECENT is not set/CONFIG_NETFILTER_XT_MATCH_RECENT=y/' Microsoft/config-wsl
# required modules for Cilium
sed -i 's/# CONFIG_NETFILTER_XT_TARGET_CT is not set/CONFIG_NETFILTER_XT_TARGET_CT=y/' Microsoft/config-wsl
sed -i 's/# CONFIG_NETFILTER_XT_TARGET_TPROXY is not set/CONFIG_NETFILTER_XT_TARGET_TPROXY=y/' Microsoft/config-wsl

# build the kernel j<cpu cores>
make -j${CPU} KCONFIG_CONFIG=Microsoft/config-wsl

# copy kernel image to user dir/kernel
if [ ! -d "${USERDIR}/${TARGET}" ]; then
    mkdir ${USERDIR}/${TARGET}
fi

cp arch/x86/boot/bzImage ${USERDIR}/${TARGET}/${IMAGEFILE}

# create .wslconfig file and point kernel to newly build 
readarray -d / -t userdirarr <<< "$USERDIR"
cat << EOF >  ${USERDIR}/.wslconfig
[wsl2]
kernel=$(echo 'C:\\Users\\'$( echo ${userdirarr[4]})'\\'${TARGET}'\\'${IMAGEFILE})
EOF

# cleanup
cd ..
rm -rf kernel-src

# restart/shutdown wsl
read -p "Press a key to continue and restart WSL"
/mnt/c/Windows/system32/cmd.exe /c "wsl --shutdown"

# start wsl and check version with uname -r
# and restart docker desktop
