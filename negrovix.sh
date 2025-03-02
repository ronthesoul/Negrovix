#!/usr/bin/env bash
###########################
# Written by: Ron Negron
# Date: 28.02
# Purpose: A tool to create an Nginx config file
# Version: 0.0.5
###########################

function main() {
    domain=""
    config_file=""
    dfile="index.html"
    ssl_cert=""
    ssl_key=""
    ssl_enabled=1
    udir=""
    uroot=""
    u_enabled=1
    htpasswd_file="/etc/nginx/.htpasswd"
    htpasswd_url_path=""
    htpasswd_user=""
    htpasswd_password=""
    htpasswd_enabled=1

    
    for index in nginx apache2-utils nginx-extras; do
        check_and_install "$index"
    done

    while getopts "d:s:f:u:a:h" opt; do
        case $opt in
            d)
                domain="$OPTARG"
                if [[ -z "$domain" ]]; then
                    echo "Syntax Error: -d <domain>"
                    exit 1
                fi
                config_file="/etc/nginx/sites-available/$domain"
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
            f)
                dfile="$OPTARG"
                if [[ -z "$dfile" ]]; then
                    echo "Syntax Error: -f <main html file>"
                    exit 1
                fi
                ;;
            u)
                if [[ "$OPTARG" != *:* ]]; then
                    echo "Syntax Error: -u <user root>:<user dir>"
                    exit 1
                fi
                IFS=":" read -r uroot udir <<< "$OPTARG"
                if [[ -z "$uroot" || -z "$udir" || ! -e "$udir" ]]; then
                    echo "Syntax Error: -u <user root>:<user dir>"
                    echo "Hint: Validate that your user directory exists"
                    exit 1
                fi
                u_enabled=0
                ;;
            a)
                if [[ ! "$OPTARG" =~ ^[^:]+:[^:]+:[^:]+$ ]]; then
                    echo "Syntax Error: -a <url_path>:<username>:<password>"
                    exit 1
                fi
                IFS=":" read -r htpasswd_url_path htpasswd_user htpasswd_password <<< "$OPTARG"
                if [[ -z $htpasswd_url_path || -z $htpasswd_user || -z $htpasswd_password ]]; then
                    echo "Syntax Error: -a <url_path>:<username>:<password>"
                    exit 1
                fi
                htpasswd_enabled=0
                ;;
            h | *)
                echo "Usage: $0 -d <domain> [-s <certfile>:<keyfile>] [-f <main html file>] [-u <user root>:<user dir>] [-a <url_path>:<username>:<password>]"
                exit 1
                ;;
        esac
    done

    
    if [[ -z "$domain" ]]; then
        echo "Error: -d (domain) is required"
        exit 1
    fi


if [[ $ssl_enabled -eq 1 ]]; then
    http_opts $domain $dfile $rootdir $config_file
else
    https_opts $domain $dfile $ssl_key $ssl_cert $rootdir $config_file
fi

if [[ $u_enabled -eq 0 ]]; then
    user_dir_opts $udir $uroot $config_file
fi

if [[ $htpasswd_enabled -eq 0 ]]; then

    auth_opts $htpasswd_file $htpasswd_url_path $htpasswd_user $htpasswd_password $config_file
fi

echo "}" >> $config_file

create_link $config_file
restart_nginx

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

cat << EOF > $oconfig_file
server {
    listen 80;
    server_name $odomain;
    return 301 https://\$host\$request_uri;
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
        try_files \$uri \$uri/ =404;
    }
EOF
}

function http_opts(){
odomain=$1
ofile=$2
oroot_dir=$3
oconfig_file=$4

cat << EOF > $oconfig_file
server {
        listen 80;
        listen [::]:80;

        server_name $odomain;

        root $oroot_dir;
        index $ofile;

        location / {
                try_files \$uri \$uri/ =404;
        }
EOF
}


function user_dir_opts(){
ouser_dir=$1
ouser_root=$2
oconfig_file=$3

cat << EOF >> $oconfig_file

    location $ouser_root ^/~(.+?)(/.*)?$ {
    alias /home/\$1/$ouser_dir\$2;
}
EOF

    if [[ ! -e $ouser_dir ]]; then
    echo "Seems like $ouser_dir does not exist, would you like to create this directory? [y/n]"
    
    read -r user_input  

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        mkdir -p /home/$USER/$ouser_dir
        chmod 755 /home/$USER/$ouser_dir
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

function auth_opts(){
oh_file=$1
oh_path=$2
oh_user=$3
oh_password=$4
oh_config_file=$5

if  ! htpasswd -b -c "$oh_file" "$oh_user" "$oh_password" ; then
    echo "An error happend during htpasswd creation, please check your syntax and run the script agian. -h for help menu"
fi
mkdir -p /var/www/"$oh_path"

cat << EOF >> $oh_config_file
location $oh_path{
    auth_basic "Restricted Area";
    auth_basic_user_file "$oh_file";
    root /var/www/"$oh_path";
    index index.html;

}
EOF
}


function check_syntax() {
    if sudo nginx -t 2>&1 | grep -E "syntax is ok|test is successful"; then
        echo "Syntax and test are golden"
        return 0
    else
        echo "You should check your configuration file for any incorrect inputs"
        return 1
    fi
}

function restart_nginx() {
        read -p "Would you like to restart nginx [y/n]: " user_input
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
            sudo service nginx restart
        elif [[ "$user_input" == "n" || "$user_input" == "N" ]]; then
            echo "Restart was not required, exiting script"
            return 0
        else
            echo "Invalid input. Please enter y or n."
            return 1
        fi
}

function create_link (){
oconfig=$1 
if check_syntax; then
    read -p "Would you like to create a symlink [y/n]: " user_input
    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
    ln -s "$oconfig" /etc/nginx/sites-enabled/
    echo "Symlink was created at /etc/nginx/sites-enabled/"
        elif [[ "$user_input" == "n" || "$user_input" == "N" ]]; then
         echo "Creating a link was not required exiting script"   
     else 
         echo "Invalid input. Please enter y or n."
    fi
else
    echo "Please check your coniguration file for any incorrect syntax link was not established"
fi
}

main "$@"
