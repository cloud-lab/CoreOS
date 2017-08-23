#!/bin/bash

echo && echo
read -p "Please enter CoreOS node number: " new

if ! [ $new -eq $new ] 2>/dev/null ; then
        echo -e "$(tput setaf 1)!! Exit -- Sorry, integer only !!$(tput sgr0)"
        exit 1; fi
if [ -z $new ] || [ $new -lt 1 ] || [ $new -gt 254 ] ; then
        echo -e "$(tput setaf 1)!! Exit -- node number out of range !!$(tput sgr0)"
        exit 1; fi

new=$(echo $new | sed 's/^0*//')
subnet=192.168.100.

cd ~
# write static.network
cat <<EOF_netw > netw
[Match]
        Name=enp0s8
[Network]
        DNS=198.142.152.164
        Address=$subnet$new/24
EOF_netw

# update hostname and ip address in coreos' user_data
sudo cp /var/lib/coreos-install/user_data config.yml
oldhost=$(sudo cat config.yml | grep hostname: | cut -d: -f2 | cut -c 1-)
oldip=$(sudo cat config.yml | grep listen-peer | cut -d: -f3 | cut -c 3-)
sudo sed -i -e "s/$oldhost/core$new/" -e "s/$oldip/$subnet$new/g" config.yml

echo $oldip ">>" $subnet$new
echo $oldhost ">>" core$new
echo "$(tput setaf 6) !! Reboot in 10 seconds. Update node name from $oldhost to core$new !! $(tput sgr0)"

sleep 10
sudo mv config.yml /var/lib/coreos-install/user_data
sudo mv netw /etc/systemd/network/static.network

echo Restarting ........
sudo shutdown -r now
