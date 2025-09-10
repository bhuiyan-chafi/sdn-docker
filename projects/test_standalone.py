#!/usr/bin/env python3
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import OVSSwitch
from mininet.cli import CLI
from mininet.log import setLogLevel
from mininet.link import TCLink


class OVSSwitch13(OVSSwitch):
    # Make sure bridges advertise/use OF1.3 (not strictly necessary for NORMAL,
    # but it matches your CLI usage and keeps things consistent)
    protocols = 'OpenFlow13'


class FiveSwitchTenHostTopo(Topo):
    """
    s1--s2--s3--s4--s5
    Two hosts per switch:
      s1: h1,h2 | s2: h3,h4 | s3: h5,h6 | s4: h7,h8 | s5: h9,h10
    """

    def build(self):
        # Switches
        s = {}
        for i in range(1, 6):
            s[i] = self.addSwitch(f's{i}')

        # Chain the switches linearly
        self.addLink(s[1], s[2])
        self.addLink(s[2], s[3])
        self.addLink(s[3], s[4])
        self.addLink(s[4], s[5])

        # Hosts: 10.0.0.1..10.0.0.10/24, gateway unset
        ip_idx = 1
        for i in range(1, 6):
            for _ in range(2):  # two hosts per switch
                h = self.addHost(f'h{ip_idx}', ip=f'10.0.0.{ip_idx}/24')
                self.addLink(h, s[i], bw=10)  # optional bw parameter
                ip_idx += 1


def run():
    setLogLevel('info')
    topo = FiveSwitchTenHostTopo()

    # No controller: we will make OVS switch locally (NORMAL)
    net = Mininet(
        topo=topo,
        controller=None,
        switch=OVSSwitch13,
        link=TCLink,
        autoSetMacs=True,
        autoStaticArp=True
    )

    net.start()

    # Prepare every bridge to behave like a standalone L2 switch:
    # - ensure OF1.3
    # - fail-mode=standalone
    # - add a default NORMAL flow so it forwards without a controller
    for sw in [f's{i}' for i in range(1, 6)]:
        s = net.get(sw)
        s.cmd(f'ovs-vsctl set bridge {sw} protocols=OpenFlow13')
        s.cmd(f'ovs-vsctl set-fail-mode {sw} standalone')
        s.cmd(f'ovs-ofctl -O OpenFlow13 del-flows {sw}')
        s.cmd(
            f'ovs-ofctl -O OpenFlow13 add-flow {sw} "priority=0,actions=NORMAL"')

    print("\nNetwork is up with standalone L2 switching.")
    print("Try: pingall, or h1 ping 10.0.0.10, etc.\n")

    CLI(net)
    net.stop()


if __name__ == '__main__':
    run()
