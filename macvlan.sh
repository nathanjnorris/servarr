#!/bin/sh

ip link add macvlan0 link enp1s0 type macvlan mode bridge

ip addr add 192.168.8.6/32 dev macvlan0

ip link set macvlan0 up

ip route add 192.168.8.4/30 dev macvlan0