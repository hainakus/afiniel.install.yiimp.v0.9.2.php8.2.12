#!/bin/env bash

##################################################################################
# This is the entry point for configuring the system.                            #
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox   #
# Updated by Afiniel for yiimpool use...                                         #
##################################################################################

source /etc/functions.sh
cd ~/yiimp_install_script/install
clear

# Get logged in user name
whoami=`whoami`
echo -e " Modifying existing user $whoami for yiimpool support."
sudo usermod -aG sudo ${whoami}

echo '# yiimp
# It needs passwordless sudo functionality.
'""''"${whoami}"''""' ALL=(ALL) NOPASSWD:ALL
' | sudo -E tee /etc/sudoers.d/${whoami} >/dev/null 2>&1

echo '
cd ~/yiimp_install_script/install
bash start.sh
' | sudo -E tee /usr/bin/yiimpool >/dev/null 2>&1
sudo chmod +x /usr/bin/yiimpool

# Check required files and set global variables
cd $HOME/yiimp_install_script/install
source pre_setup.sh

# Create the STORAGE_USER and STORAGE_ROOT directory if they don't already exist.
if ! id -u $STORAGE_USER >/dev/null 2>&1; then
sudo useradd -m $STORAGE_USER
fi
if [ ! -d $STORAGE_ROOT ]; then
sudo mkdir -p $STORAGE_ROOT
fi

# Save the global options in /etc/yiimpool.conf so that standalone
# tools know where to look for data.
echo 'STORAGE_USER='"${STORAGE_USER}"'
STORAGE_ROOT='"${STORAGE_ROOT}"'
PUBLIC_IP='"${PUBLIC_IP}"'
PUBLIC_IPV6='"${PUBLIC_IPV6}"'
DISTRO='"${DISTRO}"'
FIRST_TIME_SETUP='"${FIRST_TIME_SETUP}"'
PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee /etc/yiimpool.conf >/dev/null 2>&1

# Set Donor Addresses
echo 'BTCDON="3FrWuT56pXt9gf6fMSmzFfLSAW4SRo1hR7"
LTCDON="ltc1qtegquuq9cnuytxdl3q3uxygdl8ga24pdwyjxrq"
ETHDON="0x209357b29c16884a24498c3fa1c1474ffc7b6f33"
BCHDON="1Ccoecv5As66cHbPzEhDj1iJvxAS1MmvZU"
DOGEDON="DKAC7yG8tAgidsh4Fwk9CdSnMc2d6o7abh"' | sudo -E tee /etc/yiimpooldonate.conf >/dev/null 2>&1

cd ~
sudo setfacl -m u:${whoami}:rwx /home/${whoami}/yiimp_install_script
clear
echo -e "$YELLOW Your User:$MAGENTA ${whoami}$YELLOW has been modified for yiimpool support. $COL_RESET"
echo -e "$YELLOW You must$RED reboot$YELLOW the system for the new permissions to update and type$GREEN yiimpool$YELLOW to continue setup...$COL_RESET"
exit 0
