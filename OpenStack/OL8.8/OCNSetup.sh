#!/bin/bash

# Malachi S. 
# OpenStack Controller Node Setup (OCNSetup.sh)
# Oracle Linux 8
# 8/4/2023 0255 MDT

# EDIT BEFORE EXECUTING

# Update the system
sudo yum update -y

# Disable SELinux
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Disable NetworkManager and enable network
sudo systemctl stop NetworkManager
sudo systemctl disable NetworkManager
sudo systemctl enable network
sudo systemctl start network

# Add OpenStack repositories
sudo yum install -y https://www.oracle.com/webfolder/technetwork/dist/public-yum/openstack21/oracle-linux-8.4-oci-openstack21.repo
sudo yum update -y

# Install essential packages
sudo yum install -y python3-openstackclient openstack-selinux

# Install MariaDB database server
sudo yum install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Secure the database installation
sudo mysql_secure_installation

# Install RabbitMQ message broker
sudo yum install -y rabbitmq-server
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server

# Add OpenStack user and permissions to RabbitMQ
sudo rabbitmqctl add_user openstack <RABBIT_PASS>
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# Install Memcached
sudo yum install -y memcached python3-memcached
sudo systemctl enable memcached
sudo systemctl start memcached

# Install Keystone identity service
sudo yum install -y openstack-keystone httpd mod_wsgi

# Configure Keystone
sudo cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.orig
sudo crudini --set /etc/keystone/keystone.conf database connection "mysql+pymysql://keystone:<KEYSTONE_DB_PASS>@<CONTROLLER_IP>/keystone"
sudo crudini --set /etc/keystone/keystone.conf token provider fernet
sudo su -s /bin/bash -c "keystone-manage db_sync" keystone
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage bootstrap --bootstrap-password <ADMIN_PASS> --bootstrap-admin-url http://<CONTROLLER_IP>:5000/v3/ --bootstrap-internal-url http://<CONTROLLER_IP>:5000/v3/ --bootstrap-public-url http://<CONTROLLER_IP>:5000/v3/ --bootstrap-region-id RegionOne

# Configure HTTPD
sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.orig
sudo sed -i 's/#ServerName www.example.com:80/ServerName <CONTROLLER_IP>/g' /etc/httpd/conf/httpd.conf

# Configure mod_wsgi
sudo cp /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
sudo sed -i 's/WSGISocketPrefix run\/wsgi/WSGISocketPrefix \/var\/run\/httpd/g' /etc/httpd/conf.d/wsgi-keystone.conf

# Start and enable HTTPD
sudo systemctl enable httpd
sudo systemctl start httpd

# Source the admin credentials
source /root/openrc

# Create projects, users, and roles
openstack project create --domain default --description "Admin Project" admin
openstack user create --domain default --password <ADMIN_PASS> admin
openstack role create admin
openstack role add --project admin --user admin admin

# Create service project
openstack project create --domain default --description "Service Project" service

# Create demo project, user, and role (optional)
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password <DEMO_PASS> demo
openstack role create user
openstack role add --project demo --user demo user

# Create the service entity for the Identity service
openstack service create --name keystone --description "OpenStack Identity" identity

# Create the Identity service API endpoint
openstack endpoint create --region RegionOne identity public http://<CONTROLLER_IP>:5000/v3
openstack endpoint create --region RegionOne identity internal http://<CONTROLLER_IP>:5000/v3
openstack endpoint create --region RegionOne identity admin http://<CONTROLLER_IP>:5000/v3

# Install Glance image service (optional)
sudo yum install -y openstack-glance

# Continue with other OpenStack services setup (Nova, Neutron, etc.) as needed.

echo "OpenStack controller node setup completed!"
