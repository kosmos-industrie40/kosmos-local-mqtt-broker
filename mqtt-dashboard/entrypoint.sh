#!/bin/bash
# entrypoint.sh
#
# Benötigt Environment Variablen
# Für den Broker an sich:
# * USE_TLS             - Soll der Broker mit SSL/TLS Starten?
# * USE_PLAIN_AUTH      - Soll der Broker verbindungen ohne SSL/TLS erlauben? (Nicht implemtiert)
#   * AUTH_USERNAME         - Benutzername (Nicht implemtiert)
#   * AUTH_PASSWORD         - Passwort (Nicht implemtiert)
#
# Für die PKI
# * MY_PKI_URI          - Ist die vollständige URI der Vault PKI
# * VAULT_TOKEN         - Ist der Vault-Token um Zertifikate zu erhalten
# * MQTT_BROKER_FQDN    - Ist der vollständige MQTT-Broker-Domainname
#
if [ "$USE_TLS" = true ]; then
    # Der CN für das Zertifikat wird aus dem Domainname und dem Hostname erzeugt.
    export MY_FQDN=`hostname -f`
    . /app/common/request_cert.sh
else
    if [ "$USE_PLAIN_AUTH" = true ] && [ ! -z $AUTH_USERNAME ] && [ ! -z $AUTH_PASSWORD ]; then
        #TODO?
        echo -
    else
        #TODO?
        echo -
    fi
fi

npm start -- --userDir /app --settings /app/settings.js