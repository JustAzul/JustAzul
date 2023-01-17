#!/bin/bash

# Update and Upgrade
sudo apt-get update -y && sudo apt-get upgrade -y

# Set Time Zone
sudo ln -fs /usr/share/zoneinfo/America/Recife /etc/localtime && sudo dpkg-reconfigure -f noninteractive tzdata

# Create Swap
curl https://raw.githubusercontent.com/JustAzul/JustAzul/main/swap.sh | bash

# Create Temp Folder
mkdir ~/temp && cd ~/temp

# Install CloudWatch Agent
wget https://s3.us-east-1.amazonaws.com/amazoncloudwatch-agent-us-east-1/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
sudo mkdir -p /usr/share/collectd/ && sudo touch /usr/share/collectd/types.db
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-linux

# Install Dependencies
sudo apt install ruby-full wget -y

# Install CodeDeploy
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto | tee -a /tmp/codedeploy-install.log

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
source ~/.bashrc

# Install Node
nvm i --lts=fermium

# Install PM2
npm i pm2 -g
pm2 install pm2-logrotate

# Enable PM2 on Startup
STARTUP_COMMAND=$(pm2 startup)
eval "$STARTUP_COMMAND"
pm2 save

# Clean Up
sudo apt-get autoremove -y && sudo apt-get autoclean -y && sudo apt-get clean -y
rm -rf ~/temp