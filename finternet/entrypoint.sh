#!/bin/bash -e

AP_ADDR=192.168.0.1
AP_CHANNEL=${AP_CHANNEL:-36}
AP_SSID=${AP_SSID:-'finternet'}
AP_PASSWD=${AP_PASSWD:-'charlietheunicorn'}
AP_COUNTRY=${AP_COUNTRY:-'CL'}

HOSTAPD_OPTS=${HOSTAPD_OPTS:-''}

if [ "${AP_DEBUG}" = "true" ]; then
  HOSTAPD_OPTS="-d ${HOSTAPD_OPTS}"
fi

# Setup the wireless interface
iw dev wlan0 interface add uap0 type __ap

# Setup interface and restart DHCP service 
ip link set uap0 up
ip addr flush dev uap0
ip addr add ${AP_ADDR}/24 dev uap0

# Change the password and ssid
sed -i "s/^channel=.*/channel=${AP_CHANNEL}/g" /etc/hostapd.conf
sed -i "s/^ssid=.*/ssid=${AP_SSID}/g" /etc/hostapd.conf
sed -i "s/^wpa_passphrase=.*/wpa_passphrase=${AP_PASSWD}/g" /etc/hostapd.conf
sed -i "s/^country_code=.*/country_code=${AP_COUNTRY}/g" /etc/hostapd.conf

# Allow forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.default.forwarding=1
sysctl -w net.ipv6.conf.all.forwarding=1

# Configure iptables rules
#iptables -P FORWARD ACCEPT
#iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -i uap0 -o wwan0 -j ACCEPT
iptables -A FORWARD -i wwan0 -o uap0 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A POSTROUTING -o wwan0 -j MASQUERADE

# setup dnsmasq
dnsmasq -C /etc/dnsmasq.conf

hostapd ${HOSTAPD_OPTS} /etc/hostapd.conf
