#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$HOME/sdn-docker/kathara/practice/onos-ovs"

# ─── Usage ────────────────────────────────────────────────────────────────────
usage() {
    echo ""
    echo "Usage: ./startKatharaXonos.sh [build|run]"
    echo ""
    echo "  build   Build the kathara/onos-b5g Docker image from the Dockerfile"
    echo "  run     Clean any existing lab and start the Kathara lab (image must exist)"
    echo ""
    exit 1
}

[ $# -ne 1 ] && usage

# ─── Build ────────────────────────────────────────────────────────────────────
if [ "$1" = "build" ]; then
    echo ""
    echo "============================================"
    echo " Building kathara/onos-b5g Docker image..."
    echo " (This will take several minutes)"
    echo "============================================"
    echo ""

    docker build -t kathara/onos-b5g "$SCRIPT_DIR" --no-cache

    echo ""
    echo "============================================"
    echo " Image built successfully!"
    echo "============================================"
    echo ""

# ─── Run ──────────────────────────────────────────────────────────────────────
elif [ "$1" = "run" ]; then
    # Verify the image exists before proceeding
    if ! docker image inspect kathara/onos-b5g > /dev/null 2>&1; then
        echo "[ERROR] Image 'kathara/onos-b5g' not found."
        echo "        Please run './startKatharaXonos.sh build' first."
        exit 1
    fi

    echo "Activating Kathara virtual environment..."
    source "$HOME/kathara-env/bin/activate"
    echo "  [OK] Virtual environment active."
    echo ""

    echo "============================================"
    echo " Starting Kathara lab in:"
    echo " $LAB_DIR"
    echo "============================================"
    echo ""

    cd "$LAB_DIR"

    echo "Cleaning any existing lab state..."
    python3 -m kathara lclean
    echo "  [OK] Lab cleaned."
    echo ""

    python3 -m kathara lstart

else
    usage
fi
