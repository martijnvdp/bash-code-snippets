#!/bin/bash
# script to build latest wsl2 kernel with custom options
# run with wsl on windows ( fsutil.exe file setCaseSensitiveInfo src enable)
#
# update wsl before running with: wsl --update
#
# copy the bzImage file and create a wsl config file: 
# example: C:\Users\userx\.wslconfig
# [wsl2]
# kernel=C:\\Users\\<your_user>\\kernel\\bzImage
# 
# open powershell run:
# wsl --shutdown

WSL_VER=linux-msft-wsl-5.10.102.1
WSL_BRANCH=linux-msft-wsl-5.10.y
USERDIR=$(wslpath "$(wslvar USERPROFILE)")

# switch to home folder (build will fail in /mnt/c/users/user need linux fs)
cd /home/${USER}
sudo apt update && sudo apt install -y git build-essential flex bison dwarves libssl-dev libelf-dev python3
mkdir src
cd src
git init
git remote add origin https://github.com/microsoft/WSL2-Linux-Kernel.git
git config --local gc.auto 0
git -c protocol.version=2 fetch --no-tags --prune --progress --no-recurse-submodules --depth=1 origin +${WSL_VER}:refs/remotes/origin/build/linux-msft-wsl-5.10.y
git checkout --progress --force -B build/${WSL_BRANCH} refs/remotes/origin/build/${WSL_BRANCH}

# adds support for clientIP-based session affinity 
sed -i 's/# CONFIG_NETFILTER_XT_MATCH_RECENT is not set/CONFIG_NETFILTER_XT_MATCH_RECENT=y/' Microsoft/config-wsl
# required modules for Cilium
sed -i 's/# CONFIG_NETFILTER_XT_TARGET_CT is not set/CONFIG_NETFILTER_XT_TARGET_CT=y/' Microsoft/config-wsl
sed -i 's/# CONFIG_NETFILTER_XT_TARGET_TPROXY is not set/CONFIG_NETFILTER_XT_TARGET_TPROXY=y/' Microsoft/config-wsl

# build the kernel j<cpu cores>
make -j2 KCONFIG_CONFIG=Microsoft/config-wsl
# copy kernel image to user dir/kernel
mkdir ${USERDIR}/kernel
cp arch/x86/boot/bzImage ${USERDIR}/kernel
# create .wslconfig file and point kernel to newly build 
readarray -d / -t userdirarr <<< "$USERDIR"
cat << EOF >  ${USERDIR}/.wslconfig
[wsl2]
kernel=C:\\Users\\${userdirarr[4]}\\kernel\\bzImage
EOF
# restart/shutdown wsl
cmd.exe /c "wsl --shutdown"