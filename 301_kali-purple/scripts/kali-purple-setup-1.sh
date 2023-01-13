#!/bin/bash
#********************************************
#* Kali Purple ELK Setup Script             *
#********************************************
# Run as root
#*********************************************************************
# Kibana  port 5601                                                  *
# Elastic port 9200                                                  *
# Fleet   port 8220                                                  *
#*********************************************************************
#
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
echo "*************************************************************"
echo "Setting up SIEM name for agents certificates                *"
echo "*************************************************************"
cat << EOF > /etc/hosts
127.0.0.1           localhost ${HOSTNAME}
${IP}       ${HOSTNAME}.${DOMAIN}

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
#
echo "*************************************************************"
echo " Installing dependencies"
echo "*************************************************************"
apt update
apt install -y curl
#
echo "*************************************************************"
echo " Setting up ELK stack"
echo "*************************************************************"
if [ ! -f /etc/apt/trusted.gpg.d/elastic-archive-keyring.gpg ]; then
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /etc/apt/trusted.gpg.d/elastic-archive-keyring.gpg
else
    echo "elastic-archive-keyring.gpg already installed; skipping."
fi
if [[ $(grep "deb ${ELK_REPO}" /etc/apt/sources.list.d/${SOURCES_LIST}) ]]; then
    echo "${SOURCES_LIST} already installed; skipping."
else
    echo "deb ${ELK_REPO}" | tee -a /etc/apt/sources.list.d/${SOURCES_LIST} 
fi
apt update 
#
apt install -y elasticsearch kibana 
if [[ $(grep "^server.port: 5601" /etc/kibana/kibana.yml) ]]; then
    echo "kibana server port already configured; skipping."
else
    echo "server.port: 5601" >>    /etc/kibana/kibana.yml
fi
if [[ $(grep "^server.host: 0.0.0.0" /etc/kibana/kibana.yml) ]]; then
    echo "kibana server host already configured; skipping."
else
    echo "server.host: 0.0.0.0" >> /etc/kibana/kibana.yml
fi
sed -i "s/75/300/" /usr/lib/systemd/system/elasticsearch.service
#
echo "******************************************"
echo "* Download Elastic Agents                *"
echo "******************************************"
wget ${WIN_AGENT} -O /usr/share/elasticsearch/wagent.zip
chown elasticsearch:elasticsearch /usr/share/elasticsearch/wagent.zip
chmod +r /usr/share/elasticsearch/wagent.zip
wget ${LNX_AGENT} -O /usr/share/elasticsearch/elagent.tar.gz 
chown elasticsearch:elasticsearch /usr/share/elasticsearch/elagent.tar.gz
chmod +r /usr/share/elasticsearch/elagent.tar.gz
cp /usr/share/elasticsearch/elagent.tar.gz ./
tar -xvzf elagent.tar.gz 
mv elastic-agent-${ELK_VERSION}-linux-x86_64 elagent
#
echo "**************************************"
echo " Prepare files for sysmon            *"
echo "**************************************"
wget ${SYSMON} -O /usr/share/elasticsearch/sysmon.zip
chown elasticsearch:elasticsearch /usr/share/elasticsearch/sysmon.zip
chmod +r /usr/share/elasticsearch/sysmon.zip
wget ${SYSMON_CONFIG} -O /usr/share/elasticsearch/sysmon.xml
e10='<TargetImage condition="is">C:\\Windows\\system32\\lsass.exe</TargetImage></ProcessAccess><ProcessAccess ommatch="exclude"><SourceImage condition="is">C:\\Program Files (x86)\\VMWare\\VMware Workstation\\vmware-authd.exe</SourceImage>'
sed -i "473s|^.*$|$e10|" /usr/share/elasticsearch/sysmon.xml
chown elasticsearch:elasticsearch /usr/share/elasticsearch/sysmon.xml
chmod +r /usr/share/elasticsearch/sysmon.xml
#
echo "**********************************************************************"
echo " Setup docker"
echo "**********************************************************************"
if [ ! -f /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
else
    echo "docker-archive-keyring.gpg already installed; skipping."
fi
if [[ $(grep "${DOCKER_REPO}" /etc/apt/sources.list.d/docker-ce.list) ]]; then
    echo "${DOCKER_REPO} already setup; skipping."
else
    echo "${DOCKER_REPO}" | tee /etc/apt/sources.list.d/docker-ce.list > /dev/null
fi
apt update
apt install -y docker-ce docker-ce-cli containerd.io
docker pull docker.elastic.co/package-registry/distribution:${ELK_VERSION}
docker save -o package-registry-${ELK_VERSION}.tar docker.elastic.co/package-registry/distribution:${ELK_VERSION}
docker load -i package-registry-${ELK_VERSION}.tar
#
echo "**********************************************************************"
echo " Enable services"
echo "**********************************************************************"
systemctl enable elasticsearch.service --now
systemctl enable kibana.service --now
#
echo "**************************************************"
echo "* Stage 1 complete with manual docker start      *"
echo "* Start docker then Ctrl/C once stable           *"
echo "* Then reboot                                    *"
echo "**************************************************"
echo " "
echo "sudo docker run -it --restart unless-stopped -p 8080:8080 docker.elastic.co/package-registry/distribution:${ELK_VERSION}"
