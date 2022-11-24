#!/bin/bash

PARTNER_NAME="fuzzer"
PARTNER_IP_ADDRESS="13.126.105.35"
MY_NAME="scanner"


check_file(){
    echo "[*]Waiting for $1"
    while true
    do
        if [ -f $1 ];then
            sleep 3
            break
        fi
        sleep 5
    done
}

send_data(){
    echo '[*]Sending data to '$PARTNER_NAME
    scp -i ~/tools/server/$PARTNER_NAME.pem $1 ubuntu@$PARTNER_IP_ADDRESS:/home/ubuntu/recon
}


amr(){
echo '[*]Starting subfinder-all'
#echo '[*]Starting amass'
for i in $(cat $1)
    do
	    #amass enum -passive -nocolor -nolocaldb -config ~/tools/amass/config.ini -d $i
        subfinder -silent -all -d $i
    done >> $MY_NAME
}

subs(){
    echo '[*]Starting subdomain discovery'
    cat $1 | xargs -n1 -I{} -P4 subfinder -silent -d {} >> $MY_NAME
}


run(){
  check_file $1
  amr $1
  send_data $MY_NAME
  rm $MY_NAME
  rm $1
}

#start
run root

echo '[*]Done collecting domains'
