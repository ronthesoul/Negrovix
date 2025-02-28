#!/usr/bin/env bash
###########################
#Written by: Ron Negron
#Date: 28.02
#Purpose: A tool that is made to create nginx config file
#Version:0.0.1
##########################


function main(){

domain=" "
dfile="index.html"


    for index in nginx apache2-utils nginx-extras;  do
    check_and_install "$index"
done

while getopts "d:s:f:u:c:a:" opt; do
    case $opt in
        d) domain="OPTARG" ;;
        s)


    esac

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




