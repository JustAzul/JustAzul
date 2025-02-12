#!/bin/sh
set -e

echo "Updating package lists..."
apt-get update

echo "Installing awscli and s3fs..."
apt-get install -y awscli s3fs

echo "Creating the s3fs credentials file..."
echo "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" > /etc/passwd-s3fs
chmod 600 /etc/passwd-s3fs

mkdir -p /app/config /app/logs /app/plugins

echo "Mounting the S3 bucket directories..."
s3fs ${S3_BUCKET}:/${ASF_PROFILE}/config /app/config -o url=https://s3.${AWS_REGION}.amazonaws.com -o use_path_request_style -o allow_other -o rw
s3fs ${S3_BUCKET}:/${ASF_PROFILE}/logs /app/logs -o url=https://s3.${AWS_REGION}.amazonaws.com -o use_path_request_style -o allow_other -o rw
s3fs ${S3_BUCKET}:/${ASF_PROFILE}/plugins /app/plugins -o url=https://s3.${AWS_REGION}.amazonaws.com -o use_path_request_style -o allow_other -o rw

echo "Launching ArchiSteamFarm..."
"../asf/ArchiSteamFarm"
