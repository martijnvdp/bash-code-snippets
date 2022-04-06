#!/bin/bash
# script to build latest wsl2 kernel with custom options
#
# update wsl before running with: wsl --update
CPU=2
CUSTOM_VER="-microsoft-WSL2-cilium"
IMAGEFILE="bzImage-$(date +%s)"
SRC=$(curl https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest 2>/dev/null)
URL=$(echo ${SRC} | jq -r '.tarball_url')
USERDIR=$(wslpath "$(wslvar USERPROFILE)")
WSL_BRANCH=$(echo ${SRC} | jq -r '.target_commitish')
WSL_VER=$(echo ${SRC} | jq -r '.tag_name')

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
mkdir ${USERDIR}/kernel  
cp arch/x86/boot/bzImage ${USERDIR}/kernel/${IMAGEFILE}

# create .wslconfig file and point kernel to newly build 
readarray -d / -t userdirarr <<< "$USERDIR"
cat << EOF >  ${USERDIR}/.wslconfig
[wsl2]
kernel=$(echo 'C:\\Users\\'$( echo ${userdirarr[4]})'\\kernel\\'${IMAGEFILE})
EOF

# cleanup
cd ..
rm -rf kernel-src

# restart/shutdown wsl
cmd.exe /c "wsl --shutdown"

# start wsl and check version with uname -r