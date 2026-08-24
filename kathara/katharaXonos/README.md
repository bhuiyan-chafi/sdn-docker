# About

This tutorial explains how we can create an standalone image featuring `Kathara` and `ONOS` together. The idea is generated and inspired by my Professor Alessio Giorgetti. I hope the tool is of great help.

## Create from scratch

Run the following command to build the image from scratch:

```bash
docker build -t kathara/onos-b5g . --no-cache
```

Once the image is built, test these following scenarios to make sure everything is working:

1. **Creating a container and connecting to its shell:**

   Make sure to expose the necessary ports for the ONOS Web UI (`8181`) and SSH (`8101`):

   ```bash
   docker run -it --rm -p 8181:8181 -p 8101:8101 --name kathara-onos-test kathara/onos-b5g /bin/bash
   ```

   Test external connecivity from the container:

   ```bash
   ping google.com
   ```

2. **Verifying Kathará base networking tools:**

   From inside the container shell, verify that the standard networking and system tools inherited from `kathara/core` are available:

   ```bash
   # Check networking utilities
   ip a
   iptables --version
   tcpdump --version
   ping -V
   ```

3. **Verifying Python, NetworkX, and Java environments:**

   ```bash
   # Verify Java (should be OpenJDK / Temurin 11)
   java -version

   # Verify Python 2 (required for Bazel ONOS toolchains)
   python2 -V

   # Verify Python 3 and NetworkX
   python3 -V
   python3 -c "import networkx as nx; print(f'NetworkX version: {nx.__version__}')"
   ```

4. **Verifying Bazel & ONOS installation:**

   ```bash
   # Verify Bazel version
   bazel version

   # Verify ONOS source folder
   ls -la $ONOS_ROOT
   ```

5. **Starting and testing ONOS:**

   Run the preconfigured helper script to start ONOS:

   ```bash
   start-onos
   ```

   Once ONOS has booted up, test accessing the ONOS CLI:

   ```bash
   source $ONOS_ROOT/tools/dev/bash_profile
   onos localhost
   ```

   _(Default credentials: user `onos`, password `rocks`)_

6. **WebUI**

   Since `ONOS` is running inside the container, we have to expose the ports to access it from the host machine. Run the following command to expose a port while creating the container:

   ```bash
   # remove the --rm option if you want to keep container after use
   docker run -it --rm -p 8181:8181 --name kathara-onos-test kathara/onos-b5g /bin/bash
   # to login in webui, use `karaf` as username and password both
   ```
