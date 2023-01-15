#!/bin/bash

# Check if user is root
if [ "$EUID" -ne 0 ]
then 
    echo "Please run as root"
    exit 1
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

# Check available memory and swap space
free_mem=$(free -m | awk '/^Mem:/{print $4}')
free_swap=$(free -m | awk '/^Swap:/{print $4}')

if [ $free_mem -lt $(($size*1024)) ] && [ $free_swap -lt $(($size*1024)) ]; then
  echo "Not enough memory or swap space available"
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
