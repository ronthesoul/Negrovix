#!/usr/bin/env bash
###########################
#Written by: Ron Negron
#Date: 28.02
#Purpose: A tool that is made to create nginx config file
#Version:0.0.1
##########################


function main(){
    
domain=""
confile_file="/etc/nginx/sites-available/$domain"
dfile="index.html"
proto="listen 80 default_server;"
ssl_cert=""
ssl_key=""
ssl_enabled=1


    for index in nginx apache2-utils nginx-extras;  do
    check_and_install "$index"
done

while getopts "d:s:f:u:c:a:h" opt; do
    case $opt in
        d) $domain="$OPTARG"
           if [[ -z "$domain" ]];
           then
               echo "Syntax Error: -d <domain>"
               exit 1
           fi ;;
        s)
          if [["$OPTARG" != *:*]];
          then
              echo "Syntax Error: -s <certfile>:<keyfile>"
              exit 1
          fi
           IFS=":" read -r ssl_cert ssl_key <<< "$OPTARG"
           if [[ -z "$ssl_cert" || -z "$ssl_key" ]];
           then 
               echo "Syntax Error: -s <certfile>:<keyfile>" 
               fi
             $proto="listen 443 ssl"
             $ssl_enabled=0 ;;

         f) $dfile = $OPTARG
             if [[ -z "$dfile" ]];
             then
                 echo "Syntax Error: -f <main html file>"
                 exit 1
             fi ;;



           


    esac

rootdir="/var/www/$domain"



 if [[ -z domain ]];
 then
     echo "Error -d (domain) is requied"
     exit 1
 fi

}


function check_and_install(){
    package=$1
        if ! dpkg -l | grep -q "^ii  $package "; then
            sudo apt install $package -y
            return 1
        else
            return 0
        fi
    }
function 






}




