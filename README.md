# Homelab Scripts
This is a collection of bash and other scripts designed with the purpose of automating some of the more tedious work in my homelab.

## OpenStack

Currently there is only one OpenStack script in the repository, one used for setting up a controller node. **YOU MUST EDIT BEFORE EXECUTING** due to the fact that there are several placeholder values for passwords, etc.

#### Controller Node Setup v1 (OCNSetup.sh)

This script is designed to run on Oracle Linux 8, and will setup the OpenStack repo on the system, and install the basic dependencies (MariaDB, RabbitMQ, and MemCacheD.

This script will set up the following OpenStack Services: 

 1. Keystone
 2. Glance

## Other Scripts

This repository will be updated regularly with scripts that may help me with my work.

#### To-Do

 - [ ] Create Script for OpenStack Compute Node setup
 - [ ] Create Scripts for testing DISA STIG Compliance
