#!/usr/bin/env bash

#title           :logstash.sh
#description     :Vagrant shell script to install logstash 5.0
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

JDK_VERSION="jdk-8u112-linux-x64"
JDK_RPM="$JDK_VERSION.rpm"

if [ ! -f /tmp/$JDK_RPM ]; then
    echo Downloading $JDK_RPM
    wget –quiet -O /tmp/$JDK_RPM --no-check-certificate --no-cookies --header \
    "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u112-b15/$JDK_RPM"
fi

echo "Disabling firewalld & selinux..."
/usr/bin/systemctl stop firewalld.service
/usr/bin/systemctl disable firewalld.service
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g ' /etc/sysconfig/selinux
setenforce permissive

echo "installing jdk ..."

rpm -ivh /tmp/$JDK_RPM

########################
# IINSTALL EPEL
########################

rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

#######################
# INSTALL LOGSTASH 2.4
#######################

echo "Installing logstash"
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
rpm -ivh https://artifacts.elastic.co/downloads/logstash/logstash-5.0.2.rpm
mkdir -p /opt/logstash
cp /vagrant/config/logstash.conf /etc/logstash/conf.d
yum -y install wget tcpdump bind-utils lsof git vim-enhanced iftop
echo "Installation logstash completed"
echo "Installing logstash plugins - logstash-input-kafka, logstash-output-syslog, logstash-codec-cef, and logstash-codec-avro"
#/opt/logstash/bin/./logstash-plugin install logstash-codec-avro
#/opt/logstash/bin/./logstash-plugin install logstash-codec-cef
#/opt/logstash/bin/./logstash-plugin install logstash-output-webhdfs
#/opt/logstash/bin/./logstash-plugin install logstash-output-syslog
#/opt/logstash/bin/./logstash-plugin uninstall logstash-input-kafka
#/opt/logstash/bin/./logstash-plugin uninstall logstash-output-kafka
#/opt/logstash/bin/./logstash-plugin install logstash-input-kafka
#/opt/logstash/bin/./logstash-plugin install logstash-output-kafka
#/opt/logstash/bin/./logstash-plugin update logstash-input-kafka
#/opt/logstash/bin/./logstash-plugin update logstash-output-kafka
echo "Logstash plugins installation completed"
sed -i '$ d' /etc/hosts
chown -R logstash:logstash /opt/logstash
/usr/bin/systemctl enable logstash
/usr/bin/systemctl start logstash
