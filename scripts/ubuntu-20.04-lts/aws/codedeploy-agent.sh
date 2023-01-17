#!/bin/bash

# Create Temp Folder
mkdir ~/amazon-codedeploy-agent && cd ~/amazon-codedeploy-agent

# Install Dependencies
sudo apt install ruby-full wget -y

# Install CodeDeploy
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto | tee -a /tmp/codedeploy-install.log

# Clean Up
cd ~ && rm -rf ~/amazon-codedeploy-agent