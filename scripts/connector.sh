#!/usr/bin/env bash

#title           :logstash.sh
#description     :Vagrant shell script to setup ArcSight Smart Connector Host
#author		     :Justin Jessup
#date            :11/22/2016
#version         :0.1
#usage		     :bash logstash.sh
#notes           :Executed via Vagrant => vagrant-kafka
#bash_version    :GNU bash, version 4.1.2(1)-release (x86_64-redhat-linux-gnu)
#License         :MIT
#==============================================================================


echo "Setting up nameservers..."
cat /dev/null > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf


###########################
# ORACLE JAVA JDK 8 INSTALL
###########################

echo "Installing Oracle Java Development Kit"
JDK_VERSION="jdk-8u112-linux-x64"
JDK_RPM="$JDK_VERSION.rpm"

if [ ! -f /tmp/$JDK_RPM ]; then
    echo Downloading $JDK_RPM
    wget –quiet -O /tmp/$JDK_RPM --no-check-certificate --no-cookies --header \
    "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u112-b15/$JDK_RPM"
fi

echo "Installing JDK Version: $JDK_VERSION"
rpm -ivh /tmp/$JDK_RPM
echo "Completed installation JDK Version: $JDK_VERSION"


########################
# IINSTALL EPEL
########################

rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

echo "Disabling firewalld & selinux..."
/usr/bin/systemctl stop firewalld.service
/usr/bin/systemctl disable firewalld.service
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g ' /etc/sysconfig/selinux
setenforce permissive
sed -i '$ d' /etc/hosts

########################################################
# Get ArcSight Linux Smart Connector Installation Binary
########################################################

echo "Getting software..."
wget -O "/opt/ArcSight-7.3.0.7886.0-Connector-Linux64.bin" https://www.dropbox.com/s/zzrumm0q08x20aj/ArcSight-7.3.0.7886.0-Connector-Linux64%20%281%29.bin?dl=0
yum -y install wget tcpdump lsof bindutils vim-enhanced iftop
