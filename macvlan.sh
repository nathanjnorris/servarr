#!/bin/sh

# Create the macvlan device
ip link add macvlan0 link enp1s0 type macvlan mode bridge
# Give the host an IP address on the macvlan network
ip addr add 192.168.8.6/32 dev macvlan0
# Bring the interface up
ip link set macvlan0 up
# Add a route
ip route add 192.168.8.4/30 dev macvlan0