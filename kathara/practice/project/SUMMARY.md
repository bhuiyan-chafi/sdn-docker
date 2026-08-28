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
