#!/bin/bash

# SETUP:
#   * Replace '#iface eth0 inet<some-char>dhcp' with '# iface eth0 inet dhcp'
net="${1}"
ip_address="${2}"
eth_name="${3}"
dns="${4}"

dns_nameserver=""
file=temp.txt
net_mask="255.255.255.0"
os=`cat /etc/issue | head -n1 | awk '{print $1}'`
echo $os

function usage() {
  echo "USAGE: ${0} dhcp eth_name"
  echo -e "USAGE ubuntu static:\n   ${0} static ip_address eth_name{default first non lo} <dns_nameserver>"
  echo -e "USAGE fedora static:\n   ${0} static ip_address <dns_nameserver>"
}

#sed -i "s/\(BOOTPROTO=\)\(.*\)/\1$1/" $IFCFG_DIR/ifcfg-mgmt0

function ubuntu_to_static() {

  echo "ubuntu_to_static $file"
  #cat $file
  gateway=$(echo $ip_address | sed 's/[^.]*$/1/')
  if [ -z $dns ]
  then
      dns_server=$gateway
  else
      dns_server=$dns
  fi
  sudo sed -i \
      -e "/iface $eth_name/a address $ip_address" \
      -e "/iface $eth_name/a netmask 255.255.255.0" \
      -e "/iface $eth_name/a gateway $gateway" \
      -e "/iface $eth_name/a dns-nameservers $dns_server" \
      -e "s/\(iface $eth_name inet \)\(.*\)/\1"static"/" $file
  echo "Changed ens160 to static IP"
}
#-e '/iface\s$eth_name/{n;N;N;N;d}'
function ubuntu_to_dhcp() {
  echo "ubuntu_to_dhcp interface:$eth_name"
  echo "file:$file"
  sudo sed -i \
      -e "s/\(iface $eth_name inet \)\(.*\)/\1"dhcp"/" $file \
      -e "/iface $eth_name/{n;N;N;N;d}"
  echo "Changed $eth_name to DHCP"
}


function fedora_to_static() {
  echo "fedora_to_dhcp"
  sed -i "s/\(BOOTPROTO=\)\(.*\)/\1static/" $file
  sed -i "s/\(IPADDR=\)\(.*\)/\1$ip_address/" $file
  gateway=$(echo $ip_address | sed 's/[^.]*$/1/')
  #gateway=`sed 's/[^.]*$/1/' <<< $ip_address`
  sed -i "s/\(GATEWAY=\)\(.*\)/\1$gateway/" $file
  grep -q -e 'NETMASK=' $file || sed -i '/IPADDR=/a NETMASK=' $file
  sed -i "s/\(NETMASK=\)\(.*\)/\1$net_mask/" $file
  echo "dns is $dns"
  if [ ! -z $dns ]
  then
      sed -i "s/\(DNS1=\)\(.*\)/\1$dns/" $file
  fi
  echo "Changed eth0 to static IP"
}

function fedora_to_dhcp() {
  echo "fedora_to_dhcp"
  sed -i "s/\(BOOTPROTO=\)\(.*\)/\1dhcp/" $file
  echo "Changed eth0 to DHCP"
}

function fedora_handling(){
    file=/etc/sysconfig/network-scripts/ifcfg-mgmt0
    dns=$eth_name
    echo "file: $file"
    if [ "dhcp" == "${net}" ]; then
      fedora_to_dhcp
    else
      fedora_to_static
    fi
    echo
    echo "result:"
    cat "$file"
    exit 0
}

if [ "x" == "x${net}" ]; then
  usage
  exit 0
fi

if [[ "Fedora" == "$os" ]]; then
    echo "os is: " $os
    fedora_handling
elif [[ "Ubuntu" == "$os" ]]; then
    file=/etc/network/interfaces
    if [ "dhcp" == "${net}" ]; then
        ubuntu_to_dhcp
    else
        ubuntu_to_static
    fi
    echo "result:"
    cat "$file"
fi
exit 0
