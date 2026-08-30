# Lab Summary and Q&A

## Q&A

**Q: In the current configuration, `pc1` is assigned IP `192.168.1.10`. The `santanna` switch has IP `192.168.1.1` on `br0`. However, a ping from `pc1` to `192.168.1.1` results in "Destination host unreachable". Packet captures show the ARP request arriving at the switch, but no reply is generated. Why does this occur?**

**A:** This behavior illustrates a fundamental principle of Software-Defined Networking (SDN): the strict separation of the Control Plane and Data Plane.

The sequence of events is as follows:

### Control Plane Preemption of Local Interfaces

1. **Packet Arrival:** `pc1` transmits an ARP request. It physically arrives at `eth2` on the `santanna` switch.
2. **Open vSwitch Interception:** Because `eth2` is enslaved to the Open vSwitch bridge (`br0`), the OVS datapath intercepts the frame before the Linux kernel processes it.
3. **Flow Rule Override:** The `br0` bridge is managed by the ONOS controller. Upon connection, ONOS provisions OpenFlow rules that supersede standard Linux bridging and routing behaviors.
4. **Omission of the `LOCAL` Port:** The IP address `192.168.1.1` resides on the internal Linux networking stack, represented in OVS as the `LOCAL` port. Basic ONOS applications (like `fwd` and `proxyarp`) are designed to forward traffic exclusively between external physical ports. Consequently, ONOS does not instruct OVS to forward ARP requests to the `LOCAL` port.

### Outcome
Because ONOS lacks instructions to forward traffic to the local host's networking stack, the ARP request is dropped at the OVS layer. The internal Linux kernel of the switch never receives the request, precluding an ARP reply.

### Verification Method
To confirm that ONOS policies are responsible for the dropped packets, the switch can be temporarily disconnected from the controller:
```bash
ovs-vsctl del-controller br0
```
Upon disconnection, OVS enters `fail-standalone` mode, reverting to traditional bridging behavior. The ping will subsequently succeed. To restore SDN control, execute `ovs-vsctl set-controller br0 tcp:131.114.54.2:6653`.

---

**Q: After activating the `fwd` and `proxyarp` applications in ONOS, pinging `192.168.1.1` from `pc1` no longer returns "Destination host unreachable", but the ping remains unanswered. Packet captures indicate the ICMP echo request arrives, and OpenFlow rules show packets destined for the switch's MAC address being forwarded out of `eth1`. Will enabling NAT or IP forwarding in the switch resolve this?**

**A:** No, enabling NAT or IP forwarding within the switch OS will not resolve the issue, as the ICMP packet never reaches the Linux routing engine.

### 1. ARP Resolution Success
Activating `proxyarp` allows ONOS to properly handle ARP broadcasts, enabling `pc1` to successfully resolve the switch's MAC address.

### 2. Forwarding Logic Failure
The failure occurs during the forwarding of the ICMP echo request due to the following ONOS-generated OpenFlow rule:
`priority=10, in_port=eth2, dl_src=..., dl_dst=...[switch MAC] actions=output:eth1`

When `pc1` sends the ICMP request addressed to the switch's MAC address, the `fwd` application misinterprets the destination. Designed primarily for host-to-host communication, `fwd` assumes the MAC address belongs to an external node rather than the switch's internal `LOCAL` interface. Consequently, it forwards the packet out of `eth1` (towards the `unipi` switch) instead of delivering it to the local operating system.

### Remediation via Manual Flow Entry
To bypass this limitation, a higher-priority OpenFlow rule must be manually injected to instruct OVS to deliver packets addressed to its own MAC directly to the local network stack:

```bash
ovs-ofctl add-flow br0 -O OpenFlow13 "priority=50000,dl_dst=<SWITCH_MAC>,actions=LOCAL"
```
This forces the packet to the `LOCAL` port, allowing the internal Linux kernel to generate the ICMP Echo Reply.

---

**Q: Why did pinging work flawlessly in the `test` project (where all devices were in the same subnet) without assigning IP addresses to the switch bridges, whereas cross-subnet communication fails in `project-2`?**

**A:** The distinction lies in Layer 2 switching versus Layer 3 routing requirements.

In the `test` project, both hosts (`pc1` and `pc2`) resided in a single, flat Layer 2 subnet. Communication between them relied entirely on MAC addresses. The ONOS `fwd` application operates as a Layer 2 learning switch; it efficiently learned the external MAC addresses and forwarded the Ethernet frames across the topology. The switches did not require IP addresses on their `br0` interfaces because they acted purely as transparent transit nodes.

In `project-2`, the hosts reside in different subnets (`192.168.1.0/24` and `192.168.2.0/24`). A ping across subnets requires the packet to be sent to a default gateway, which must perform Layer 3 routing operations, including MAC rewriting and TTL decrementing. The `fwd` application lacks Layer 3 routing logic, rendering it incapable of forwarding traffic between distinct subnets.

---

**Q: What happens if the gateway IP (e.g., `192.168.1.1`) is assigned directly to the physical interface (`eth2`) instead of the bridge (`br0`)?**

**A:** Assigning an IP address to `eth2` while it is enslaved to an Open vSwitch bridge will result in a total loss of IP connectivity to the switch on that port. 

When a physical interface is added to a bridge (`ovs-vsctl add-port br0 eth2`), the Linux kernel relinquishes Layer 3 processing capabilities for that interface. `eth2` functions solely as a raw data conduit for the OVS datapath. The Linux IP stack will ignore packets arriving on `eth2`. To maintain IP connectivity, the IP address must be assigned to the logical bridge interface (`br0`), which serves as the internal pathway (`LOCAL` port) between the OVS datapath and the host operating system.

---

**Q: Can a single transit switch (like `unipi`) act as the gateway for multiple subnets simultaneously?**

**A:** Yes, through the use of IP aliasing. A single bridge interface can host multiple IP addresses belonging to different subnets. For example, `unipi` can be configured as follows:
```bash
ifconfig br0 192.168.1.254 netmask 255.255.255.0 up
ifconfig br0:0 192.168.2.254 netmask 255.255.255.0 up
```
This allows the internal Linux OS of the switch to establish a logical presence in both subnets. However, in an SDN environment where OVS intercepts data plane traffic, the controller must be explicitly programmed to forward traffic to these local interfaces.

---

**Q: If we enable IP forwarding in all switches (`sysctl -w net.ipv4.ip_forward=1`) and manually add `actions=LOCAL` rules, will inter-subnet routing succeed?**

**A:** No. While enabling IP forwarding prepares the Linux kernel to act as a router, relying on this mechanism fundamentally contradicts the SDN architecture.

If the `actions=LOCAL` rule forces traffic into the switch's Linux kernel, the kernel will attempt to route the packet. However, for `santanna` to route traffic to `pc2`, it requires static routes defining the path via `unipi`. Configuring distributed static routes on every switch converts the topology back into a traditional, distributed routing network, entirely bypassing the SDN controller's capabilities. 

In a properly designed SDN architecture, the controller (e.g., via Segment Routing applications) calculates the optimal paths and pushes specialized OpenFlow rules (such as `mod_dl_dst` and `dec_ttl`) to perform hardware-level routing, eliminating the need for the switches' local operating systems to participate in data plane routing.

---

**Q: When manually injecting a rule into the switch using `ovs-ofctl`, the rule functions briefly before being removed. Why is the rule deleted?**

**A:** The removal occurs because the ONOS controller enforces strict state synchronization, acting as the Single Source of Truth for the network.

The process operates as follows:
1. A flow rule is manually injected via `ovs-ofctl`.
2. ONOS periodically polls the switch for its active flow tables (typically every 5-10 seconds).
3. The switch reports the presence of the manually injected rule.
4. ONOS compares the reported flows against its internal intent and flow databases. Recognizing the manual rule as unverified, it flags it as an extraneous flow.
5. To maintain network consistency and prevent unauthorized data plane modifications, ONOS automatically issues an `OFPFC_DELETE` command to purge the flow.

To persistently install custom rules in an SDN environment, administrators must utilize the controller's northbound interfaces (such as the REST API or Intent Framework) rather than configuring the data plane switches directly.
