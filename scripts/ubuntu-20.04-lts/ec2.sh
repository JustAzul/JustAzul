#!/bin/bash

# Update and Upgrade
sudo apt-get update -y && sudo apt-get upgrade -y

# Set Time Zone
curl https://raw.githubusercontent.com/JustAzul/JustAzul/main/ubuntu-20.04-lts/timezone.sh | bash

# Create Swap
curl https://raw.githubusercontent.com/JustAzul/JustAzul/main/scripts/swap.sh | bash

# Install CloudWatch Agent
curl https://raw.githubusercontent.com/JustAzul/JustAzul/main/ubuntu-20.04-lts/aws/cloudwatch-agent.sh | bash

# Install CodeDeploy
curl https://raw.githubusercontent.com/JustAzul/JustAzul/main/ubuntu-20.04-lts/aws/codedeploy-agent.sh | bash

# Install NodeJS, PM2, pm2-logrotate, and Enable PM2 on Startup
curl https://raw.githubusercontent.com/JustAzul/JustAzul/main/scripts/node.sh | bash

# Clean Up
sudo apt-get autoremove -y && sudo apt-get autoclean -y && sudo apt-get clean -y