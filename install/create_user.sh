#!/bin/env bash

##################################################################################
# This is the entry point for configuring the system.                            #
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox   #
# Updated by Afiniel for yiimpool use...                                         #
##################################################################################

source /etc/yiimpoolversion.conf
source /etc/functions.sh
cd ~/yiimp_install_script/install
clear

# Welcome
message_box "Yiimpool Installer $VERSION" \
"Hello and thanks for using the Yiimpool Yiimp Installer!
\n\nInstallation for the most part is fully automated. In most cases any user responses that are needed are asked prior to the installation.
\n\nNOTE: You should only install this on a brand new Ubuntu 20.04 , Ubuntu 18.04 or Ubuntu 16.04 installation."

# Root warning message box
message_box "Yiimpool Installer $VERSION" \
"WARNING: You are about to run this script as root!
\n\n The program will create a new user account with sudo privileges. 
\n\nThe next step, you will be asked to create a new user account, you can name it whatever you want."

# Ask if SSH key or password user
dialog --title "Create New User With SSH Key" \
--yesno "Do you want to create new user with SSH key login?
Selecting no will create user with password login only." 7 60
response=$?
case $response in
0) UsingSSH=yes ;;
1) UsingSSH=no ;;
255) echo "[ESC] key pressed." ;;
esac

# If Using SSH Key Login
if [[ ("$UsingSSH" == "yes") ]]; then
    clear
    if [ -z "${yiimpadmin:-}" ]; then
        DEFAULT_yiimpadmin=yiimpadmin
        input_box "New username" \
            "Please enter your new  username.
      \n\nUser Name:" \
            ${DEFAULT_yiimpadmin} \
            yiimpadmin

        if [ -z "${yiimpadmin}" ]; then
            # user hit ESC/cancel
            exit
        fi
    fi

    if [ -z "${ssh_key:-}" ]; then
        DEFAULT_ssh_key=PublicKey
        input_box "Please open PuTTY Key Generator on your local machine and generate a new public key." \
            "To paste your Public key use ctrl shift right click.
      \n\nPublic Key:" \
            ${DEFAULT_ssh_key} \
            ssh_key

        if [ -z "${ssh_key}" ]; then
            # user hit ESC/cancel
            exit
        fi
    fi

    # create random user password
    RootPassword=$(openssl rand -base64 8 | tr -d "=+/")
    clear

    # Add user
    echo -e "$YELLOW => Adding new user and setting SSH key... <= $COL_RESET"
    sudo adduser ${yiimpadmin} --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
    echo -e "${RootPassword}\n${RootPassword}" | passwd ${yiimpadmin}
    sudo usermod -aG sudo ${yiimpadmin}
    
    # Create SSH Key structure
    mkdir -p /home/${yiimpadmin}/.ssh
    touch /home/${yiimpadmin}/.ssh/authorized_keys
    chown -R ${yiimpadmin}:${yiimpadmin} /home/${yiimpadmin}/.ssh
    chmod 700 /home/${yiimpadmin}/.ssh
    chmod 644 /home/${yiimpadmin}/.ssh/authorized_keys
    authkeys=/home/${yiimpadmin}/.ssh/authorized_keys
    echo "$ssh_key" >"$authkeys"

    # enabling yiimpool command
    echo '# yiimp
  # It needs passwordless sudo functionality.
  '""''"${yiimpadmin}"''""' ALL=(ALL) NOPASSWD:ALL
  ' | sudo -E tee /etc/sudoers.d/${yiimpadmin} >/dev/null 2>&1

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
    PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee /etc/yiimpool.conf >/dev/null 2>&1

    # Set Donor Addresses
    echo 'BTCDON="3FrWuT56pXt9gf6fMSmzFfLSAW4SRo1hR7"
    LTCDON="ltc1qtegquuq9cnuytxdl3q3uxygdl8ga24pdwyjxrq"
    ETHDON="0x209357b29c16884a24498c3fa1c1474ffc7b6f33"
    BCHDON="1Ccoecv5As66cHbPzEhDj1iJvxAS1MmvZU"
    DOGEDON="DKAC7yG8tAgidsh4Fwk9CdSnMc2d6o7abh"' | sudo -E tee /etc/yiimpooldonate.conf >/dev/null 2>&1


    sudo cp -r ~/yiimp_install_script /home/${yiimpadmin}/
    cd ~
    sudo setfacl -m u:${yiimpadmin}:rwx /home/${yiimpadmin}/yiimp_install_script
    sudo rm -r $HOME/yiimpool
    clear
    echo -e "$YELLOW New User:$MAGENTA ${yiimpadmin} $GREEN created!$YELLOW Make sure you save your$RED private key!$COL_RESET"
    echo
    echo -e "$RED Please reboot system and log in as $GREEN ${yiimpadmin} $RED and type$GREEN yiimpool$RED to$GREEN continue$YELLOW setup...$COL_RESET"
    exit 0
fi

# New User Password Login Creation
if [ -z "${yiimpadmin:-}" ]; then
    DEFAULT_yiimpadmin=yiimpadmin
    input_box "Creaete new username" \
        "Please enter your new username.
  \n\nUser Name:" \
        ${DEFAULT_yiimpadmin} \
        yiimpadmin

    if [ -z "${yiimpadmin}" ]; then
        # user hit ESC/cancel
        exit
    fi
fi

if [ -z "${RootPassword:-}" ]; then
    DEFAULT_RootPassword=$(openssl rand -base64 8 | tr -d "=+/")
    input_box "User Password" \
        "Enter your new user password or use this randomly system generated one.
  \n\nUnfortunatley dialog doesnt let you copy. So you have to write it down.
  \n\nUser password:" \
        ${DEFAULT_RootPassword} \
        RootPassword

    if [ -z "${RootPassword}" ]; then
        # user hit ESC/cancel
        exit
    fi
fi

clear

dialog --title "Verify Your input" \
    --yesno "Please verify your answers before you continue:
New User Name : ${yiimpadmin}
New User Pass : ${RootPassword}" 8 60

# Get exit status
# 0 means user hit [yes] button.
# 1 means user hit [no] button.
# 255 means user hit [Esc] key.
response=$?
case $response in

0)
    clear
    echo -e "$YELLOW => Adding new user and password... <= $COL_RESET"

    sudo adduser ${yiimpadmin} --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
    echo -e ""${RootPassword}"\n"${RootPassword}"" | passwd ${yiimpadmin}
    sudo usermod -aG sudo ${yiimpadmin}

    # enabling yiimpool command
    echo '# yiimp
    # It needs passwordless sudo functionality.
    '""''"${yiimpadmin}"''""' ALL=(ALL) NOPASSWD:ALL
    ' | sudo -E tee /etc/sudoers.d/${yiimpadmin} >/dev/null 2>&1

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

    PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee /etc/yiimpool.conf >/dev/null 2>&1

    # Set Donor Addresses
  echo 'BTCDON="3FrWuT56pXt9gf6fMSmzFfLSAW4SRo1hR7"
LTCDON="ltc1qtegquuq9cnuytxdl3q3uxygdl8ga24pdwyjxrq"
ETHDON="0x209357b29c16884a24498c3fa1c1474ffc7b6f33"
BCHDON="1Ccoecv5As66cHbPzEhDj1iJvxAS1MmvZU"
DOGEDON="DKAC7yG8tAgidsh4Fwk9CdSnMc2d6o7abh"' | sudo -E tee /etc/yiimpooldonate.conf >/dev/null 2>&1


    sudo cp -r ~/yiimp_install_script /home/${yiimpadmin}/
    cd ~
    sudo setfacl -m u:${yiimpadmin}:rwx /home/${yiimpadmin}/yiimp_install_script
    sudo rm -r $HOME/yiimp_install_script
    clear
    echo -e "$YELLOW New User:$MAGENTA ${yiimpadmin} $GREEN created$RED $COL_RESET"
    echo
    echo -e "$YELLOW Please$RED reboot$YELLOW system and log in as the new user:$MAGENTA ${yiimpadmin} $YELLOW and type$GREEN yiimpool$YELLOW to$GREEN continue$YELLOW setup.$COL_RESET"
    exit 0
    ;;

1)

    clear
    bash $(basename $0) && exit
    ;;

255) ;;

esac
