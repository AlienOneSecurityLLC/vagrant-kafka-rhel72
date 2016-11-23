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

#######################
# INSTALL LOGSTASH 2.4
#######################

echo "Installing logstash"
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
cp /vagrant/config/logstash.repo /etc/yum.repos.d
mkdir -p /opt/logstash
cp /vagrant/config/logstash.conf /etc/logstash/conf.d
echo "Installation logstash completed"
echo "Installing logstash plugins - logstash-input-kafka, logstash-output-syslog, logstash-codec-cef, and logstash-codec-avro"
/opt/logstash/bin/./logstash-plugin install logstash-codec-avro
/opt/logstash/bin/./logstash-plugin install logstash-codec-cef
/opt/logstash/bin/./logstash-plugin install logstash-output-webhdfs
/opt/logstash/bin/./logstash-plugin install logstash-output-syslog
/opt/logstash/bin/./logstash-plugin uninstall logstash-input-kafka
/opt/logstash/bin/./logstash-plugin uninstall logstash-output-kafka
/opt/logstash/bin/./logstash-plugin install logstash-input-kafka
/opt/logstash/bin/./logstash-plugin install logstash-output-kafka
/opt/logstash/bin/./logstash-plugin update logstash-input-kafka
/opt/logstash/bin/./logstash-plugin update logstash-output-kafka
echo "Logstash plugins installation completed"
chown -R logstash:logstash /opt/logstash
/sbin/chkconfig logstash on
/sbin/service logstash start

#######################
# CENTOS 6.8 UPDATE
#######################
echo "Updating CentOS 7.2..."
rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
yum clean all
yum -y update
echo "Completed updating CentOS 7.2..."
