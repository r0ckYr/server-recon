#!/bin/bash

AMASS_SPLIT_RATIO=55
PARTNER_NAME="scanner"
PARTNER_IP_ADDRESS="65.2.171.175"
MY_NAME="fuzzer"

check_file(){
    echo "[*]Waiting to receive $1"
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

gurls(){
  for i in $(cat $1)
  do
    gauplus $i
  done >> urls
}

#send domains to scanner
send_data domains

#hunter.py on domains
number_of_lines=`wc --lines < domains`
if [[ $number_of_lines -gt 1 ]]
then
    mkdir out
    mkdir out/text
    mkdir out/vulns
    echo '[*]Starting httpx'
    httpx -cl -sr -srd out/text -location -fr -sc -td -silent -title -nc -t 100 -l domains > out/index
    cat out/index | awk '{print $1}' | sort -u > active-domains
    cat active-domains | getJS --complete > out/jsfiles
else
    echo '[*]Starting hunter.py'
    hunter.py --no-redirect -p 443,80,8443 -timeout 10 -t 100 domains > /dev/null
    cat out/index | awk '{print $1}' | sort -u > active-domains
fi



##geturls.py on active-domains
check_file dns
number_of_domains=`wc --lines < dns`
if [[ $number_of_domains -gt 800 ]]
then
    echo '[*]Starting gauplus'
    gurls dns
    cp urls urls2
    cat urls | grep -a "=" | grep -vaE "\.(gif|jpeg|css|tif|tiff|png|woff|jpg|ico|pdf|svg|txt|js)" > u
    rm urls
    mv u urls

    #get all js files
    echo '[*]Getting jsfiles urls'
    cat urls2 | grep -aE '\.js' | grep -avE '\.json|\.jsp' | sort -u > out/jsfiles2
else
    echo '[*]Too many domains skipping gauplus'
fi


#sort jsfiles
cd out
cat jsfiles | sort -u > j
rm jsfiles
mv j jsfiles

#download files
echo '[*]Downloading jsfiles'
mkdir scripts/
cat jsfiles | httpx -fl 0 -mc 200 -content-length -sr -srd scripts/ -silent -no-color > jsindex
cd ~/recon

#httpx
echo '[*]Starting httpx to find files'
httpx -path ~/tools/tools/files/secret-files -fr -l active-domains -sc -nc -title -cl -location -silent -t 200 -td > httpd
cat httpd | awk '{gsub("\\[", "", $4);gsub("\\]", "", $4);print $4"  "$0}' | sort -u | sort -n > sortd
guniq 3 httpd | sort -n > uniqd

#httpx on ips filter output
check_file httpip
cat httpip | awk '{gsub("\\[", "", $4);gsub("\\]", "", $4);print $4"  "$0}' | sort -u | sort -n > sortip
guniq 3 httpip | sort -n > uniqhip

#check for ports-scan files
check_file ip_addresses
check_file resp
check_file ips
check_file masscan-all-ports

echo '[*]Creating ports file'
ports.sh > ports

echo '[*]Done...'
