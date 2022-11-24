#!/bin/bash

AMASS_SPLIT_RATIO=60
PARTNER_NAME="scanner"
PARTNER_IP_ADDRESS="65.2.171.175"
MY_NAME="fuzzer"

subdomains(){
    echo '[*]Starting subdomain discovery'
    cat $1 | xargs -n1 -I{} recon.py {} >> domains
    cat $1 | xargs -n1 -I{} subfinder -silent -d {} >> domains
    cat $1 | xargs -n1 -I{} findomain -q -t {} >> domains
}

check_files(){
    echo "[*]Waiting to receive data"
    while true
    do
        if [ -f $PARTNER_NAME ];then
            sleep 3
            break
        fi
        sleep 5
    done

    cat $PARTNER_NAME >> domains
    rm $PARTNER_NAME
}

check_file(){
    echo "[*]Waiting for $1"
    while true
    do
        if [ -f $1 ];then
            sleep 3
            break
        fi
        sleep 3
    done
}

send_data(){
    echo '[*]Sending data to '$PARTNER_NAME
    scp -i ~/tools/server/$PARTNER_NAME.pem $1 ubuntu@$PARTNER_IP_ADDRESS:/home/ubuntu/recon
}

splitfam(){
    mv $1 tempf
    split -l $[ $(wc -l tempf|cut -d" " -f1) * $AMASS_SPLIT_RATIO / 100 ] tempf
    mv xaa $1
    mv xab $1-2
}

amr(){
#echo '[*]Starting subfinder-all'
echo '[*]Starting amass'
for i in $(cat $1)
    do
	    #amass enum -passive -nocolor -nolocaldb -config ~/tools/amass/config.ini -d $i
        subfinder -silent -all -d $i
    done >> domains
}

subs(){
    echo '[*]Starting subdomain discovery'
    cat $1 | xargs -n1 -P4 -I{} subfinder -silent -d {} >> domains
}

#start
check_file root
check_file out-of-scope

#Send data to partner
send_data root

#Discovery on root domains
echo '[*]Starting discovery on root domains'
subdomains root
check_files

#cleaning domains
echo '[*]Cleaning domains'
sanitizer.py root domains | sort -u > t
rm domains
join.py out-of-scope | sed 's/,/|/g' | xargs -n1 -I{} sh -c "cat t | grep -avE '^({})$'" | sort -u > domains

echo '[*]Done collecting domains...'
