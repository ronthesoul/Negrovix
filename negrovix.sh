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
    uuser=""
    u_enabled=1
    htpasswd_file="/etc/nginx/.htpasswd"
    htpasswd_url_path=""
    htpasswd_user=""
    htpasswd_password=""
    htpasswd_enabled=1
    cgi_file=""
    cgi_enabled=1

cat << 'EOF'
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    __                          _
  /\ \ \___  __ _ _ __ _____   _(_)_  __
 /  \/ / _ \/ _` | '__/ _ \ \ / / \ \/ /
/ /\  /  __/ (_| | | | (_) \ V /| |>  <
\_\ \/ \___|\__, |_|  \___/ \_/ |_/_/\_\
            |___/
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
EOF

    
    for index in nginx apache2-utils nginx-extras python3 fcgiwrap spawn-fcgi; do
        check_and_install "$index"
    done

    while getopts "d:s:f:u:a:c:h" opt; do
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
                if [[ ! "$OPTARG" =~ ^[^:]+:[^:]+$ ]]; then
                    echo "Syntax Error: -u <user name>:<user dir>"
                    exit 1
                fi
                IFS=":" read -r  uuser udir <<< "$OPTARG"
                if [[ -z "$udir" || -z "$uuser" ]]; then
                    echo "Syntax Error: -u <user name>:<user dir>"
                    exit 1
                elif [[ ! $(getent passwd $uuser) ]]; then
                    echo "The user $uuser does not exist"
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

            c)
                cgi_file=$OPTARG
                if [[ -z $cgi_file ]]; then
                    echo "Syntax Error: -c <main cgi file>"
                    exit 1
                    fi
                 cgi_enabled=0
                 ;;

            h | *)
                echo "Usage: $0 -d <domain> [-s <certfile>:<keyfile>] [-f <main html file>] [-u <username>:<user dir>] [-a <url_path>:<username>:<password>]"
                echo "                      [-c <main cgi file>]"
                exit 1
                ;;
        esac
    done

    
    if [[ -z "$domain" ]]; then
        echo "Error: -d (domain) is required"
        exit 1
    fi

    if [[ -e "$config_file" ]]; then
        echo "Error: config file already exists in /etc/nginx/site-available"
        exit 1
    fi

if [[ $ssl_enabled -eq 1 ]]; then
    http_opts $domain $dfile $rootdir $config_file
else
    https_opts $domain $dfile $ssl_key $ssl_cert $rootdir $config_file
fi

if [[ $u_enabled -eq 0 ]]; then
    user_dir_opts $udir $uuser $config_file
fi

if [[ $htpasswd_enabled -eq 0 ]]; then

    auth_opts $htpasswd_file $htpasswd_url_path $htpasswd_user $htpasswd_password $config_file
fi

if [[ $cgi_enabled -eq 0 ]]; then
    cgi_opts $cgi_file $rootdir $config_file
fi

echo "}" >> $config_file

create_link $config_file
add_domain_to_hosts $domain
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
ouser_user=$2
oconfig_file=$3
opath=/home/$ouser_user/$ouser_dir

cat << EOF >> $oconfig_file

    location ~ ^/~(.+?)(/.*)?$ {
    alias /home/\$1/$ouser_dir\$2;
}
EOF

    if [[ ! -e $opath ]]; then
    echo "Seems like $opath does not exist, would you like to create this directory? [y/n]"
    
    read -r user_input  

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        mkdir -p $opath
        chmod 755 $opath
        echo "Directory $opath has been created."
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
oh_root_path=$6

if  ! htpasswd -b -c "$oh_file" "$oh_user" "$oh_password" ; then
    echo "An error happend during htpasswd creation, please check your syntax and run the script agian. -h for help menu"
fi
mkdir -p $oh_root_path/$oh_path

cat << EOF >> $oh_config_file
location $oh_path{
    auth_basic "Restricted Area";
    auth_basic_user_file "$oh_file";
    root $oh_root_path/$oh_path;
    index index.html;

}
EOF
}

function cgi_opts(){
    local cgi_file="$1"
    local rootdir="$2"
    local config_file="$3"

    local full_path="$rootdir/cgi-bin/"
    local full_fpath="$full_path$cgi_file"

    if [[ ! -e $full_path ]]; then
        echo "Creating cgi-bin folder under $full_path and also creating a test CGI file under: $full_fpath..."
        mkdir -p "$full_path"
        cat << 'EOF' >> "$full_fpath"
#!/usr/bin/env python3
import sys
print("Content-Type: text/html\n")
print("<html><body>")
print("<h1>FastCGI is working!</h1>")
print("<p>If you see this message, FastCGI is properly configured.</p>")
print("</body></html>")
EOF
        sudo chown www-data:www-data "$full_fpath" "$full_path"
        sudo chmod 755 "$full_fpath" "$full_path"
    fi

    echo "Checking and starting fcgiwrap process..."
    pgrep -x fcgiwrap > /dev/null || sudo spawn-fcgi -s /run/fcgiwrap.socket -M 777 -- /usr/sbin/fcgiwrap &

    cat << EOF >> "$config_file"
location /cgi-bin/ {
    fastcgi_pass unix:/run/fcgiwrap.socket;
    include fastcgi_params;
    
    fastcgi_param SCRIPT_FILENAME $full_fpath;
    fastcgi_param PATH_INFO \$fastcgi_script_name;
    fastcgi_param QUERY_STRING \$query_string;
    fastcgi_param REQUEST_METHOD \$request_method;
    fastcgi_param CONTENT_TYPE \$content_type;
    fastcgi_param CONTENT_LENGTH \$content_length;
    autoindex on;
    index $cgi_file;
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







function validate_ip (){
local ip=$1
local regex='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$'

if [[ $ip =~ $regex ]]; then
        oct1=${BASH_REMATCH[1]}
        oct2=${BASH_REMATCH[2]}
        oct3=${BASH_REMATCH[3]}
        oct4=${BASH_REMATCH[4]}
        if (( oct1 >= 0 && oct1 <= 255 )) && \
            (( oct2 >= 0 && oct2 <= 255 )) && \
             (( oct3 >= 0 && oct3 <= 255 )) && \
             (( oct4 >= 0 && oct4 <= 255 ))
                 then
                    return 0
                else
                    echo "Invalid IP Address"
                    return 1
        fi
    else
        echo "Invalid IP Address"
        return 1
fi

if grep -q "$ip" /etc/hosts; then
    echo "The IP address: $ip already exists in /etc/hosts"
    return 1
fi

}

function add_domain_to_hosts (){
local domain=$1
local ip=""

    read -p "Do you want to add a domain to /etc/hosts (loopback address)? [y/n]: " user_input
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
               if grep -q "$domain" /etc/hosts; then
                   echo "The domain is already present in /etc/hosts."
                    return 1
                else
                    read -p "Enter the loopback address (example 127.0.0.1): " loopback_address
                        if validate_ip $loopback_address; then
                            echo "$loopback_address $domain" | sudo tee -a /etc/hosts > /dev/null
                            echo "Domain '$domain' added to /etc/hosts with the address $loopback_address."
                        else 
                            echo "There was an error in adding the record $loopback_address $domain to /etc/hosts"
                            return 1
                        fi
               fi
        fi

}








main "$@"
