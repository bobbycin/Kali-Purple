#!/bin/bash
if [ "$EUID" -ne 0 ]
  then printf "\nPlease run as root\n"
  exit
fi
#
#*********************************************************************
#* Get configuration                                                 *
#*********************************************************************
BASEDIR="$(dirname $0)"
source ${BASEDIR}/kali-purple-config.sh
#
echo "********************************************"
echo "*  Stage 2                                 *"
echo "********************************************"
echo "********************************************"
echo "* Reconfigure ELK for Security(1)          *"
echo "********************************************"
systemctl stop kibana
systemctl stop elasticsearch
echo "xpack.security.enabled: true" >> /etc/elasticsearch/elasticsearch.yml 
echo "xpack.security.audit.enabled: true" >> /etc/elasticsearch/elasticsearch.yml 
echo "discovery.type: single-node" >>  /etc/elasticsearch/elasticsearch.yml 
echo "network.host: ${HOSTNAME}.${DOMAIN}" >> /etc/elasticsearch/elasticsearch.yml
systemctl start elasticsearch
echo "y" | /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto > elkpass.txt
kk="$(grep 'kibana_system = ' elkpass.txt | awk '{print $4}')"
echo 'server.publicBaseUrl: "http://${HOSTNAME}.${DOMAIN}:5601"' >> /etc/kibana/kibana.yml
echo 'elasticsearch.username: "kibana_system"' >> /etc/kibana/kibana.yml 
echo "elasticsearch.password: $kk" >> /etc/kibana/kibana.yml 
echo "xpack.encryptedSavedObjects.encryptionKey: 'fhjskloppd678ehkdfdlliverpoolfcr'" >> /etc/kibana/kibana.yml
echo 'xpack.fleet.registryUrl: "http://127.0.0.1:8080"' >> /etc/kibana/kibana.yml
systemctl start kibana 
#
echo "********************************************************"
echo "* Stage 2 complete                                     *"
echo "* Check Elasticsearch and Kibana are running           *"
echo "* Then manually run the following commands:            *"
echo "*  nb: change the --dns argument to your own siem name *"
echo "  "
echo "sudo /usr/share/elasticsearch/bin/elasticsearch-certutil ca"
echo "sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12 --dns ${HOSTNAME}.${DOMAIN} --out http.p12"
echo "sudo openssl pkcs12 -in /usr/share/elasticsearch/elastic-stack-ca.p12 -out /usr/share/elasticsearch/ca.crt -clcerts -nokeys "
echo "sudo openssl pkcs12 -in /usr/share/elasticsearch/http.p12 -out /usr/share/elasticsearch/fleet.crt -clcerts -nokeys "
echo " "
