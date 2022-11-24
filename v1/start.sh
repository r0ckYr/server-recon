#!/bin/bash

now=$(date +'%d/%m/%Y' | sed 's/\//-/g')

banner(){
    echo "[*]New session started!:- Date: [$now]  Program: [$2]"
  echo "+------------------------------------------+"
  printf "| %-40s |\n" "`date`"
  echo "|                                          |"
  printf "|`tput bold` %-40s `tput sgr0`|\n" "$@"
  echo "+------------------------------------------+"
}



if [ $# != 1 ]
then
  echo "Usage: start.sh <program name>"
  exit 1
else
  banner $now $1
fi

recon.sh
enum.sh

cd ~/
mv recon $now
tar -czf $1.tar.gz $now
rm -rf $now
mkdir recon
echo "Done recon on $1" | notify.py
