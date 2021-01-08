#!/bin/bash
# entrypoint.sh
#
# Benötigt Environment Variablen
# Für den Broker an sich:
# * USE_TLS             - Soll der Broker mit SSL/TLS Starten?
#
# Für die PKI (Bei TLS)
# * MY_PKI_URI          - Ist die vollständige URI der Vault PKI
# * VAULT_TOKEN         - Ist der Vault-Token um Zertifikate zu erhalten
#
if [ "$USE_TLS" = true ]; then
    # Der CN für das Zertifikat wird aus dem Domainname und dem Hostname erzeugt.
    export MY_FQDN=`hostname -f`
    . /app/common/request_cert.sh
fi

npm start -- --userDir /app