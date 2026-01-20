#!/bin/bash

echo "Starting Litecoin LND node..."
docker-compose up -d

echo "Waiting for container to be ready..."
sleep 5

# Check if running in interactive terminal
if [ -t 0 ]; then
    echo "Unlocking wallet..."
    docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin unlock
else
    echo ""
    echo "Container started. To unlock wallet, run:"
    echo "  docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin unlock"
fi
