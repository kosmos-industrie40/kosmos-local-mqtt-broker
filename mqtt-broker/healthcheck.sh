#!/bin/sh

if [ "$ALLOW_TLS" = true ] && [ "$ALLOW_PLAIN" = true ]; then

    SSL_HEALTH=`nc -z 127.0.0.1 8883 && echo true || echo false`
    PLAIN_HEALTH=`nc -z 127.0.0.1 1883 && echo true || echo false`
    ([ "$SSL_HEALTH" = true ] && [ "$PLAIN_HEALTH" = true ]) && exit 0 || exit 1

elif [ "$ALLOW_TLS" = true ]; then

    SSL_HEALTH=`nc -z 127.0.0.1 8883 && echo true || echo false`
    [ "$SSL_HEALTH" = true ] && exit 0 || exit 1

elif [ "$ALLOW_PLAIN" = true ]; then

    PLAIN_HEALTH=`nc -z 127.0.0.1 1883 && echo true || echo false`
    [ "$PLAIN_HEALTH" = true ] && exit 0 || exit 1

fi