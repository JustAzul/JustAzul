#!/bin/bash

# Set the timezone to America/Recife
sudo ln -fs /usr/share/zoneinfo/America/Recife /etc/localtime && sudo dpkg-reconfigure -f noninteractive tzdata