#!/bin/bash
# script to build latest wsl2 kernel with custom options
# it can run under wsl on windows
#
# copy the bzImage file and create a wsl config file: 
# example: C:\Users\userx\.wslconfig
# [wsl2]
# kernel=C:\\Users\\<your_user>\\bzImage
# 
# open powershell run:
# wsl --shutdown

WSL_VER=linux-msft-wsl-5.10.60.1
apt update && apt install -y git build-essential flex bison dwarves libssl-dev libelf-dev python3

mkdir src
cd src
git clone https://github.com/microsoft/WSL2-Linux-Kernel.git
git fetch --all --tags
git checkout tags/${WSL_VER} -b default

# adds support for clientIP-based session affinity 
sed -i 's/# CONFIG_NETFILTER_XT_MATCH_RECENT is not set/CONFIG_NETFILTER_XT_MATCH_RECENT=y/' Microsoft/config-wsl

# required modules for Cilium
sed -i 's/# CONFIG_NETFILTER_XT_TARGET_CT is not set/CONFIG_NETFILTER_XT_TARGET_CT=y/' Microsoft/config-wsl
sed -i 's/# CONFIG_NETFILTER_XT_TARGET_TPROXY is not set/CONFIG_NETFILTER_XT_TARGET_TPROXY=y/' Microsoft/config-wsl

# build the kernel j<cpu cores>
make -j6 KCONFIG_CONFIG=Microsoft/config-wsl