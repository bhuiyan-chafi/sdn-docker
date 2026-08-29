# Kathará Lab Tasks: Hierarchical SDN Network with ONOS

Here is a step-by-step task list to help track the progress of building and running this lab:

- [x] **Analyze Requirements:** Review topology and design constraints from `README.md`.
- [x] **Create Blueprint (`lab.conf`):**
  - [x] Define ONOS node and bind to host port `8181`.
  - [x] Set up Management Collision Domain (`MGT`) for Control Plane isolation.
  - [x] Set up Data Plane collision domains for interconnecting switches (UniPI, Sant'Anna, Scuola Normale) and PCs.
- [x] **Create ONOS Startup Script (`onosnode.startup`):**
  - [x] Assign the controller management IP address (`131.114.54.2/24`).
- [x] **Create Switch Startup Scripts (`unipi.startup`, `santanna.startup`, `scuolanormale.startup`):**
  - [x] Configure Management IP for Control Plane.
  - [x] Start Open vSwitch service.
  - [x] Create internal `br0` bridge and add Data Plane ports.
  - [x] Link switches to the ONOS controller's OpenFlow port (`6653`).
  - [x] Enforce OpenFlow 1.3 and 1.4 protocols.
  - [x] Ensure no static routing is added for data subnets.
- [x] **Create PC Startup Scripts (`pc1.startup`, `pc2.startup`):**
  - [x] Configure `192.168.1.10/24` for PC1 and default gateway.
  - [x] Configure `192.168.2.10/24` for PC2 and default gateway.
- [x] **Run the Lab:** Open a terminal in the project directory and execute `kathara lstart`.
- [x] **Verify Control Plane:** Ensure ONOS node is running, the Web UI is accessible on `http://localhost:8181/onos/ui`, and switches are successfully connected via OpenFlow.
- [x] **Verify Data Plane / Routing:** (Future Step) Configure ONOS Segment Routing (Trellis) and verify that PC1 can ping PC2.

## Testing Reachability

-[x] switches can reach each other (they can because shares the same management network)

- [] `pc1:192.168.1.10` can ping `san'tanna:192.168.1.1` switch
