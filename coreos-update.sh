#!/bin/bash

if [ ! "${USER}" = "root" ] ; then
   echo -e "!! Enter $(tput setaf 1)sudo $0$(tput sgr0) to update !!"
   echo && exit 0 ; fi

# get discovery url
if [ ! -f etcd.key ] ; then
   curl https://discovery.etcd.io/new\?size=3 -o ./etcd.key; fi

echo && echo
read -p "Please enter new node number: " new

if ! [ $new -eq $new ] 2>/dev/null ; then
        echo -e "$(tput setaf 1)!! Exit -- Sorry, integer only !!$(tput sgr0)"
        exit 1; fi
if [ -z $new ] || [ $new -lt 1 ] || [ $new -gt 254 ] ; then
        echo -e "$(tput setaf 1)!! Exit -- node number out of range !!$(tput sgr0)"
        exit 1; fi

new=$(echo $new | sed 's/^0*//')

intf=$(ifconfig | grep -m1 ^e | awk -F: '{print $1 }')
oldhost=$(hostname)
oldip=$(ifconfig | grep $intf -A 1 | grep inet | awk '{ print $2 }')

newhost=$(echo $oldhost | cut -d- -f1)-$new
newip=$(echo $oldip | cut -d. -f4 --complement).$new

read -p "Change hostname? [enter] for no change: " new
if [ ! -z $new ] ; then  newhost=$new-$(echo $newhost | cut -d- -f2) ; fi

# update config.yml
sudo cp /var/lib/coreos-install/user_data config.yml
sudo sed -i "s/$oldhost/$newhost/" config.yml

discoveryUrl=$(cat etcd.key)

cat <<EOF_core >> config.yml 
coreos:
  etcd2:
    name: $newhost
    discovery: $discoveryUrl
    advertise-client-urls: http://$newip:2379,http://$newip:4001
    initial-advertise-peer-urls: http://$newip:2380
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$newip:2380

    units:
    - name: etcd2.service
      command: start

EOF_core

# write static.network

cat <<EOF_netw > netw
[Match]
   Name=$intf

[Network]
   DNS=61.88.88.88 139.130.4.4
   Address=$newip/24
   Gateway=$(echo $newip | cut -d. -f4 --complement).1

EOF_netw

echo
echo "$(tput setaf 6)!! Update node name from $oldhost to $newhost !!"
echo "!! Update node IP from $oldip to $newip !! $(tput sgr0)"
echo && echo System will restart in 10 seconds
sleep 10

mv config.yml /var/lib/coreos-install/user_data
mv netw /etc/systemd/network/static.network

echo Restarting ........
shutdown -r now
