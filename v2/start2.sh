#!/bin/bash

banner(){
  echo "[*]New session started!"
  echo "+------------------------------------------+"
  printf "| %-40s |\n" "`date`"
  echo "|                                          |"
  printf "|`tput bold` %-40s `tput sgr0`|\n" "$@"
  echo "+------------------------------------------+"
}

while :
do
  cd ~/recon
  banner
  recon2.sh
  enum2.sh
  clear
done
