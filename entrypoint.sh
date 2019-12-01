#!/bin/bash

i="1"

while : ; do
    host="SERVICE_HOST_$i"
    address="SERVICE_ADDRESS_$i"
    port="SERVICE_PORT_$i"
    if [[ -z "${!host}" || -z "${!address}" || -z "${!port}" ]]; then
        i=$[$i-1]
        break
    fi
    if [ -e /etc/letsencrypt/live/"${!host}"/fullchain.pem ] 
    then
        echo "Certificaate is already created for host ${!host}" 
    else
        cp example.com.conf /etc/nginx/conf.d/${!host}.conf
        sed -i "s|example.com|${!host}|g" /etc/nginx/conf.d/${!host}.conf
        sed -i "s|0.0.0.0|${!address}|g" /etc/nginx/conf.d/${!host}.conf
        sed -i "s|0000|${!port}|g" /etc/nginx/conf.d/${!host}.conf
        certbot -n --nginx -d ${!host} --agree-tos --email $EMAIL
    fi
    i=$[$i+1]
done

service cron start
crontab /crontab
nginx -s stop
exec nginx -g 'daemon off;'