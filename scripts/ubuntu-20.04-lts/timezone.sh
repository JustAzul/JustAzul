#!/bin/bash

current_timezone=$(date +%Z)
echo "Current timezone: $current_timezone"

PS3='Please select your timezone: '
options=("America/Recife" "America/New_York" "Asia/Tokyo" "Europe/Berlin" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "America/Recife")
            timezone="America/Recife"
            break
            ;;
        "America/New_York")
            timezone="America/New_York"
            break
            ;;
        "Asia/Tokyo")
            timezone="Asia/Tokyo"
            break
            ;;
        "Europe/Berlin")
            timezone="Europe/Berlin"
            break
            ;;
        "Quit")
            exit 0
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

sudo ln -fs /usr/share/zoneinfo/$timezone /etc/localtime && sudo dpkg-reconfigure -f noninteractive tzdata