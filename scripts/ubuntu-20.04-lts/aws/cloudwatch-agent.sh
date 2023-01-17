#!/bin/bash

# Create Temp Folder
mkdir ~/amazon-cloudwatch-agent && cd ~/amazon-cloudwatch-agent

# Install CloudWatch Agent
wget https://s3.us-east-1.amazonaws.com/amazoncloudwatch-agent-us-east-1/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
sudo mkdir -p /usr/share/collectd/ && sudo touch /usr/share/collectd/types.db
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-linux

# Clean Up
cd ~ && rm -rf ~/amazon-cloudwatch-agent