#!/bin/sh
# request_cert.sh
#
# Benötigt Environment Variablen:
# * MY_FQDN     - Ist der CN dieser Komponente
# * MY_PKI_URI  - Ist die vollständige URI der Vault PKI
# * VAULT_TOKEN - Ist der Vault-Token um Zertifikate zu erhalten
#
echo request_cert::Using Vault-Token: $VAULT_TOKEN

# Cert bei der Vault beantragen.
#
# Die Vault muss an dieser Stelle überprüfen, ob der TOKEN dazu berechtigt ist ein 
# Zertifikat von diesem Pfad zu beziehen!
#
echo -n "request_cert::Requesting Cert for $MY_FQDN..."
CERT_DATA=$(curl -s --cacert /app/common/ca/KOSMoS_GLOBAL_ROOT_CA.crt --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data "{ \"common_name\": \"$MY_FQDN\" }" $MY_PKI_URI)

echo $CERT_DATA | jq -r .data.ca_chain[] > ca.pem && \
(
    echo " [OK]"
    cat /app/common/ca/KOSMoS_GLOBAL_ROOT_CA.crt >> ca.pem && 
    echo $CERT_DATA | jq -r .data.certificate > cert.pem &&
    echo $CERT_DATA | jq -r .data.private_key > key.pem
) || (echo "FAILED:" && echo $CERT_DATA | jq) 