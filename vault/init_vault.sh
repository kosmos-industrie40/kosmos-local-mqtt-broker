#!/bin/ash

init_vault(){
  # wait until vault is up
  sleep 5

  TOKEN=$(cat /vault/logs/vault.log | awk '/Root Token:/ {print $NF;}' | tail -n 1 | sed 's/\x1b\[[0-9;]*m//g')

  echo TOKEN: $TOKEN

  # Login
  
  vault login $TOKEN

  # PKI related
  # Root-CA, simulates KoSMoS Global Vault
  vault secrets enable -path=$KOSMOS_GLOBAL_PKI_PATH pki
  vault secrets tune -max-lease-ttl=87600h $KOSMOS_GLOBAL_PKI_PATH
  #vault write -field=certificate $KOSMOS_GLOBAL_PKI_PATH/root/generate/internal common_name="$KOSMOS_GLOBAL_CA_FQDN" ttl=87600h > GLOBAL_CA_cert.crt
  vault write $KOSMOS_GLOBAL_PKI_PATH/config/ca pem_bundle=@/vault/KOSMoS_GLOBAL_ROOT_CA.bundle
  vault write $KOSMOS_GLOBAL_PKI_PATH/config/urls issuing_certificates="http://$KOSMOS_GLOBAL_CA_FQDN:8200/v1/$KOSMOS_GLOBAL_PKI_PATH/ca" crl_distribution_points="http://$KOSMOS_GLOBAL_CA_FQDN:8200/v1/$KOSMOS_GLOBAL_PKI_PATH/crl"
  

  # KoSMoS Local Intermediate CA - signed by KoSMoS Global CA
  vault secrets enable $KOSMOS_LOCAL_PKI_PATH
  vault secrets tune -max-lease-ttl=87600h $KOSMOS_LOCAL_PKI_PATH
  vault write -format=json $KOSMOS_LOCAL_PKI_PATH/intermediate/generate/internal common_name="$KOSMOS_LOCAL_CA_FQDN Intermediate Authority" ttl=87600h | jq -r '.data.csr' > LOCAL_CA_pki_intermediate.csr
  vault write -format=json $KOSMOS_GLOBAL_PKI_PATH/root/sign-intermediate csr=@LOCAL_CA_pki_intermediate.csr format=pem_bundle ttl=43800h | jq -r '.data.certificate' > LOCAL_CA_intermediate.cert.pem
  vault write $KOSMOS_LOCAL_PKI_PATH/intermediate/set-signed certificate=@LOCAL_CA_intermediate.cert.pem
  vault write $KOSMOS_LOCAL_PKI_PATH/config/urls issuing_certificates="http://$KOSMOS_LOCAL_CA_FQDN:8200/v1/$KOSMOS_LOCAL_PKI_PATH/ca" crl_distribution_points="http://$KOSMOS_LOCAL_CA_FQDN:8200/v1/pki/crl"

  # KoSMoS Local MQTT Intermediate CA for - signed by Local-CA
  vault secrets enable -path=$KOSMOS_LOCAL_MQTT_PKI_PATH pki
  vault secrets tune -max-lease-ttl=43800h $KOSMOS_LOCAL_MQTT_PKI_PATH
  vault write -format=json $KOSMOS_LOCAL_MQTT_PKI_PATH/intermediate/generate/internal common_name="$MQTT_CA_FQDN Intermediate Authority" | jq -r '.data.csr' > MQTT_CA_pki_intermediate.csr
  vault write -format=json $KOSMOS_LOCAL_PKI_PATH/root/sign-intermediate csr=@MQTT_CA_pki_intermediate.csr format=pem_bundle ttl=43800h | jq -r '.data.certificate' > MQTT_CA_intermediate.cert.pem
  vault write $KOSMOS_LOCAL_MQTT_PKI_PATH/intermediate/set-signed certificate=@MQTT_CA_intermediate.cert.pem
  vault write $KOSMOS_LOCAL_MQTT_PKI_PATH/config/urls issuing_certificates="http://$KOSMOS_LOCAL_MQTT_CA_FQDN:8200/v1/$KOSMOS_LOCAL_MQTT_PKI_PATH/ca" crl_distribution_points="http://$KOSMOS_LOCAL_MQTT_CA_FQDN:8200/v1/$KOSMOS_LOCAL_MQTT_PKI_PATH/crl"

  vault write $KOSMOS_LOCAL_MQTT_PKI_PATH/roles/$KOSMOS_LOCAL_MQTT_CLIENT_ROLE_PATH allowed_domains="$KOSMOS_LOCAL_MQTT_CLIENT_ROLE_FQDN" allow_bare_domains=true allow_subdomains=true max_ttl=720h
  vault write $KOSMOS_LOCAL_MQTT_PKI_PATH/roles/$KOSMOS_LOCAL_MQTT_BROKER_ROLE_PATH allowed_domains="$KOSMOS_LOCAL_MQTT_BROKER_ROLE_FQDN" allow_bare_domains=true allow_subdomains=true max_ttl=720h

  # User/Pass related
  vault auth enable userpass
  vault policy write admin /vault/config/admin.hcl
  vault write auth/userpass/users/admin password=admin policies=admin
}

init_vault&

# Start Vault
/usr/local/bin/docker-entrypoint.sh server -dev | tee /vault/logs/vault.log