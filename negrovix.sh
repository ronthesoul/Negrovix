#!/usr/bin/env bash
###########################
# Written by: Ron Negron
# Date: 28.02
# Purpose: A tool to create an Nginx config file
# Version: 0.0.3
###########################

function main() {
domain=""
confile_file=""
dfile="index.html"
ssl_cert=""
ssl_key=""
ssl_enabled=1
udir=""
uroot=""
u_enabled=1
htpasswd_file="/etc/nginx/htpasswd"

    
    for index in nginx apache2-utils nginx-extras; do
        check_and_install "$index"
    done

    # Parse options
    while getopts "d:s:f:u:c:a:h" opt; do
        case $opt in
            d) domain="$OPTARG"
               if [[ -z "$domain" ]]; then
                   echo "Syntax Error: -d <domain>"
                   exit 1
               fi
               confile_file="/etc/nginx/sites-available/$domain"
               rootdir="/var/www/$domain"
               ;;
            
            s) 
               if [[ "$OPTARG" != *:* ]]; then
                   echo "Syntax Error: -s <certfile>:<keyfile>"
                   exit 1
               fi

               IFS=":" read -r ssl_cert ssl_key <<< "$OPTARG"

               if [[ -z "$ssl_cert" || -z "$ssl_key" ]]; then
                   echo "Syntax Error: -s <certfile>:<keyfile>"
                   exit 1
               fi

               ssl_enabled=0 
               ;;
            
            f) dfile="$OPTARG"
               if [[ -z "$dfile" ]]; then
                   echo "Syntax Error: -f <main html file>"
                   exit 1
               fi
               ;;
           u) 
             if [[ -z "$OPTARG" != *:*  ]]; then
                echo "Syntax Error: -u <user root>:<user dir>"
               exit 1
             fi
            IFS=":" read -r $uroot $dir <<< "$OPTARG"
            if [[ -z "$uroot" || -z "$dir" || ! -e "$dir" ]]; then
                echo "Synatx Error: -u <user root>:<user dir>"
                echo "Hint: Validate that your user directory exists"
                exit 1
             fi
                $u_enabled=1
              ;;


                        






        esac
    done

    
    if [[ -z "$domain" ]]; then
        echo "Error: -d (domain) is required"
        exit 1
    fi


if [[ $ssl_enabled = 1]]; then
    http_opts $domain $dfile $rootdir $config_file
else:
    https_opts $domain $dfile $ssl_key $ssl_cert $rootdir $config_file
fi

if [[ $u_enabled = 0 ]]; then
    user_dir_opts $udir $uroot $config_file
fi










echo "}" >> $config_file

}


function check_and_install() {
    package=$1
    if ! dpkg -l | grep -q "^ii  $package "; then
        sudo apt install "$package" -y
        return 1
    else
        return 0
    fi
}


function https_opts(){
odomain=$1
ofile=$2
ossl_key=$3
ossl_cert=$4
oroot_dir=$5
oconfig_file=$6

cat << 'EOF' > $oconfig_file
server {
    listen 80;
    server_name $odomain;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    server_name $odomain;
    root $oroot_dir;
    index $ofile;

    ssl_certificate     "$ossl_cert";
    ssl_certificate_key "$ossl_key";
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;

    location / {
        try_files $uri $uri/ =404;
    }
EOF
}

function http_opts(){
odomain=$1
ofile=$2
oroot_dir=$3
oconfig_file=$4

cat << 'EOF' > $oconfig_file
server {
        listen 80;
        listen [::]:80;

        server_name $odomain;

        root $oroot_dir;
        index $ofile;

        location / {
                try_files $uri $uri/ =404;
        }
EOF    
}

function user_dir_opts(){
ouser_dir=$1
ouser_root=$2
oconfig_file=$3

cat << 'EOF' >> $oconfig_file

    location $ouser_root ^/~(.+?)(/.*)?$ {
    alias /home/\$1/$ouser_dir\$2;
}
EOF

    if [[ ! -e /home/$USER/$ouser_dir ]]; then
    echo "Seems like /home/$USER/$ouser_dir does not exist, would you like to create this directory? [y/n]"
    
    read -r user_input  

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        mkdir -p /home/$USER/$ouser_dir
        echo "Directory /home/$USER/$ouser_dir has been created."
    elif [[ "$user_input" == "n" || "$user_input" == "N" ]]; then
        echo "Directory not created."
    else
        echo "Invalid input. Please enter 'y' for Yes or 'n' for No."
    fi
fi

if [[ ! -e /etc/skel/$ouser_dir ]]; then
    echo "Would you also like to create /etc/skel/$ouser_dir? [y/n]"

    read -r skel_input  

    if [[ "$skel_input" == "y" || "$skel_input" == "Y" ]]; then
        sudo mkdir -p /etc/skel/$ouser_dir
        echo "Directory /etc/skel/$ouser_dir has been created."
    elif [[ "$skel_input" == "n" || "$skel_input" == "N" ]]; then
        echo "Directory in /etc/skel not created."
    else
        echo "Invalid input. Please enter 'y' for Yes or 'n' for No."
    fi
fi

}

function auth_opts()






main
