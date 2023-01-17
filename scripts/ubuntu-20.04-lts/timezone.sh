#!/bin/bash

echo "Current timezone: $(date +%Z)"

options=(
  "-0"
  "-1"
  "-2"
  "-3"
  "-4"
  "-5"
  "-6"
  "-7"
  "-8"
  "-9"
  "-10"
  "-11"
  "-12"
  "-13"
  "-14"
  "+0"
  "+1"
  "+2"
  "+3"
  "+4"
  "+5"
  "+6"
  "+7"
  "+8"
  "+9"
  "+10"
  "+11"
  "+12"
)
PS3='Please select your timezone: '
select opt in "${options[@]}"
do
    timezone="Etc/GMT${opt##* }"

    # Confirm the change
    read -p "Do you want to change timezone to $timezone? [y/n]" -n 1 -r
    echo   
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Change the timezone
        sudo ln -fs /usr/share/zoneinfo/$timezone /etc/localtime && sudo dpkg-reconfigure -f noninteractive tzdata
        echo "Timezone changed to $timezone"
    else
        echo "Timezone not changed"
    fi
    break
done
