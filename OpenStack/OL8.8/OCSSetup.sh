#!/bin/bash

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

# Install Nova Compute service
sudo yum install -y openstack-nova-compute

# Configure Nova Compute
sudo cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
sudo crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
sudo crudini --set /etc/nova/nova.conf api auth_strategy keystone
sudo crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://<CONTROLLER_IP>:5000
sudo crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://<CONTROLLER_IP>:5000
sudo crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers <CONTROLLER_IP>:11211
sudo crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
sudo crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
sudo crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
sudo crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
sudo crudini --set /etc/nova/nova.conf keystone_authtoken username nova
sudo crudini --set /etc/nova/nova.conf keystone_authtoken password <NOVA_PASS>
sudo crudini --set /etc/nova/nova.conf DEFAULT my_ip <COMPUTE_NODE_IP>
sudo crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
sudo crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

# Start and enable Nova Compute service
sudo systemctl enable openstack-nova-compute
sudo systemctl start openstack-nova-compute

# Install Neutron Compute agent
sudo yum install -y openstack-neutron-openvswitch

# Configure Neutron Compute agent
sudo cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig
sudo crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://<CONTROLLER_IP>:5000
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://<CONTROLLER_IP>:5000
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers <CONTROLLER_IP>:11211
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name Default
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name Default
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken password <NEUTRON_PASS>

# Configure the Open vSwitch agent
sudo cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig
sudo crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings physnet1:br-ex
sudo crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
sudo crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True

# Start and enable Neutron Compute agent
sudo systemctl enable openstack-neutron-openvswitch-agent
sudo systemctl start openstack-neutron-openvswitch-agent

# Install Glance image service (optional)
# sudo yum install -y openstack-glance

echo "OpenStack compute node setup completed!"

# Install the Cinder service and client
sudo yum install -y openstack-cinder python3-oslo-db

# Configure the Cinder database
sudo cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.orig
sudo crudini --set /etc/cinder/cinder.conf database connection "mysql+pymysql://cinder:<CINDER_DB_PASS>@<CONTROLLER_IP>/cinder"

# Configure the RabbitMQ message broker
sudo crudini --set /etc/cinder/cinder.conf DEFAULT transport_url "rabbit://openstack:<RABBIT_PASS>@<CONTROLLER_IP>"

# Configure the Keystone authentication
sudo crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
sudo crudini --set /etc/cinder/cinder.conf keystone_authtoken www_authenticate_uri http://<CONTROLLER_IP>:5000
sudo crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://<CONTROLLER_IP>:5000
sudo crudini --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers <CONTROLLER_IP>:11211
sudo crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
sudo crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name Default
sudo crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name Default
sudo crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name service
sudo crudini --set /etc/cinder/cinder.conf keystone_authtoken username cinder
sudo crudini --set /etc/cinder/cinder.conf keystone_authtoken password <CINDER_PASS>

# Configure the cinder-volume service to use LVM
sudo systemctl enable lvm2-lvmetad
sudo systemctl start lvm2-lvmetad

# Create a physical volume and volume group for Cinder
sudo pvcreate /dev/<YOUR_CINDER_DEVICE>
sudo vgcreate cinder-volumes /dev/<YOUR_CINDER_DEVICE>

# Configure the Cinder volume group in the Cinder configuration
sudo crudini --set /etc/cinder/cinder.conf DEFAULT volume_group cinder-volumes

# Start and enable the Cinder services
sudo systemctl enable openstack-cinder-api
sudo systemctl enable openstack-cinder-scheduler
sudo systemctl start openstack-cinder-api
sudo systemctl start openstack-cinder-scheduler

echo "Cinder setup completed!"
