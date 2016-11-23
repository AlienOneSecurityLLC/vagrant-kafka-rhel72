#!/usr/bin/env bash


#title           :logstash.sh
#description     :Vagrant shell script install Zookeeper & Kafka
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

echo "Installing Oracle Java Development Kit"
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


echo "Installing JDK Version: $JDK_VERSION"
rpm -ivh /tmp/$JDK_RPM
echo "Completed installation JDK Version: $JDK_VERSION"

########################
# ZOOKEEPER INSTALL
########################

echo "Installing Zookeeper"
yum -y install git lsof
cd /opt
git clone git@github.com:AlienOneSecurityLLC/zookeeper-el7-rpm.git
cd zookeeper-el7-rpm
sudo yum install make rpmdevtools
make rpm
cd x86_64
rpm -ivh zookeeper-*.rpm
echo "Setting unique zookeeper id..."
touch myid
str=$(hostname)
last_char="${str: -1}"
cd /opt/zookeeper/data
echo $last_char > myid
echo 'JVMFLAGS="-Xmx2048m -Djute.maxbuffer=1000000000"' >> /etc/sysconfig/zookeeper
echo "server.1=10.30.3.2:2888:3888" >> /etc/zookeeper/zoo.cfg
echo "server.2=10.30.3.3:2888:3888" >> /etc/zookeeper/zoo.cfg
echo "server.3=10.30.3.4:2888:3888" >> /etc/zookeeper/zoo.cfg
chown -R zookeeper:zookeeper /opt/zookeeper
service zookeeper start
sed -i 's/eforward        2181\/tcp                \# eforward/zookeeper        2181\/tcp                \# zookeeper/g' /etc/services
lsof -i TCP:2181 | grep LISTEN
echo "Completed installation of Zookeeper"

#######################
# INSTALL KAFKA
#######################

cd /opt
git clone https://github.com/id/kafka-el7-rpm.git
cd kafka-el7-rpm
sudo yum install make rpmdevtools
make rpm
cd RPMS/x86_64
rpm -ivh kafka-*.rpm
echo "Setting unique kafka broker id..."
str=$(hostname)
last_char="${str: -1}"
sed -i "s/broker.id\=0/broker.id\=$last_char/g" /etc/kafka/server.properties
ip_address=$(ifconfig -a eth1 | grep 'inet addr\:' | cut -d':' -f2 | awk '{print $1}')
sed -i "s/\#advertised.listeners\=PLAINTEXT\:\/\/your.host.name:9092/advertised.listeners\=PLAINTEXT\:\/\/$ip_address:9092/g" /etc/kafka/server.properties
mkdir -p /opt/kafka-logs-1
sed -i "s/log.dirs\=\/tmp\/kafka-logs/log.dirs\=\/opt\/kafka-logs-1/g" /etc/kafka/server.properties
sed -i "s/num.partitions\=1/num.partitions\=3/g" /etc/kafka/server.properties
sed -i "s/\#delete.topic.enable\=true/delete.topic.enable\=true/g" /etc/kafka/server.properties
sed -i "s/zookeeper.connect\=localhost\:2181/zookeeper.connect\=localhost\:2181,10.30.3.2\:2181,10.30.3.3\:2181,10.30.3.4\:2181/g" /etc/kafka/server.properties
/usr/bin/systemctl enable kafka
chown -R kafka:kafka /opt/kafka-logs-1
chown -R kafka:kafka /opt/kafka
/usr/bin/systemctl start kafka
sed -i "s/XmlIpcRegSvc    9092\/tcp                \# Xml-Ipc Server Reg/kafka    9092\/tcp                \# Kafka/g" /etc/services
lsof -i TCP:9092 | grep LISTEN
echo "Completed installation of Kafka"


#######################
# CENTOS 7.2 UPDATE
#######################

echo "Updating CentOS 7.2..."
rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
yum clean all
yum -y update
echo "Completed updating CentOS 7.2..."
