#!/bin/bash

PARTNER_NAME="fuzzer"
PARTNER_IP_ADDRESS="13.126.105.35"
MY_NAME="scanner"

check_file(){
    echo "[*]Waiting to receive $1"
    while true
    do
        if [ -f $1 ];then
            sleep 5
            break
        fi
        sleep 3
    done
}

send_data(){
    echo '[*]Sending data to '$PARTNER_NAME
    scp -i ~/tools/server/$PARTNER_NAME.pem $1 ubuntu@$PARTNER_IP_ADDRESS:/home/ubuntu/recon
    rm -rf $1
}

#dnsx on received domains
check_file domains
echo "[*]Starting dnsx"
dnsx -l domains -silent -resp >> resp
rm domains

#create required files
echo '[*]Generating files'
cat resp | awk '{print $2}' | tr -d '[]' | sort -u >> ips
cat ips | sort -u > t
rm ips
mv t ips
cat resp | awk '{print $1}' | sort -u >> dns

#send dns to fuzzer
send_data dns

#clean_ips
echo '[*]Removing cloudflare ips'
clean_ips.py ips | sort -u > ip_addresses

#masscan on ips
number_of_lines=`wc --lines < ip_addresses`
echo '[*]Starting masscan'

if [[ $number_of_lines -gt 1300 ]]
then
    sudo masscan -p1-1000,2075,2076,6443,3868,3366,8443,8080,9443,9091,3000,8000,5900,8081,6000,10000,8181,3306,5000,4000,8888,5432,15672,9999,161,4044,7077,4040,9000,8089,443,7447,7080,8880,8983,5673,7443,19000,1908,1000,4080 -iL ip_addresses --max-rate=1500 --open -oG masscan-all-ports
else
    sudo masscan -p1-65535 -iL ip_addresses --max-rate=1300 --open -oG masscan-all-ports
fi

#httpx on masscan output
echo '[*]Starting httpx on masscan output'
masscan2http.py masscan-all-ports | httpx -silent -nc -title -fr -td -sc -cl -location -t 100 >> http-result
cp http-result hr
send_data http-result
mv hr http-result

#httpx fuzz on ips
check_file http-result
cat http-result | awk '{print $1}' | httpx -path ~/tools/tools/files/secret-files -sc -nc -title -cl -location -silent -t 200 -td > httpip

#send data
send_data httpip
send_data masscan-all-ports
send_data resp
send_data ip_addresses
send_data ips
