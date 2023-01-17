#!/bin/bash

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