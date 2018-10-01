#!/bin/bash

# commands to install Mediawiki website and its dependencies"

yum install httpd php php-mysql php-xcache  php-gd php-xml mysql-server mysql wget

chkconfig httpd on

chkconfig mysqld on

cd /home/
wget https://releases.wikimedia.org/mediawiki/1.31/mediawiki-1.31.1.tar.gz
tar -xvzf mediawiki-1.31.1.tar.gz
cp mediawiki-1.31.1/* /var/www/html
service httpd restart
exit
