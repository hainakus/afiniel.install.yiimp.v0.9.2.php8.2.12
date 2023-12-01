#!/usr/bin/env bash
#########################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by Afiniel for Yiimpool use...
# This script is intended to be run like this:
#
# curl https://raw.githubusercontent.com/Filnet82/afiniel.install.yiimp.v0.9.2.php8.2.12/main/install.sh | bash
#
#########################################################

if [ -z "${TAG}" ]; then
	TAG=v0.9.2
fi

echo 'VERSION='"${TAG}"'' | sudo -E tee /etc/yiimpoolversion.conf >/dev/null 2>&1

# Clone the Yiimp Install Script repository if it doesn't exist.
if [ ! -d $HOME/yiimp_install_script ]; then
	if [ ! -f /usr/bin/git ]; then
		echo Installing git . . .
		apt-get -q -q update
		DEBIAN_FRONTEND=noninteractive apt-get -q -q install -y git < /dev/null
		clear
		echo

	fi

	echo Downloading Yiimpool Installer ${TAG}. . .
	git clone https://github.com/hainakus/afiniel.install.yiimp.v0.9.2.php8.2.12.git \
		"$HOME"/yiimp_install_script \
		< /dev/null 2> /dev/null

	echo
fi


cd $HOME/yiimp_install_script/

# Update it.
sudo chown -R $USER $HOME/yiimp_install_script/.git/


# Start setup script.
bash $HOME/yiimp_install_script/install/start.sh
