#!/bin/sh
# entrypoint.sh

# conf.d leeren
rm /app/conf.d/* > /dev/null 2>&1

if [ "$ALLOW_TLS" = true ]; then
    # Kopieren der conf
    echo "entrypoint::copy mqtt_ssl.conf to conf.d"
    cp /app/conf.available/mqtt_ssl.conf /app/conf.d
    export MY_FQDN=`hostname -f`
    . common/request_cert.sh
fi

if [ "$ALLOW_PLAIN" = true ]; then
    if [ "$PLAIN_REQUIRE_AUTH" = true ] && [ ! -z $AUTH_USERNAME ] && [ ! -z $AUTH_PASSWORD ]; then
        echo "entrypoint::copy mqtt_userpass.conf to conf.d"
        cp /app/conf.available/mqtt_userpass.conf /app/conf.d
        touch /app/password_file
        mosquitto_passwd -b /app/password_file $AUTH_USERNAME $AUTH_PASSWORD  
    else
        echo "entrypoint::copy mqtt.conf to conf.d"
        cp /app/conf.available/mqtt.conf /app/conf.d
    fi
fi

# Ignoriere verbindungen vom Healthcheck
mosquitto -c /app/mosquitto.conf 2>&1 | awk '/New connection from 127.0.0.1 on port/{getline;next} 1'