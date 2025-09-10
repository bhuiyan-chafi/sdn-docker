#!/usr/bin/env python3
"""
Simple Topology Example for Mininet Docker Container

Creates a simple linear topology with 3 switches and 6 hosts.
Perfect for testing the standalone Mininet Docker environment.

Usage:
sudo python3 simple_topology.py
"""

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import RemoteController, OVSSwitch
from mininet.cli import CLI
from mininet.log import setLogLevel
from mininet.link import TCLink


class SimpleTopo(Topo):
    """Simple linear topology with 3 switches and 6 hosts."""

    def build(self):
        # Add switches
        s1 = self.addSwitch('s1')
        s2 = self.addSwitch('s2')
        s3 = self.addSwitch('s3')

        # Add hosts
        h1 = self.addHost('h1', ip='10.0.0.1/24')
        h2 = self.addHost('h2', ip='10.0.0.2/24')
        h3 = self.addHost('h3', ip='10.0.0.3/24')
        h4 = self.addHost('h4', ip='10.0.0.4/24')
        h5 = self.addHost('h5', ip='10.0.0.5/24')
        h6 = self.addHost('h6', ip='10.0.0.6/24')

        # Add links between switches (linear topology)
        self.addLink(s1, s2, bw=10)  # 10 Mbps link
        self.addLink(s2, s3, bw=10)  # 10 Mbps link

        # Add host-switch links
        self.addLink(h1, s1, bw=10)
        self.addLink(h2, s1, bw=10)
        self.addLink(h3, s2, bw=10)
        self.addLink(h4, s2, bw=10)
        self.addLink(h5, s3, bw=10)
        self.addLink(h6, s3, bw=10)


def run_topology():
    """Create and run the topology."""
    print("Creating simple linear topology...")

    # Set log level
    setLogLevel('info')

    # Create topology
    topo = SimpleTopo()

    # Create network with remote controller
    net = Mininet(
        topo=topo,
        controller=RemoteController('c0', ip='onos', port=6653),
        switch=OVSSwitch,
        link=TCLink,
        autoSetMacs=True
    )

    print("Starting network...")
    net.start()

    print("Network started successfully!")
    print("\nTopology:")
    print("h1 -- s1 -- s2 -- s3 -- h5")
    print("|           |           |")
    print("h2          h3,h4       h6")
    print("\nUse the following commands to test:")
    print("  pingall                    # Test connectivity")
    print("  h1 ping h6                # Ping across topology")
    print("  iperf h1 h6               # Bandwidth test")
    print("  h6 iperf -s &             # Start iperf server")
    print("  h1 iperf -c 10.0.0.6      # Connect to server")
    print("  exit                      # Exit mininet")
    print()

    # Start CLI
    CLI(net)

    print("Stopping network...")
    net.stop()


if __name__ == '__main__':
    run_topology()
