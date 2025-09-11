#!/bin/bash

# Standalone Mininet Docker Management Script
# Usage: ./docker-run.sh [command]
NETWORK=labnet
SUBNET=172.28.0.0/16
MININET_CONTAINER="mininet-dev"
MININET_IMAGE="mininet-standalone"
ONOS_IMAGE="onosproject/onos:latest"
ONOS_CONTAINER="onos"
ONOS_IP="172.28.0.11"
MININET_IP="172.28.0.10"
OPENFLOW_PORT=6653
ONOS_GUI_PORT=8181
ONOS_CLI_PORT=8101

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "Error: Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Build the Docker image
build() {
    echo "Building docker network"
    # create network if missing
    docker network inspect "$NETWORK" >/dev/null 2>&1 || \
    docker network create --subnet "$SUBNET" "$NETWORK"
    # import images
    docker load -i mininet-standalone.tar
    docker load -i onos.tar
    # check if the images are loaded
    docker images
}

run_mininet() {
    check_docker
    # Stop existing container if running
    docker stop $MININET_CONTAINER
    sleep 2
    # Remove existing container if exists
    echo "Removing existing container..."
    docker rm $MININET_CONTAINER
    sleep 2
    echo "Starting new Mininet container..."
    docker run -it --privileged \
        --name $MININET_CONTAINER \
        --network "$NETWORK" --ip "$MININET_IP" \
        -v "$(pwd)/projects:/app/projects" \
        -v "/lib/modules:/lib/modules:ro" \
        $MININET_IMAGE
}

run_onos() {
    # Stop/remove old controller
     echo "Stopping existing container..."
    docker stop $ONOS_CONTAINER
    
    sleep 2
    # Remove existing container if exists
    echo "Removing existing container..."
    docker rm $ONOS_CONTAINER

    sleep 2
    # Starting new container
    echo "Starting ONOS..."
    docker run --name "$ONOS_CONTAINER" \
    --network "$NETWORK" --ip "$ONOS_IP" \
    -p ${ONOS_GUI_PORT}:8181 -p ${OPENFLOW_PORT}:6653 -p $ONOS_CLI_PORT:8101 \
    "$ONOS_IMAGE"

  echo -n "ONOS controller has been started"
}

# Enter running container
mininet_shell() {
    check_docker
    if ! docker ps -q -f name=$MININET_CONTAINER | grep -q .; then
        echo "Container $MININET_CONTAINER is not running. Starting it first..."
        run
    else
        echo "Entering container shell..."
        docker exec -it $MININET_CONTAINER /bin/bash
    fi
}

# Stop the container
stop() {
    echo "Stopping container..."
    docker stop $MININET_CONTAINER
    docker stop $ONOS_CONTAINER
    echo "Container stopped"
}

# Clean up everything
clean() {
    check_docker
    echo "Cleaning up Docker resources..."
    
    # Stop and remove mininet
    docker stop $MININET_CONTAINER 
    docker rm $MININET_CONTAINER 
    echo "Mininet Container removed"
    sleep 2
    # Remove mininet image
    docker rmi $MININET_IMAGE
    echo "Mininet Image removed"
    sleep 2
     # Stop and remove onos
    docker stop $ONOS_CONTAINER 
    docker rm $ONOS_CONTAINER 
    echo "Mininet Container removed"
    sleep 2
    # Remove onos image
    docker rmi $ONOS_IMAGE
    echo "ONOS Image removed"
    docker images
    sleep 2
    # Remove Network
    docker network rm $NETWORK
    docker network ls
    
    echo "Cleanup complete!"
}

# Show help
help() {
    echo "SDN - ONOS and Mininet"
    echo ""
    echo ""
    echo "Commands:"
    echo "  build           - Builds the network and loads the images"
    echo "  clean           - Removes network, container and image"
    echo "  run_mininet     - Starts the Mininet Container"
    echo "  run_onos        - Starts the ONOS Container"
    echo "  mininet_shell   - Takes you to the ubuntu shell to use mininet"
    echo "  stop            - Stops the containers"
}

# Main script logic
case "${1:-help}" in
    build)     build ;;
    clean)   clean ;;
    run_mininet)     run_mininet ;;
    run_onos)     run_onos ;;
    mininet_shell)   mininet_shell ;;
    stop)    stop ;;
    help)    help ;;
    *)       echo "Unknown command: $1"; help; exit 1 ;;
esac