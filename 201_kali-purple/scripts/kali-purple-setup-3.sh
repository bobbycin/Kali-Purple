#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
#
#*********************************************************************
#* Get configuration                                                 *
#*********************************************************************
BASEDIR="$(dirname $0)"
source ${BASEDIR}/kali-purple-config.sh
#
echo "*************************************"
echo "* STAGE 3                            *"
echo "*************************************"
echo "*************************************"
echo "* Reconfigure ELK for Security(2)   *" 
echo "*************************************"
systemctl stop kibana
systemctl stop elasticsearch
chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/
chmod -R +r /usr/share/elasticsearch/
mkdir /etc/elasticsearch/certs 
cp /usr/share/elasticsearch/elastic-stack-ca.p12 /etc/elasticsearch/certs/
cp /usr/share/elasticsearch/http.p12 /etc/elasticsearch/certs/
cp /usr/share/elasticsearch/ca.crt /etc/elasticsearch/certs/
cp /usr/share/elasticsearch/fleet.crt /etc/elasticsearch/certs/
chown -R elasticsearch:elasticsearch /etc/elasticsearch/
chmod -R +r /etc/elasticsearch/
echo 'xpack.security.http.ssl.enabled: true' >> /etc/elasticsearch/elasticsearch.yml 
echo 'xpack.security.http.ssl.keystore.path: "/etc/elasticsearch/certs/http.p12"' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.http.ssl.keystore.password: ""' >> /etc/elasticsearch/elasticsearch.yml 
echo "xpack.security.http.ssl.certificate: /etc/elasticsearch/certs/fleet.crt" >> /etc/elasticsearch/elasticsearch.yml
cp /usr/share/elasticsearch/ca.crt /etc/kibana/
chown kibana:kibana /etc/kibana/ca.crt
chmod +r /etc/kibana/ca.crt
echo 'elasticsearch.ssl.certificateAuthorities: ["/etc/kibana/ca.crt"]' >> /etc/kibana/kibana.yml
echo 'elasticsearch.hosts: ["https://${HOSTNAME}.${DOMAIN}:9200"]' >> /etc/kibana/kibana.yml
systemctl start elasticsearch
#
echo "*******************************************"
echo " Startup script                            "
echo "*******************************************"
cat << EOF >> /etc/systemd/system/check.service
[Unit]
Description=SIEM IP Check
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /root/check.py
[Install]
WantedBy=multi-user.target
EOF
cat << EOF >> /root/check.py
import netifaces as ni
import os
import time
if __name__ == '__main__':
  os.system("systemctl stop kibana")
  os.system("systemctl stop elasticsearch")
  os.system("systemctl start elasticsearch")
  os.system("systemctl start kibana")
EOF
systemctl enable check.service
#
echo "********************************************************"
echo "* Stage 3 complete..                                   *"
echo "********************************************************"
