#!/bin/bash

# Check if user is root
if [ "$EUID" -ne 0 ]
then 
    echo "Please run as root"
    exit 1
fi

# Check if necessary tools and dependencies are installed
if ! command -v fallocate &> /dev/null; then
    echo "fallocate is not installed, installing it now..."
    if ! apt-get install -y fallocate; then
        echo "Failed to install fallocate, please install it manually"
        exit 1
    fi
fi

if ! command -v mkswap &> /dev/null; then
    echo "mkswap is not installed, installing it now..."
    if ! apt-get install -y util-linux; then
        echo "Failed to install mkswap, please install it manually"
        exit 1
    fi
fi

if ! command -v swapon &> /dev/null; then
    echo "swapon is not installed, installing it now..."
    if ! apt-get install -y util-linux; then
        echo "Failed to install swapon, please install it manually"
        exit 1
    fi
fi

# Check if swap is already enabled
if swapon --show | grep -q '/swap'; then
  echo "Swap is already enabled"
  exit 0
fi

# Prompt user for swap file size
read -p "Enter the size of the swap file in GB(default 2GB): " size
if [ -z "$size" ]; then
  size=2
fi

# Check available memory
free_mem=$(free -m | awk '/^Mem:/{print $4}')

if [ $free_mem -lt $(($size*1024)) ]; then
  echo "Not enough memory available"
  exit 1
fi

# Check available space in partition
partition=$(df / | awk '{print $1}' | tail -n 1)
avail_space=$(df -BG $partition | tail -n 1 | awk '{print $4}' | sed 's/G//')
if [ $(echo "$size > $avail_space" | bc) -eq 1 ]; then
  echo "Not enough free space in partition"
  exit 1
fi

# Check if swap file already exists
if [ -e /swap ]; then
  read -p "Swap file already exists, do you want to overwrite it? (y/n) " choice
  case "$choice" in
    y|Y ) echo "Overwriting existing swap file...";;
    n|N ) echo "Exiting script..."; exit 0;;
    * ) echo "Invalid input, exiting script..."; exit 1;;
  esac
fi

# Create swap file
if ! sudo fallocate -l ${size}G /swap; then
    echo "Failed to create swap file"
    exit 1
fi

# Set permissions to 600
if ! sudo chmod 600 /swap; then
    echo "Failed to set permissions on swap file"
    exit 1
fi

# Mark file as swap space
if ! sudo mkswap /swap; then
    echo "Failed to mark file as swap space"
    exit 1
fi

# Enable swap file
if ! sudo swapon /swap; then
    echo "Failed to enable swap file"
    exit 1
fi

# Add swap file to fstab
if ! echo '/swap swap swap defaults 0 0' | sudo tee -a /etc/fstab; then
    echo "Failed to add swap file to fstab"
    exit 1
fi

echo "Swap file created successfully"
exit 0
fi
