FROM vault

RUN apk add jq

COPY ./init_vault.sh /vault/init_vault.sh
COPY ./KOSMoS_GLOBAL_ROOT_CA.bundle /vault/KOSMoS_GLOBAL_ROOT_CA.bundle
COPY ./KOSMoS_GLOBAL_ROOT_CA.crt /vault/KOSMoS_GLOBAL_ROOT_CA.crt
COPY ./KOSMoS_GLOBAL_ROOT_CA.key /vault/KOSMoS_GLOBAL_ROOT_CA.key
COPY ./config /vault/config

ENTRYPOINT [ "/vault/init_vault.sh" ]