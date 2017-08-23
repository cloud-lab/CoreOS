#!/bin/bash

# Prequisite:
# Boot CoreOS with LiveCD in VirtualBox or VMware.
# Use console access to create user for ssh access, e.g. Putty
# > sudo useradd -U -m sydadmin -G sudo
# > sudo passwd sydadmin
# ssh login with new user
# paste this file content and save as core-cd.sh
# chmod +x core-cd.sh
# execute core-cd.sh

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
read -p "Please enter CoreOS node number: " new

if ! [ $new -eq $new ] 2>/dev/null ; then
        echo -e "$(tput setaf 1)!! Exit -- Sorry, integer only !!$(tput sgr0)"
        exit 1; fi
if [ -z $new ] || [ $new -lt 1 ] || [ $new -gt 254 ] ; then
        echo -e "$(tput setaf 1)!! Exit -- node number out of range !!$(tput sgr0)"
        exit 1; fi
new=$(echo $new | sed 's/^0*//')

oldip=$(ifconfig | grep enp0s3 -A 1 | grep inet | awk '{ print $2 }')

newhost=CoreOS-$new
newip=$(echo $oldip | cut -d. -f4 --complement).$new

# write config.yml
cat <<EOF_core > config.yml
#cloud-config
users:
  - name: $user
    passwd: $password
    groups: [ sudo, docker ]
hostname: $newhost
networkd:
  units:
    - name: 10-static.network
      contents: |
      [Match]
      Name=enp0s3
      [Network]
      DNS=61.88.88.88 139.130.4.4
      Address=$newip/24
      Gateway=$(echo $newip | cut -d. -f4 --complement).1
EOF_core

echo
echo "$(tput setaf 6)Install vm $newhost into HDD"
echo "with new user $user and"
echo "new IP address $newip ......$(tput sgr0)"
echo && echo System will restart in 10 seconds
echo
sleep 10

# run installation
sudo chmod 755 /usr/bin/coreos-install
sudo /usr/bin/coreos-install -d /dev/sda -c config.yml -C alpha

echo -e "$(tput setaf 6)Installation finishes, please remove CoreOS live CD and reboot VM.$(tput sgr0)"
