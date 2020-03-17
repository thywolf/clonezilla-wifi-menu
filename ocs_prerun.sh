#!/bin/bash

function get_wlan()
{
  rm /tmp/wlans 2>&1 > /dev/null
  iw dev | awk '$1=="Interface"{print $2}' > /tmp/wlans
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    dialog --clear --title "WiFi Setup" --msgbox "ERROR: No wireless interfaces found." 5 41
    return 1
  fi

  COUNT=0
  declare -a OPTIONS=()
  while read -r line; do
    OPTIONS+=($((++COUNT)) "$line")
  done < /tmp/wlans

  choice=$(dialog --clear --stdout --title "WiFi Setup" --menu "Select wireless interface:" 0 0 0 "${OPTIONS[@]}")
  if [ $? -ne 0 ]; then
    return 1
  fi

  WLAN="$(sed "$choice!d" /tmp/wlans)"
  dialog --infobox "Enabling $WLAN interface..." 3 41
  ifconfig $WLAN down 2>&1 /dev/null
  ifconfig $WLAN up 2>&1 /dev/null
  if [ $? -ne 0 ]; then
    dialog --clear --title "WiFi Setup" --msgbox "ERROR: An error occurred while enabling $WLAN interface." 6 41
    return 1
  fi
  return 0
}

function get_ssid()
{
  rm /tmp/ssids 2>&1 > /dev/null
  dialog --infobox "Searching for nearby WiFi networks..." 3 41
  iwlist $WLAN scan | awk -F ':' '/ESSID:/ {print $2;}' | sed -e s/\"//g > /tmp/ssids
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    dialog --clear --title "WiFi Setup" --msgbox "ERROR: An error occurred while scanning for WiFi networks." 6 41
    return 1
  fi

  COUNT=0

  declare -a OPTIONS=()
  while read -r line; do
    OPTIONS+=($((++COUNT)) "$line")
  done < /tmp/ssids

  if [ $COUNT -eq 0 ]; then
    dialog --clear --title "WiFi Setup" --msgbox "No Wifi networks nearby!" 5 41
    return 1
  fi

  choice=$(dialog --clear --stdout --title "WiFi Setup" --menu "Select SSID to connect to:" 0 0 0 "${OPTIONS[@]}")
  if [ $? -ne 0 ]; then
    return 1
  fi

  SSID="$(sed "$choice!d" /tmp/ssids)"

  return 0
}

function get_password()
{
  PASSWORD="$(dialog --clear --stdout --title "WiFi Setup" --insecure --passwordbox "Enter password for "$SSID":" 0 0)"

  if [ $? -ne 0 ]; then
    return 1
  fi

  return 0
}

function update_conf()
{
  dialog --infobox "Connecting..." 3 17
  wpa_passphrase $SSID $PASSWORD > /etc/wpa_supplicant.conf
  wpa_supplicant -B -D wext -i $WLAN -c /etc/wpa_supplicant.conf 2>&1 > /dev/null
  dhclient $WLAN 2>&1 > /dev/null
  return $?
}

function test_connection()
{
  HOST="$(dialog --clear --stdout --title "WiFi Setup" --inputbox "Enter remote host IP" 0 0 "192.168.0.1")"
  if [ $? -ne 0 ]; then
    return 1
  fi
  dialog --infobox "Pinging $HOST..." 3 30
  ping -c 1 $HOST 2>&1 > /dev/null
  if [ $? -ne 0 ]; then
    dialog --clear --title "WiFi Setup" --msgbox "Pinging "$HOST" failed!" 5 41
    return 1
  fi
  dialog --clear --title "WiFi Setup" --msgbox "Pinging "$HOST" OK!" 5 41
  return 0
}

while true; do
  choice=$(dialog --clear --stdout --no-cancel --title "WiFi Setup" --menu " " 0 0 0 1 "Setup WiFi" 2 "Test connection" 3 "Exit")

  case $choice in
      1)
        if get_wlan; then
          if get_ssid; then
            if get_password; then
              if update_conf; then
                if test_connection; then
                  exit
                fi
              fi
            fi
          fi
        fi
        ;;
      2)
        test_connection
        ;;
      3)
        exit
        ;;
    esac

done
s