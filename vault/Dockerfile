FROM vault

RUN apk add jq

COPY ./init_vault.sh /vault/init_vault.sh
COPY ./KOSMoS_GLOBAL_ROOT_CA.bundle /vault/KOSMoS_GLOBAL_ROOT_CA.bundle
COPY ./KOSMoS_GLOBAL_ROOT_CA.crt /vault/KOSMoS_GLOBAL_ROOT_CA.crt
COPY ./KOSMoS_GLOBAL_ROOT_CA.key /vault/KOSMoS_GLOBAL_ROOT_CA.key
COPY ./config /vault/config

HEALTHCHECK CMD curl -f -s http://127.0.0.1:8200 || exit 1
ENTRYPOINT [ "/vault/init_vault.sh" ]