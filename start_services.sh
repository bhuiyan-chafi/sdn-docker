#!/bin/bash

# Startup script for Mininet Docker container
# Starts required services and provides interactive shell

echo "Starting Mininet Docker Container..."

# Start Open vSwitch services
echo "Starting Open vSwitch services..."
service openvswitch-switch start

# Wait a moment for services to initialize
sleep 2

# Verify OVS is running
echo "Verifying Open vSwitch..."
if ovs-vsctl show >/dev/null 2>&1; then
    echo "✓ Open vSwitch is running"
else
    echo "✗ Open vSwitch failed to start"
    echo "Attempting to restart..."
    service openvswitch-switch restart
    sleep 2
fi

# Clean up any previous mininet state
echo "Cleaning up previous mininet state..."
mn -c >/dev/null 2>&1 || true

echo "Services started successfully!"
echo ""
echo "Available commands:"
echo "  mn --test pingall                    # Quick connectivity test"
echo "  python3 examples/simple_topology.py  # Run example topology"
echo ""
echo "Container ready for SDN development!"
echo ""

# If arguments provided, execute them; otherwise start interactive bash
if [ $# -eq 0 ]; then
    exec /bin/bash
else
    exec "$@"
fi