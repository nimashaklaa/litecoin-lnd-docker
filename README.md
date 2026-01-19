# Litecoin Lightning Network Node (Docker)

A Docker-based setup for running an LND (Lightning Network Daemon) node connected to a remote Litecoin node.

## Architecture

```
┌─────────────────────┐         ┌─────────────────────────────┐
│   Your PC (Docker)  │         │   Remote Server             │
│                     │         │                             │
│  ┌───────────────┐  │   RPC   │  ┌───────────────────────┐  │
│  │     LND       │◄─┼─────────┼──►    litecoind          │  │
│  │ (Lightning)   │  │   ZMQ   │  │  (your litecoind host)  │ │
│  └───────────────┘  │         │  └───────────────────────┘  │
│                     │         │                             │
└─────────────────────┘         └─────────────────────────────┘
```

## Prerequisites

- Docker and Docker Compose installed
- Access to a running litecoind node with:
  - RPC enabled
  - ZMQ enabled for raw blocks and transactions
  - RPC credentials

## Quick Start

### 1. Clone this repository

```bash
git clone <your-repo-url>
cd litecoin-lnd-node
```

### 2. Configure environment variables

```bash
# Copy the example env file
cp .env.example .env

# Edit with your credentials
nano .env
```

Fill in your litecoind connection details:
- `LITECOIND_RPCHOST` - Your litecoind RPC endpoint
- `LITECOIND_RPCUSER` - RPC username
- `LITECOIND_RPCPASS` - RPC password
- `LITECOIND_ZMQPUBRAWBLOCK` - ZMQ endpoint for blocks
- `LITECOIND_ZMQPUBRAWTX` - ZMQ endpoint for transactions

### 3. Build and run

```bash
# Build the Docker image
docker-compose build

# Start the node
docker-compose up -d
```

### 4. Create a wallet (first time only)

```bash
# Access the container
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin create
```

Follow the prompts to:
1. Create a new wallet password
2. Optionally create a new seed or restore from existing

### 5. Unlock wallet (after restarts)

```bash
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin unlock
```

## Common Commands

All commands use the prefix:
```bash
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin <command>
```

### Node Info
```bash
# Get node info
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin getinfo

# Get wallet balance
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin walletbalance
```

### Generate Address
```bash
# Get a new address to receive LTC
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin newaddress p2wkh
```

### Connect to Peers
```bash
# Connect to another node
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin connect <pubkey>@<host>:<port>

# List connected peers
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin listpeers
```

### Channel Operations
```bash
# Open a channel
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin openchannel <pubkey> <amount>

# List channels
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin listchannels

# Close a channel
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin closechannel <channel_point>
```

### Payments
```bash
# Create an invoice
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin addinvoice --amt=<amount>

# Pay an invoice
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin payinvoice <payment_request>
```

## Logs

```bash
# View LND logs
docker-compose logs -f lnd

# View last 100 lines
docker-compose logs --tail=100 lnd
```

## Stop/Restart

```bash
# Stop the node
docker-compose down

# Restart
docker-compose restart

# Rebuild and restart
docker-compose up -d --build
```

## Directory Structure

```
litecoin-lnd-node/
├── docker-compose.yml    # Docker Compose configuration
├── .env.example          # Example environment variables
├── .env                  # Your actual credentials (git-ignored)
├── lnd/
│   ├── Dockerfile        # LND Docker image
│   └── lnd.conf          # LND configuration
└── README.md
```

## Ports

| Port  | Service       | Description                    |
|-------|---------------|--------------------------------|
| 9735  | Lightning P2P | Peer-to-peer Lightning Network |
| 10009 | gRPC          | gRPC API for programmatic use  |
| 8080  | REST          | REST API                       |

## Troubleshooting

### "unable to connect to litecoind"
- Check that your litecoind is running and accessible
- Verify RPC credentials in `.env`
- Ensure ports are open on the remote server

### "waiting for chain backend to finish sync"
- LND needs to wait for litecoind to fully sync
- Check litecoind sync status

### "wallet not found"
- Run the wallet creation command (see step 4)

## Security Notes

- Never commit your `.env` file with real credentials
- Keep your wallet password and seed phrase secure
- Back up your `~/.lnd` directory regularly
