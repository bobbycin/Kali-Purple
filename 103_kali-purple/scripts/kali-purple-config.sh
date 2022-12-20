#*********************************************************************
#                                                                    *
# Configuration file to be sourced by kali-purple-setup scripts      *
#                                                                    *
#*********************************************************************
#
# Host:
HOSTNAME="kali-purple"
DOMAIN="kali.purple"
IP="192.168.252.3"
#
# Elastic search v.7.x:
ELK_VERSION="7.17.8"
ELK_REPO="https://artifacts.elastic.co/packages/7.x/apt stable main"
SOURCES_LIST="elastic-7.x.list"
WIN_AGENT="https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-${ELK_VERSION}-windows-x86_64.zip"
LNX_AGENT="https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-${ELK_VERSION}-linux-x86_64.tar.gz"
#
# Sysmon
SYSMON="https://download.sysinternals.com/files/Sysmon.zip"
SYSMON_CONFIG="https://github.com/SwiftOnSecurity/sysmon-config/raw/master/sysmonconfig-export.xml"
#
# Docker
DOCKER_REPO="deb https://download.docker.com/linux/debian bullseye stable"


