#!/bin/bash

# Prequisite:
# Boot CoreOS with LiveCD in VirtualBox or VMware.
# login console and enter command
# > git clone https://github.com/cloud-lab/CoreOS.git
# > cd CoreOS && ./coreos-install.sh
#
# --- Alternative method ---
# Use console access to create user for ssh access, e.g. Putty
# > sudo useradd -U -m sydadmin -G sudo
# > sudo passwd sydadmin
# ssh login with new user
# paste this file content and save as coreos-install.sh
# chmod +x coreos-install.sh
# execute coreos-install.sh

echo && echo
read -p "Create new CoreOS user - enter user name: " user
read -s -p "Password: " pass

if [ -z $pass ]; then
        echo -e "$(tput setaf 1)!! Exit -- No password !!$(tput sgr0)"
        exit 1; fi

echo
read -s -p "Enter password again: " password
if ! [ "$pass" == "$password" ]; then
        echo -e "$(tput setaf 1)!! Exit -- password does not match!!$(tput sgr0)"
        exit 1; fi

# hash password
password=`echo -n $pass | mkpasswd --method=SHA-512 --rounds=4096 -s`

echo

# write config.yml
cat <<EOF_core > config.yml
#cloud-config
users:
  - name: $user
    passwd: $password
    groups: [ sudo, docker ]

hostname: CoreOS-00

EOF_core

echo
echo "$(tput setaf 6)Installing CoreOS into HDD with user name - $user$(tput sgr0)"
echo && echo System will restart in 10 seconds
echo
sleep 10

# run installation
sudo chmod 755 /usr/bin/coreos-install
sudo /usr/bin/coreos-install -d /dev/sda -c config.yml -C alpha

echo -e "$(tput setaf 6)Installation has finished, please remove CoreOS live CD and reboot VM.$(tput sgr0)"
