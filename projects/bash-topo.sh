#!/bin/sh

echo "--- clearing previous configuration....................."
./clear-bash-topo.sh
echo "--- Add hosts..........................................."
ip netns add h1
ip netns add h2
ip netns add h3
ip netns add h4

echo "--- Add Open vSwitch and powering up...................."
ovs-vsctl add-br s1
ovs-vsctl add-br s2
ovs-vsctl add-br s3
ifconfig s1 up
ifconfig s2 up
ifconfig s3 up

echo "--- Show ovs entries for confirmation..................."

ovs-vsctl show

echo "Creatign the connection between h1,h2 and s1"

ip link add veth-h1 type veth peer name veth-h1-br #physical wire to connect h1 with s1
ip link set veth-h1 netns h1 #moving the interface to h1, means plugged one side of this wire to h1
ovs-vsctl add-port s1 veth-h1-br #plugged another side to s1
ip link set veth-h1-br up #turning up the interface

ip link add veth-h2 type veth peer name veth-h2-br #physical wire to connect h2 with s1
ip link set veth-h2 netns h2 #moving the interface to h2, means plugged one side of this wire to h2
ovs-vsctl add-port s1 veth-h2-br #plugged another side to s1
ip link set veth-h2-br up #turning up the interface

echo "--- Connection from h1,h2 to s1 complete..............."
sleep 1

echo "Creatign the connection between h3,h4 and s3"

ip link add veth-h3 type veth peer name veth-h3-br #physical wire to connect h3 with s3
ip link set veth-h3 netns h3 #moving the interface to h3, means plugged one side of this wire to h3
ovs-vsctl add-port s3 veth-h3-br #plugged another side to s3
ip link set veth-h3-br up #turning up the interface

ip link add veth-h4 type veth peer name veth-h4-br #physical wire to connect h4 with s3
ip link set veth-h4 netns h4 #moving the interface to h4, means plugged one side of this wire to h4
ovs-vsctl add-port s3 veth-h4-br #plugged another side to s1
ip link set veth-h4-br up #turning up the interface
sleep 1

echo "---Connecting s1,s2,s3 ..............................."

ip link add s1s2-trunk type veth peer name s2s1-trunk #the trunk wire to connect s1,s2 switches together
ovs-vsctl add-port s1 s1s2-trunk #port of the s1
ovs-vsctl add-port s2 s2s1-trunk #port of the s2
ip link set s1s2-trunk up #powering up
ip link set s2s1-trunk up #powering up

ip link add s2s3-trunk type veth peer name s3s2-trunk #the trunk wire to connect s2,s3 switches together
ovs-vsctl add-port s2 s2s3-trunk #port of the s2 
ovs-vsctl add-port s3 s3s2-trunk #port of the s3
ip link set s2s3-trunk up #powering up
ip link set s3s2-trunk up #powering up

sleep 2

echo "--- VLAN and Tagging ................................"
ovs-vsctl set port veth-h1-br tag=100
ovs-vsctl set port veth-h3-br tag=100
ovs-vsctl set port veth-h2-br tag=200
ovs-vsctl set port veth-h4-br tag=200

echo "-----Adding VLAN tags to the trunk...."
ovs-vsctl set port s1s2-trunk trunks=[100,200]
ovs-vsctl set port s2s1-trunk trunks=[100,200]
ovs-vsctl set port s2s3-trunk trunks=[100,200]
ovs-vsctl set port s3s2-trunk trunks=[100,200]

echo "--- Configuring IP addresses ........................"
#we are not using a router so hosts with same VLAN is under the same subnet
ip -n h1 addr add 10.10.100.1/24 dev veth-h1 #VLAN 100
ip -n h2 addr add 10.10.200.2/24 dev veth-h2 #VLAN 200
ip -n h3 addr add 10.10.100.3/24 dev veth-h3 #VLAN 100
ip -n h4 addr add 10.10.200.4/24 dev veth-h4 #VLAN 200

echo "---Enabling self loop (optional) and veth-<hosts>.."
ip netns exec h1 ip link set lo up
ip netns exec h2 ip link set lo up
ip netns exec h3 ip link set lo up
ip netns exec h4 ip link set lo up

ip netns exec h1 ip link set veth-h1 up
ip netns exec h2 ip link set veth-h2 up
ip netns exec h3 ip link set veth-h3 up
ip netns exec h4 ip link set veth-h4 up
