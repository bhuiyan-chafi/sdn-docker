#!/bin/bash
NETWORK=labnet
IP="172.28.0.12"
IMAGE_NAME=maven
CONTAINER_NAME=maven

build(){
    if ! docker network inspect "$NETWORK" >/dev/null 2>&1; then
        echo "Docker network '$NETWORK' does not exist. Exiting..."
        exit 1
    fi
    echo "Building the docker image....."
    docker build -t $IMAGE_NAME .
    sleep 2
    docker run -it --name $CONTAINER_NAME --network $NETWORK -p 2222:22 \
    -v "$(pwd)/work:/home/alessio/work" $IMAGE_NAME
}

install(){
    echo "Starting the installation....."
    # stop if any container is running 
    docker stop $CONTAINER_NAME
    sleep 2
    # remove container
    docker rm $CONTAINER_NAME
    sleep 2
    # remove image
    docker rmi $IMAGE_NAME
    sleep 2
    # load the image
    docker load -i maven.tar
    sleep 2
    # run container
    docker run -it --name $CONTAINER_NAME --network $NETWORK -p 2222:22 \
    -v "$(pwd)/work:/home/alessio/work" $IMAGE_NAME
}

clean(){
    echo "Stopping $CONTAINER_NAME ....."
    docker stop $CONTAINER_NAME
    sleep 2
    echo "Removing $CONTAINER_NAME ....."
    docker rm $CONTAINER_NAME
    sleep 2
    echo "Removing $IMAGE_NAME ....."
    docker rmi $IMAGE_NAME
}

# Show help
help() {
    echo "Maven to build ONOS external applications"
    echo ""
    echo ""
    echo "Commands:"
    echo "  build           - builds the docker image from scratch"
    echo "  clean           - Removes, container and image"
}

# Main script logic
case "${1:-help}" in
    build)     build ;;
    install)    install;;
    clean)   clean ;;
    run_mininet)     run_mininet ;;
    run_onos)     run_onos ;;
    mininet_shell)   mininet_shell ;;
    stop)    stop ;;
    help)    help ;;
    *)       echo "Unknown command: $1"; help; exit 1 ;;
esac