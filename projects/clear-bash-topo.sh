#!/bin/sh

echo "--- Deleting all namespaces............................."
ip -all netns delete
sleep 1

echo "--- Deleting all ovs...................................."
for br in $(ovs-vsctl list-br); do
    echo "Deleting ovs: $br"
    ovs-vsctl del-br $br
done
sleep 2

echo "--- Deleting all links.................................."

echo "Current links.."
ip -o link show type veth

echo "deleting if matching exists"
ip link del s1s2-trunk
ip link del s2s3-trunk
echo "Current links.."
ip -o link show type veth
sleep 1

echo "--- Show ovs entries for confirmation..................."
ovs-vsctl show