# Summary of ONOS and OVS VLAN Routing Integration

## 1. The Core Problem

The objective of Task 4 was to verify connectivity between an Open vSwitch (OVS) internal gateway port (`vlan100-gw`) on `lswitch1` and a locally connected host (`pc1`) on a VLAN access port (`eth2`).

When `lswitch1` was connected to the ONOS SDN controller, pings from the switch to the host resulted in **100% packet loss**.

Traffic captures (`tcpdump`) revealed that while the host (`pc1`) successfully received and replied to ARP requests, ONOS dropped the return packets. As the OpenFlow controller, ONOS takes absolute control of the forwarding table, but its default routing applications do not natively understand how to bridge traffic between internal OVS gateway ports and VLAN-tagged access ports.

---

## 2. Trials and Troubleshooting

We systematically attempted multiple solutions to natively resolve this using ONOS, observing the limitations at each step:

### Trial 1: OVS Standalone Fail Mode

- **Attempt**: We added `ovs-vsctl set bridge br0 fail_mode=standalone` to the switch startup scripts, hoping OVS would fall back to normal hardware switching for packets ONOS couldn't handle.
- **Result/Problem**: Failed. Standalone mode only activates if the switch completely loses its connection to the controller. Because ONOS was actively connected, it forced the switch to stay in `secure` mode, aggressively dropping unmatched packets.

### Trial 2: Activating ONOS `fwd` and `proxyarp` Apps

- **Attempt**: We discovered that the reactive forwarding (`fwd`) and Proxy ARP apps were not starting automatically. We modified `onosnode.startup` to ensure these apps started in the background.
- **Result/Problem**: Failed. The ping still suffered 100% packet loss. While the apps intercepted the ARP packets (installing `arp actions=CONTROLLER` in the OVS flow table), they did not install any Layer 2 forwarding paths for the ICMP traffic because they are designed for flat L2 edge-host networks, not VLAN-aware internal routing.

### Trial 3: Replacing Internal Ports with `veth` Pairs

- **Attempt**: We hypothesized that ONOS was ignoring `vlan100-gw` because it was explicitly typed as an OVS `internal` port. We deleted it and replaced it with a Linux `veth` pair (`veth100-br` and `veth100-host`) so ONOS would see it as a standard physical interface.
- **Result/Problem**: Failed. ONOS still failed to bridge the traffic, confirming the issue was rooted in its handling of the VLAN tags (`tag=100`) rather than the interface type.

### Trial 4: Reconfiguring `fwd` dynamically via REST API

- **Attempt**: We used the ONOS REST API to dynamically reconfigure the `org.onosproject.fwd.ReactiveForwarding` application, enabling `matchVlanId=true` and `matchIpv4Address=true`.
- **Result/Problem**: Failed. The `fwd` app still failed to install the correct flow rules. This proved that basic reactive forwarding apps cannot handle this topology without advanced configuration.

### Trial 5: Injecting a Static `NORMAL` Flow

- **Attempt**: We used `ovs-ofctl add-flow br0 "priority=50000,actions=NORMAL" -O OpenFlow13` to explicitly tell OVS to bypass ONOS for standard Layer 2 forwarding.
- **Result/Problem**: Succeeded briefly, then failed. The ping worked perfectly with 0% packet loss for a few seconds. However, ONOS features an aggressive flow reconciliation engine. It noticed a flow it didn't authorize and automatically deleted it, causing the ping to fail again.

---

## 3. Final Adopted Solution

To satisfy the lab requirements (all switches must remain connected to the controller) while allowing local VLAN routing to function, we adopted an aggressive daemon workaround.

We injected the following background loop into `lswitch1.startup` and `lswitch2.startup`:

```bash
nohup bash -c 'while true; do ovs-ofctl add-flow br0 "priority=50000,actions=NORMAL" -O OpenFlow13 2>/dev/null; sleep 1; done' >/dev/null 2>&1 &
```

**Why it works**: The daemon constantly re-adds the `NORMAL` flow rule every second. If the ONOS reconciler deletes the rule, the script immediately replaces it. This guarantees that OVS handles its own local VLAN routing (allowing Task 4 pings to succeed) while the switch maintains an active OpenFlow connection to ONOS.

---

## 4. What is Missing / Unsolved Native ONOS Limitations

Because we are forcing local traffic to bypass ONOS, we encounter side-effects that cannot be resolved using the basic `fwd` application:

1. **Topology Graph Glitches**: ONOS discovers network links by sending LLDP packets. Because we forced the switches to use `NORMAL` switching, they flood these LLDP packets across the data plane instead of sending them straight back to the controller. This causes ONOS to draw inaccurate links in its GUI (e.g., showing `lswitch1` directly connected to `lswitch2`).
2. **True Native SDN Routing**: To natively route VLANs across an enterprise network without the `NORMAL` flow hack, ONOS requires the **Segment Routing (TRELLIS)** application. This requires writing a comprehensive `netcfg` JSON file that hardcodes every switch DPID, subnet, and VLAN, and completely removes the OVS internal ports (making ONOS the default gateway). Due to its complexity, it falls far outside the scope of a standard academic SDN lab.

---

## 5. Frequently Asked Questions

**Q: Why does `ping 10.10.1.2` (pc1) work directly from `lswitch1` without specifying an interface, but `ping 10.10.1.3` (pc2) fails unless I use `-I vlan200-gw`?**

**A:** This is due to standard Linux routing behavior when multiple interfaces share the exact same subnet (`10.10.1.0/24`).
When the kernel looks up the route for `10.10.1.X`, it picks the **very first matching rule** in the Main Routing Table (which defaults to `vlan100-gw`).

- Because `pc1` is physically in VLAN 100, the ping succeeds.
- Because `pc2` is in VLAN 200, the ping still blindly goes out `vlan100-gw` (getting tagged with VLAN 100), so it never reaches `pc2`.
  By using `-I vlan200-gw`, you explicitly trigger the custom **Policy Routing** rules (`ip rule`) we added in the startup script, forcing the kernel to use `table 200` and properly tag the packet for VLAN 200.

**Note: In the later configuration, this has been changed. Now we can ping the hosts from the switch using their IP**

<br>

**Q: If we are manually configuring static routes and default gateways on every device ourselves, why do we even need OpenFlow/ONOS in this lab?**

**A:** You are entirely correct—in this specific lab setup, we bypassed OpenFlow almost completely, reverting to traditional distributed networking!
This happened because we relied on ONOS's built-in **Reactive Forwarding (`fwd`)** application. The `fwd` app is extremely basic; it is only designed to handle flat, untagged Layer 2 networks (essentially acting like one giant switch). It does not understand IP subnets, VLAN gateways, or Layer 3 routing.
When we introduced VLANs and cross-subnet routing, `fwd` broke. To fix the network without writing our own custom Java application for ONOS, we had to bypass OpenFlow using the `NORMAL` daemon hack and manually build the L3 routing ourselves.

In a true production SDN environment (like AT&T or Comcast), you would never configure static routes on the switches. Instead of `fwd`, you would run the **Trellis / Segment Routing (SR)** application suite in ONOS. You would feed ONOS a single JSON file describing the subnets, and ONOS would automatically push the complex OpenFlow rules to every switch to route the traffic end-to-end natively. In short, you only had to do everything yourself because the basic `fwd` app was out of its depth!

<br>

**Q: Are the `gw-x` and `ethX` the same thing on the switches (e.g., in `parentswitch.startup`)?**

**A:** No, they are fundamentally different types of interfaces that serve two different purposes in the Linux networking stack and Open vSwitch (OVS):

1. **`ethX` (The Physical Layer 2 "Cables"):**
   Interfaces like `eth1` and `eth2` are standard physical network interfaces provided by the Linux container. In our Kathara lab, these represent the physical cables connecting the switches together. We plug these into the OVS bridge (`ovs-vsctl add-port br0 eth1`). **Notice that we never assign an IP address to `eth1` or `eth2`.** They operate strictly at Layer 2, blindly passing raw Ethernet frames into the software switch.

2. **`gw-x` (The Virtual Layer 3 "Gateways"):**
   Interfaces like `gw-b` and `gw-c` do not exist physically. They are **OVS internal software ports** created by setting `type=internal`. When you create an internal port, OVS creates a virtual port inside the software switch and simultaneously exposes it as a network interface to the Linux kernel. **We assign IP addresses to these ports.** They act as the Layer 3 gateways for the switch, allowing the Linux kernel to participate in routing.

**How They Work Together:** When a packet arrives on a physical "cable" (`eth1`), the switch receives it at Layer 2 and forwards it internally to the virtual gateway (`gw-b`). The Linux kernel sitting on `gw-b` receives the packet, looks at the destination IP, routes it to the other virtual interface (`gw-c`), and sends it back down into the switch to be forwarded out the other physical cable (`eth2`).

<br>

**Q: As I can see we have a physical interface `eth0` in `parentswitch.startup` with an IP `131.114.54.74`. But this physical interface is not attached to `br0` which is exposed to ONOS. But we did add `eth1` and `eth2` in `br0`. How does this exposure work?**

**A:** This perfectly illustrates the fundamental SDN concept of separating the **Control Plane** from the **Data Plane** using an Out-of-Band Management Network:

1. **`eth0` is the Control Plane (Management):**
   When you assign an IP to `eth0`, you are giving an IP to the Linux operating system running the switch, *not* to the `br0` software switch itself. When we run `ovs-vsctl set-controller br0 tcp:...`, Open vSwitch uses the Linux kernel's routing table to establish a TCP connection to the controller out through `eth0`. 
   **Why isn't it in `br0`?** Because we explicitly do not want regular user traffic mixing with our critical SDN management traffic. If `eth0` were added to the data-plane bridge, a broadcast storm caused by a user could easily sever the connection to the controller!

2. **`eth1` and `eth2` are the Data Plane (User Traffic):**
   These interfaces are the "dumb pipes" meant entirely for user traffic. We plug them into `br0` so OVS can route traffic between them. Once OVS successfully establishes the OpenFlow connection to ONOS via `eth0`, it sends a message over the control plane saying: *"I have a bridge named `br0` with physical ports `eth1` and `eth2`."* ONOS then learns the topology and pushes OpenFlow rules back down over `eth0` to tell the switch exactly how to handle packets arriving on the `eth1` and `eth2` data-plane ports.
