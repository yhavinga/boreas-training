#!/bin/bash
#set -e
cd "$(dirname "$0")"
#
## Install Python 3.11 and its tools
#sudo apt install software-properties-common -y
#sudo add-apt-repository ppa:deadsnakes/ppa -y
#sudo apt-get -y update
#sudo apt install python3.11 python3.11-distutils python3.11-venv -y
#
### Link python3 or python to python3.11
#sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
##sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

wget https://bootstrap.pypa.io/get-pip.py
sudo python3 get-pip.py

if [ -n "$(lspci | grep Google)" ]; then
  echo -e "\033[0;31mUsing TPU\033[0m"
  sudo python3 -m pip uninstall tensorboard tbp-nightly tb-nightly tensorboard-plugin-profile -y
  sudo apt-get -y update
  sudo apt-get -y install git-lfs ncdu mc joe
  sudo apt-get install golang -y
  sudo apt-get install -y python3.10-venv
fi

# if venv does not exists, create it
if [ ! -d venv ]; then
    python3.10 -m venv venv
fi
. venv/bin/activate
pip install --upgrade pip


