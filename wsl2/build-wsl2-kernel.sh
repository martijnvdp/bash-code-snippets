#!/bin/bash
# script to build latest wsl2 kernel with custom options
#
# update wsl before running with: wsl --update

WSL_VER=$(curl https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest 2>/dev/null |jq -r '.tag_name')
WSL_BRANCH=$(curl https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest 2>/dev/null |jq -r '.target_commitish')
USERDIR=$(wslpath "$(wslvar USERPROFILE)")
URL=$(curl https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest 2>/dev/null |jq -r '.tarball_url')

# switch to home folder (build will fail in /mnt/c/users/user need linux fs)
cd /home/${USER}
sudo apt update && sudo apt install -y git build-essential flex bison dwarves libssl-dev libelf-dev python3
mkdir kernel-src
cd kernel-src
wget ${URL} -O kernel.tar.gz
tar --strip-components=1 -zxf kernel.tar.gz

# set custom version ( uname -r )
sed -i 's/-microsoft-standard-WSL2/-microsoft-WSL2-with-cilium/' Microsoft/config-wsl
# adds support for clientIP-based session affinity 
sed -i 's/# CONFIG_NETFILTER_XT_MATCH_RECENT is not set/CONFIG_NETFILTER_XT_MATCH_RECENT=y/' Microsoft/config-wsl
# required modules for Cilium
sed -i 's/# CONFIG_NETFILTER_XT_TARGET_CT is not set/CONFIG_NETFILTER_XT_TARGET_CT=y/' Microsoft/config-wsl
sed -i 's/# CONFIG_NETFILTER_XT_TARGET_TPROXY is not set/CONFIG_NETFILTER_XT_TARGET_TPROXY=y/' Microsoft/config-wsl

# build the kernel j<cpu cores>
make -j2 KCONFIG_CONFIG=Microsoft/config-wsl
# copy kernel image to user dir/kernel
mkdir ${USERDIR}/kernel  
sudo cp arch/x86/boot/bzImage ${USERDIR}/kernel
# create .wslconfig file and point kernel to newly build 
readarray -d / -t userdirarr <<< "$USERDIR"
cat << EOF >  ${USERDIR}/.wslconfig
[wsl2]
kernel=C:\\\\Users\\\\$( echo ${userdirarr[4]})\\\\kernel\\\\bzImage
EOF
# cleanup
cd ..
rm -rf kernel-src
# restart/shutdown wsl
cmd.exe /c "wsl --shutdown"
# start wsl and check version with uname -r