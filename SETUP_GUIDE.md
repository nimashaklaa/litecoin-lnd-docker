# Litecoin LND Setup Guide

Complete step-by-step guide to set up and test your Litecoin Lightning Network node.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Configuration](#configuration)
4. [Building and Starting](#building-and-starting)
5. [Wallet Setup](#wallet-setup)
6. [Testing & Verification](#testing--verification)
7. [Common Operations Testing](#common-operations-testing)
8. [Troubleshooting Checklist](#troubleshooting-checklist)

---

## Prerequisites

### 1. System Requirements

**Check Docker Installation:**
```bash
docker --version
docker compose version
```

**Expected Output:**
```
Docker version 24.x.x or higher
Docker Compose version v2.x.x or higher
```

**If not installed:**
- macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
- Linux: Follow [Docker installation guide](https://docs.docker.com/engine/install/)

### 2. Litecoin Node Requirements

Your Litecoin node must be:
- ✅ Running and accessible
- ✅ Configured with RPC enabled
- ✅ Configured with ZMQ enabled
- ✅ On the same Docker network (if using Docker) or accessible from host

**Verify Litecoin Node is Running:**
```bash
# If Litecoin node is in Docker
docker ps | grep -i litecoin

# Check if RPC port is listening
lsof -i :19332  # or your RPC port

# Check if ZMQ ports are listening
lsof -i :28333  # ZMQ blocks
lsof -i :28332  # ZMQ transactions
```

**Litecoin Node Configuration Required:**
```ini
# In your litecoin.conf
server=1
rpcuser=your_username
rpcpassword=your_password
rpcport=19332
rpcallowip=0.0.0.0/0
rpcbind=0.0.0.0

# ZMQ Configuration (REQUIRED)
zmqpubrawblock=tcp://0.0.0.0:28333
zmqpubrawtx=tcp://0.0.0.0:28332
```

### 3. Network Requirements

**If Litecoin node is in Docker:**
- Note the Docker network name (e.g., `node_bitcoin`)
- Note the container name (e.g., `node-node-1`)

**Find Docker Network:**
```bash
docker inspect <litecoin-container-name> | grep -A 5 Networks
```

---

## Initial Setup

### Step 1: Clone or Navigate to Project

```bash
git clone https://github.com/nimashaklaa/litecoin-lnd-docker.git
cd litecoin-lnd-docker
```

### Step 2: Verify Project Structure

```bash
ls -la
```

**Expected files:**
```
docker-compose.yml
lnd/
  ├── Dockerfile
  └── lnd.conf
.env.example (optional)
README.md
TROUBLESHOOTING.md
```

---

## Configuration

### Step 1: Create Environment File

```bash
# Copy example if it exists, or create new
cp .env.example .env 2>/dev/null || touch .env
```

### Step 2: Configure Connection Settings

Edit `.env` file with your Litecoin node details:

**If Litecoin node is in Docker (same network):**
```bash
# .env
LITECOIND_RPCHOST="node-node-1:19332"
LITECOIND_RPCUSER="bcn-admin"
LITECOIND_RPCPASS="your_rpc_password"
LITECOIND_ZMQPUBRAWBLOCK=tcp://node-node-1:28333
LITECOIND_ZMQPUBRAWTX=tcp://node-node-1:28332
```

**If Litecoin node is on host machine:**
```bash
# .env
LITECOIND_RPCHOST="127.0.0.1:19332"
LITECOIND_RPCUSER="your_username"
LITECOIND_RPCPASS="your_password"
LITECOIND_ZMQPUBRAWBLOCK=tcp://127.0.0.1:28333
LITECOIND_ZMQPUBRAWTX=tcp://127.0.0.1:28332
```

**If Litecoin node is on remote server:**
```bash
# .env
LITECOIND_RPCHOST="your-server-ip:19332"
LITECOIND_RPCUSER="your_username"
LITECOIND_RPCPASS="your_password"
LITECOIND_ZMQPUBRAWBLOCK=tcp://your-server-ip:28333
LITECOIND_ZMQPUBRAWTX=tcp://your-server-ip:28332
```

### Step 3: Verify docker-compose.yml Network Configuration

**If Litecoin node is in Docker, ensure networks match:**

```yaml
# docker-compose.yml
services:
  lnd:
    networks:
      - node_bitcoin  # Must match Litecoin node's network

networks:
  node_bitcoin:
    external: true  # Use existing network
```

**Verify network exists:**
```bash
docker network ls | grep node_bitcoin
```

**If network doesn't exist, create it:**
```bash
docker network create node_bitcoin
```

---

## Building and Starting

### Step 1: Build Docker Image

```bash
# Clean build (recommended for first time)
docker compose down
docker volume rm litecoin-lnd-docker_lnd-data 2>/dev/null
docker compose build --no-cache
```

**Expected Output:**
```
[+] Building ... (should complete successfully)
✔ lnd  Built
```

**If build fails:**
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- Verify Go version in Dockerfile
- Check internet connection for git clone

### Step 2: Start LND Container

```bash
docker compose up -d
```

**Verify container is running:**
```bash
docker ps | grep litecoin-lnd
```

**Expected Output:**
```
litecoin-lnd   ...   Up ...   0.0.0.0:9735->9735/tcp, ...
```

### Step 3: Check Initial Logs

```bash
docker compose logs --tail=30 lnd
```

**Look for:**
- ✅ `[INF] LTND: Version: 0.14.2-beta.rc3`
- ✅ `[INF] LTND: Active chain: Litecoin (network=regtest)`
- ✅ `[INF] RPCS: RPC server listening on 0.0.0.0:10009`
- ✅ `[INF] LTND: Waiting for wallet encryption password`

**If you see errors:**
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Verify `.env` configuration
- Ensure Litecoin node is running

---

## Wallet Setup

### Step 1: Create Wallet (First Time Only)

```bash
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin create
```

**Follow the prompts:**

1. **Wallet Password:**
   - Enter a strong password (8+ characters)
   - Confirm the password
   - ⚠️ **SAVE THIS PASSWORD** - you'll need it to unlock the wallet

2. **Cipher Seed Passphrase (Optional):**
   - Press Enter twice to skip (recommended for testing)
   - Or enter a passphrase for extra security

3. **Create New Seed:**
   - Type `n` to create a new seed
   - Type `y` if you want to restore from existing seed

4. **Save Your Seed Phrase:**
   ```
   !!!YOU MUST WRITE DOWN THIS SEED TO BE ABLE TO RESTORE THE WALLET!!!
   
   ---------------BEGIN LND CIPHER SEED---------------
   1. word1    2. word2    3. word3    ...
   ...
   ---------------END LND CIPHER SEED-----------------
   ```
   - ⚠️ **CRITICAL:** Write down all 24 words
   - Store in a secure location
   - This is the ONLY way to recover your wallet

**Expected Output:**
```
lnd successfully initialized!
```

### Step 2: Verify Wallet Creation

```bash
docker compose logs --tail=20 lnd
```

**Look for:**
- ✅ `[INF] LNWL: Opened wallet`
- ✅ `[INF] CHRE: Primary chain is set to: litecoin`
- ✅ `[INF] LNWL: Started listening for litecoind block notifications via ZMQ`
- ✅ `[INF] LNWL: Started listening for litecoind transaction notifications via ZMQ`

**If you see ZMQ connection errors:**
- Verify Litecoin node is running
- Check ZMQ ports are accessible
- Verify network configuration

### Step 3: Unlock Wallet (After Restarts)

After container restarts, unlock the wallet:

```bash
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin unlock
```

Enter your wallet password when prompted.

---

## Testing & Verification

### Test 1: Verify LND is Running

```bash
docker exec litecoin-lnd lncli --network=regtest --chain=litecoin getinfo
```

**Expected Output:**
```json
{
    "version": "0.14.2-beta.rc3",
    "identity_pubkey": "02...",
    "alias": "litecoin-lightning-node",
    "num_pending_channels": 0,
    "num_active_channels": 0,
    "num_peers": 0,
    "block_height": 432,
    "synced_to_chain": false,
    "synced_to_graph": false,
    "testnet": false,
    "chains": [
        {
            "chain": "litecoin",
            "network": "regtest"
        }
    ]
}
```

**✅ Success Indicators:**
- `version` shows LND version
- `identity_pubkey` is present (your node's public key)
- `block_height` matches or is close to Litecoin node's height
- `chains` shows `litecoin` and `regtest`

### Test 2: Verify ZMQ Connection

```bash
docker compose logs lnd | grep -i zmq
```

**Expected Output:**
```
[INF] LNWL: Started listening for litecoind block notifications via ZMQ on ...
[INF] LNWL: Started listening for litecoind transaction notifications via ZMQ on ...
```

**✅ Success:** Both ZMQ connections established

**❌ Failure:** If you see "connection refused" or "unable to subscribe":
- Check Litecoin node ZMQ configuration
- Verify network connectivity
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Test 3: Verify RPC Connection

```bash
docker compose logs lnd | grep -i "litecoind\|rpc\|chain"
```

**Look for:**
- ✅ No RPC connection errors
- ✅ Chain sync messages
- ✅ Block height updates

### Test 4: Check Wallet Balance

```bash
docker exec litecoin-lnd lncli --network=regtest --chain=litecoin walletbalance
```

**Expected Output:**
```json
{
    "total_balance": "0",
    "confirmed_balance": "0",
    "unconfirmed_balance": "0"
}
```

**✅ Success:** Command executes without errors (balance may be 0 initially)

### Test 5: Generate Test Address

```bash
docker exec litecoin-lnd lncli --network=regtest --chain=litecoin newaddress p2wkh
```

**Expected Output:**
```json
{
    "address": "ltc1..."
}
```

**✅ Success:** Address generated successfully

### Test 6: Verify Ports are Accessible

```bash
# Check if ports are listening
lsof -i :9735   # Lightning P2P
lsof -i :10009  # gRPC
lsof -i :8080   # REST API
```

**Expected Output:**
```
COMMAND  PID  ...  NAME
docker   ...  ...  *:9735 (LISTEN)
docker   ...  ...  *:10009 (LISTEN)
docker   ...  ...  *:8080 (LISTEN)
```

**✅ Success:** All three ports are listening

### Test 7: Test REST API

```bash
# Get node info via REST API
curl -k https://localhost:8080/v1/getinfo \
  --cert ~/.lnd/tls.cert \
  --macaroon ~/.lnd/admin.macaroon 2>/dev/null || \
curl http://localhost:8080/v1/getinfo
```

**Or test from container:**
```bash
docker exec litecoin-lnd curl -s http://localhost:8080/v1/getinfo | head -20
```

**✅ Success:** Returns JSON with node information

---

## Common Operations Testing

### Test 1: Create Invoice

```bash
docker exec litecoin-lnd lncli --network=regtest --chain=litecoin addinvoice --amt=1000
```

**Expected Output:**
```json
{
    "r_hash": "...",
    "payment_request": "lntb...",
    "add_index": "0",
    "payment_addr": "..."
}
```

**✅ Success:** Invoice created with payment request

### Test 2: List Invoices

```bash
docker exec litecoin-lnd lncli --network=regtest --chain=litecoin listinvoices
```

**Expected Output:**
```json
{
    "invoices": [
        {
            "memo": "",
            "r_preimage": "...",
            "r_hash": "...",
            "value": "1000",
            "value_msat": "1000000",
            "settled": false,
            "creation_date": "...",
            "settle_date": "0",
            "payment_request": "lntb...",
            "add_index": "0"
        }
    ]
}
```

**✅ Success:** Lists all invoices (including the one you just created)

### Test 3: Get Node URI

```bash
docker exec litecoin-lnd lncli --network=regtest --chain=litecoin getinfo | grep -A 5 uris
```

**Expected Output:**
```json
"uris": [
    "02...@your-ip:9735"
]
```

**✅ Success:** Shows your node's public URI for peer connections

### Test 4: List Peers

```bash
docker exec litecoin-lnd lncli --network=regtest --chain=litecoin listpeers
```

**Expected Output:**
```json
{
    "peers": []
}
```

**✅ Success:** Command works (may be empty if no peers connected)

### Test 5: List Channels

```bash
docker exec litecoin-lnd lncli --network=regtest --chain=litecoin listchannels
```

**Expected Output:**
```json
{
    "channels": []
}
```

**✅ Success:** Command works (may be empty if no channels opened)

---

## Troubleshooting Checklist

### Build Issues

- [ ] Docker and Docker Compose installed and working
- [ ] Internet connection available (for git clone)
- [ ] Sufficient disk space
- [ ] Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for specific errors

### Connection Issues

- [ ] Litecoin node is running
- [ ] RPC port (19332) is accessible
- [ ] ZMQ ports (28333, 28332) are accessible
- [ ] `.env` file has correct credentials
- [ ] Docker network configuration matches Litecoin node's network
- [ ] Container names/hostnames are correct

### Wallet Issues

- [ ] Wallet created successfully
- [ ] Wallet password saved securely
- [ ] Seed phrase backed up
- [ ] Wallet unlocked after container restart

### Runtime Issues

- [ ] Container is running: `docker ps | grep litecoin-lnd`
- [ ] No errors in logs: `docker compose logs lnd`
- [ ] ZMQ connections established (check logs)
- [ ] RPC connections working (check logs)
- [ ] Ports are listening (9735, 10009, 8080)

---

## Quick Reference Commands

### Container Management
```bash
# Start
docker compose up -d

# Stop
docker compose down

# Restart
docker compose restart lnd

# View logs
docker compose logs -f lnd

# Rebuild
docker compose build --no-cache
```

### LND Commands (all use this prefix)
```bash
docker exec -it litecoin-lnd lncli --network=regtest --chain=litecoin <command>
```

### Common lncli Commands
```bash
# Node info
getinfo

# Wallet
walletbalance
newaddress p2wkh

# Peers
listpeers
connect <pubkey>@<host>:<port>

# Channels
listchannels
openchannel <pubkey> <amount>

# Payments
addinvoice --amt=<amount>
payinvoice <payment_request>
listinvoices
```

---

## Next Steps

Once everything is tested and working:

1. **Secure Your Setup:**
   - Change default passwords
   - Secure your seed phrase
   - Review firewall rules
   - Enable TLS for REST API

2. **Connect to Network:**
   - Find peers to connect to
   - Open channels
   - Start routing payments

3. **Monitor:**
   - Set up log monitoring
   - Track channel balances
   - Monitor network status

4. **Backup:**
   - Regularly backup wallet
   - Save channel states
   - Document configuration

---

## Additional Resources

- [README.md](README.md) - General information
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Detailed troubleshooting guide
- [LND Documentation](https://docs.lightning.engineering/)
- [Litecoin Lightning Network](https://litecoin-foundation.org/)

---

## Support

If you encounter issues not covered in this guide:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review logs: `docker compose logs lnd`
3. Verify all prerequisites are met
4. Check Litecoin node connectivity
5. Review Docker network configuration

