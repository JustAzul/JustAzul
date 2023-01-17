#!/bin/bash
sudo apt-get update
sudo apt-get -y upgrade
sudo ln -fs /usr/share/zoneinfo/America/Recife /etc/localtime 
sudo dpkg-reconfigure -f noninteractive tzdata
curl https://raw.githubusercontent.com/JustAzul/JustAzul/main/scripts/swap.sh | bash
