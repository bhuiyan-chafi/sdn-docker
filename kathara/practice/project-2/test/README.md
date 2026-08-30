# ONOS Layer 2 Forwarding Test (`fwd` App)

## Overview

This project is a modified clone of `project-2`, designed specifically to demonstrate the capabilities and limitations of the ONOS `fwd` (Reactive Forwarding) and `proxyarp` applications.

In the original `project-2`, `pc1` and `pc2` were placed in **different subnets** (192.168.1.0/24 and 192.168.2.0/24). When trying to route traffic between them using only the `fwd` app, the pings failed.

This `test` project was created to prove **why** it failed, by placing all data plane equipment (`pc1`, `pc2`, and the switches) into a **single subnet** (`192.168.1.0/24`).

## The Verdict: What this lab proves

By placing everything in a single subnet and running the `fwd` app, pings between `pc1` and `pc2` succeed completely automatically without any static routing or `netcfg.json` configuration.

This proves that:

1. **The `fwd` app is strictly a Layer 2 (MAC-based) application.** It functions exactly like a traditional "dumb" learning switch. It learns source MAC addresses and forwards packets to destination MAC addresses.
2. **The `fwd` app is blind to IP headers.** It does not understand subnets, it cannot decrement TTLs, and it cannot rewrite MAC addresses.
3. **You cannot use `fwd` for routing.** To route traffic between different subnets (like in the original `project-2`), you must deactivate `fwd` and instead use a Layer 3 routing application (like `reactive-routing`) paired with a `netcfg.json` file to tell ONOS where the subnets and virtual gateways are.

## Topology & IP Addressing

All data plane devices share the `192.168.1.0/24` subnet:

- `pc1`: 192.168.1.10
- `pc2`: 192.168.1.20
- `santanna` switch (`br0`): 192.168.1.1
- `unipi` switch (`br0`): 192.168.1.2
- `scuolanormale` switch (`br0`): 192.168.1.3

_(Note: Default gateways were removed from the PCs because they are no longer necessary in a flat L2 network)._

## How to run

1. Start the lab: `kathara lstart`
2. Connect to the ONOS CLI and verify the `fwd` and `proxyarp` apps are active.
3. Ping `pc2` from `pc1`: `ping 192.168.1.20`.
4. The ping will succeed, demonstrating that ONOS successfully bridged the flat network using OpenFlow rules.
