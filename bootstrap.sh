#!/usr/bin/env bash

# Set timezone
rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/London /etc/localtime

# Instal EPEL
rpm --import https://fedoraproject.org/static/0608B895.txt
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm  

# Install IUS
rpm -Uvh http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/i386/ius-release-1.0-13.ius.centos6.noarch.rpm

# Install apache, php, mysql and git
yum install -y git vim mysql-server mysql httpd mod_ssl php56u php56u-bcmath php56u-cli php56u-common php56u-devel php56u-gd php56u-imap php56u-mbstring php56u-mcrypt php56u-mysql php56u-pdo php56u-pear php56u-soap php56u-xml php56u-pecl-xdebug

# Set up apache for Laravel
echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf
VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot "/vagrant/laravel/public"
  ServerName localhost
  <Directory "/vagrant/laravel/public">
	AllowOverride All
  </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" >> /etc/httpd/conf/httpd.conf

# PHP error reporting for development
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php.ini

# XDebug settings
cat << EOF | sudo tee -a /etc/php.ini
xdebug.scream=1
xdebug.cli_color=1
xdebug.show_local_vars=1
xdebug.var_display_max_depth=-1
xdebug.var_display_max_children=-1
xdebug.var_display_max_data=-1
EOF

# Enable services
chkconfig mysqld on
chkconfig httpd on
service mysqld start
service httpd start

# Get composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Set up mysql - not secure at all but its fine for dev
echo "GRANT ALL on *.* TO root@'%' identified by 'root'" | mysql -uroot
echo "GRANT ALL on *.* TO root@'localhost' identified by 'root'" | mysql -uroot
echo "FLUSH PRIVILEGES" | mysql -uroot -proot

# Laravel specific
cd /vagrant/laravel/
/usr/local/bin/composer install --dev
# Laravel Database
echo "CREATE DATABASE IF NOT EXISTS laravel" | mysql -uroot -proot
echo "CREATE USER 'laravel'@'localhost' IDENTIFIED BY 'laravel'" | mysql -uroot -proot
echo "GRANT ALL PRIVILEGES ON laravel.* TO 'laravel'@'localhost' IDENTIFIED BY 'laravel'" | mysql -uroot -proot
# Create and seed database
php artisan migrate --env=development
php artisan db:seed --env=development
