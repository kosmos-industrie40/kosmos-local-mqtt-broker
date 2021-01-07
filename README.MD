# Lokale KOSMoS MQTT Komponente

Die lokale KOSMoS Komponente verbindet alle Komponenten auf dem Hallenboden 
(der Edge) über das Protokoll MQTT miteinander.

## Kurzbeschreibung

Das verwendete Protokoll ist MQTT V3.1  
  
Jede Maschine oder Komponente die mit dem MQTT Broker sprechen will, muss sich wie folgt authentifizieren:  
* gar nicht (zum Test echt super, in Echt leider nicht verfügbar)
* mit Benutzername/Kennwort (besser als gar nichts, Datenaustausch jedoch nicht vertraulich)
* mit einem Zertifikat, welches von der KOSMoS Vault-PKI vergeben wurde (SSL/TLS) 

## Inhalt dieses Repos

Kern dieses Repos ist:  
* ein Docker Container mit dem MQTT Broker Mosquitto.

Zum Demonstation der Funktionsweise sind im Repo ebenfalls folgende Container:  
* mqtt-dashboard: Überblick über MQTT-Nachrichten-Aufkommen im Broker (per Web-Browser)  
* vault-placeholder: Simuliert die KOSMoS-Vault und erzeugt Zertifikate für Tests  
  
> Die Vault Komponente dient nur zur demonstration der Funktionsweise und ist so keinesfalls für den Produktiveinsatz geeignet!

## Voraussetzungen zur Installation/Nutzung

* Linux (getestet unter Ubuntu 18.04.4 LTS, vielleicht gehten auch andere OS's)
* Docker (`apt install docker-ce`)
* TCP Ports 10002 (mqtt-dashboard), 10003 (vault-placeholder HTTP), 10004 (vault-placeholder HTTPS) dürfen nicht belegt sein

## TODO

* Node-RED Editor Passwort schützen
* Reverse Proxy (Candy: Einheitlicher Passwortschutz für alles / OIDC)
* Bereitstellung einer produktionstauglichen Vault

## Installation und Start aller Services

Der Start der Komponenten erfolgt über ein Start-Script,
welches als Referenz für die Komponenten verwendet werden kann.

```bash
git clone https://github.com/kosmos-industrie40/kosmos-local-startup.git
cd kosmos-local-startup
./start_all.sh
```
  
## Das Netzwerk in der EDGE

Der MQTT-Broker ist ein zentrales Element in der EDGE.
Um das Netzwerk der EDGE zu simulieren initialisiert das `start_all.sh` Script einen virtuellen Docker Switch (`docker network create kosmos-local`).

Hier die Eckdaten des aufgespannten virtuellen Netzwerks:    
* Der MQTT-Broker ist erreichbar unter `mqtt.brokers.mqtt.local.kosmos`  
* Alle MQTT-Subscriber und -Publisher müssen als DNS-Namen bekommen: `*.clients.mqtt.local.kosmos`  
  * Dies wurde in der Vault als Rollenname für MQTT-Clients festgelegt  
* Die Vault ist unter `ca.mqtt.local.kosmos`, `ca.local.kosmos` und `ca.global.kosmos` erreichbar  
  * Die DNS bezeichnungen `local` und `global` sollen dazu dienen, die Rollen der Vault als CA im jeweiligen KOSMoS Umfeld zu Simulieren

Alle Komponenten, welche mit dem MQTT-Broker komunizieren sollen, müssen sich in diesen virtuellen Switch "einstecken".
```bash
docker run
[...]
    --net kosmos-local \
[...]
```

Alle Komponenten, welche für andere Komponenten per SSL/TLS erreichbar sein müssen, brauchen (mindestens) einen DNS Namen.  
```
# Der Vault Placeholder ist zu anschaungszecken unter 3 DNS-Namen erreichbar:
docker run 
[...]
    --net-alias ca.mqtt.local.kosmos \
    --net-alias ca.local.kosmos \
    --net-alias ca.global.kosmos \
[...]
```

Dem `start_all.sh` Script können Beispiel-Services entnommen werden.

## Sichtbar machen was läuft

Versendete Topics in Kommandozeile anzeigen: 

```bash
docker log -f machine-simulator
```

Visualisierung im Browser (MQTT Message aufkommen und Topics):

* http://localhost:10002

Zugang zur Vault im Browser:

* http://localhost:10003 / https://localhost:10004

## Implementierungsdetails

* Als MQTT-Broker wird Mosquitto eingesetzt

* Subscriber und Publisher können sich verbinden

     * ohne Credentials (zu Testzwecken, ist abschaltbar)
     * mit Benutzername/Passwort (zu testzwecken, ist abschaltbar)
     * mit SSL-Zertifikat (das ist der richtige KOSMoS-Weg)

### Wie kommen Broker und Clients an die Zertifikate?

* Das `KOSMoS_GLOBAL_ROOT_CA.pem` im Ordner `common/ca` ist in jedem relevanten Container unter `/app/common/ca` verfügbar.

     > Die Vault verwendet auf Host-Port 10004 (docker intern Port 8201) dieses Zertifikat (respektive Key).
     > Dadurch wird eine sichere Verbindung zwischen Containern und Vault gewährleistet (HTTPS).

* Ein Shell-Script `request_cert.sh` ist in jedem relevanten Container unter `/app/common/` verfügbar.

     > Das Script verwedent einen Token um sich gegen die Vault zu Authentifizieren und beantragt damit sein Zertifikat.
     > Die folgenden docker-compose.yml environment variablen werden verarbeitet:

     * MY_CA_FQDN wird benötigt um ein Login-Token von der Vault zu bekommen
     * MY_PKI_URI ist die Vollständige URI der Vault-PKI (z.B.: https://ca.mqtt.local.kosmos:8201/v1/pki_mqtt/issue/mqtt-client)
     * MY_FQDN ist der Vollständige DNS-Name des Services


     > !!! Dieses Script nutzt in der Testumgebung den Admin-Account der Vault um einen Token zu beziehen.
     > In der Produktivumgebung könnte der Container bereits mit einem Token ausgeliefert werden !!!

### Wie Authentifizieren sich die Clients beim Broker?

Der MQTT-Broker erfordert, dass alle Clients sich mit Zertifikaten der selben CA anmelden.

> Hat ein Client also ein Zertifikat von der Vault bekommen, ist dieser auch automatisch berechtigt den Brocker zu nutzen.
> Eine ACL überprüfung kann mit dem CN (falls notwendig auch mit weiteren Feldern des Zertifikates) erfolgen.

### Die Vault in dieser Testumgebung

Die Vault hat im Dev-Mode kein Backend für persisitente Daten, dafür ein ***Web-UI*** (siehe oben).

Nach jedem neustart wird die mit dem Script `vault/init_vault.sh` Vault neu Initialisiert.

Dieses Script erstellt die Public Key Infrastructure (PKI) und einen userpass Admin-Account (Username: admin - Passwort: admin).

Diese Vault repräsentiert KOSMoS global und KOSMoS local.

Zertifikat und Private Key von KOSMoS global sind in `vault/KOSMoS_GLOBAL_ROOT_CA.[crt,key,bundle]` und werden bei Initialisieren importiert.
Sinn und Zweck ist, dass eine HTTPS Verbindung immer gegen das selbe `KOSMoS_GLOBAL_ROOT_CA.crt` geprüft werden kann.

> In der Produktivumgebung darf ein Private Key natürlich niemals nie so zugänglich sein.

## Credits

Dieses Repo wurde erstellt im Rahmen des BMBF Forschungsprojektes KOSMoS. Danke, BMBF!

Verwendete Software und Technologien:

* Eclipse Foundation: mosquitto
* mosquitto-go-auth Plugin: https://github.com/iegomez/mosquitto-go-auth
* HashiCorp: Vault
* OpenJS Foundation: Node-RED
* alpine Linux: https://alpinelinux.org/
* Docker & Compose: https://www.docker.com

## Author

(C) 2020, Ondics GmbH
