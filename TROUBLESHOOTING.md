# Troubleshooting & Development Notes

This document explains the issues encountered while setting up Litecoin LND and the solutions attempted.

## Quick Reference - Common Issues

| Issue | Solution |
|-------|----------|
| Go version too old | Use `golang:1.23-alpine` |
| Tag not found | Use `v0.14.2-beta` or latest available tag |
| "No names found" git error | Use full clone, not shallow (`--depth 1`) |
| go.mod out of sync | Run `go mod tidy` before `make install` |
| Compilation errors on main branch | Use tagged release instead |
| ZMQ connection refused | Connect to Litecoin container via Docker network |
| IPv6 connection issues | Use container name instead of localhost |
| Can't reach Litecoin node | Use `node-node-1` (container name) in `.env` |

## Problem Summary

The goal was to build a Docker container running LND (Lightning Network Daemon) compatible with Litecoin. The main challenge was finding a compatible version of LND that works with modern Litecoin Core RPC responses.

## Attempt 1: lightningnetwork/lnd v0.17.5-beta

### What Was Tried
- Used the official `lightningnetwork/lnd` repository
- Built version `v0.17.5-beta` (last version with Litecoin support)
- Successfully built and ran the container
- Wallet creation worked

### Why It Failed
**Error:**
```
unable to create partial chain control: unable to determine if bitcoind is pruned: 
json: cannot unmarshal object into Go struct field SoftForks.softforks of type []*btcjson.SoftForkDescription
```

**Root Cause:**
- Litecoin Core's RPC response format for `getblockchaininfo` changed
- The `SoftForks` field structure differs from what LND v0.17.5-beta expects
- LND v0.17.5-beta was designed for Bitcoin Core's RPC format, not Litecoin Core's updated format
- This is a known compatibility issue between older LND versions and newer Litecoin Core versions

**Conclusion:** The official `lightningnetwork/lnd` repository doesn't maintain Litecoin compatibility in newer versions, and older versions are incompatible with modern Litecoin Core.

---

## Attempt 2: ltcsuite/lnd (Litecoin's Official Fork)

### What Was Tried
Switched to `ltcsuite/lnd`, which is Litecoin's official fork of LND maintained specifically for Litecoin compatibility.

### Attempt 2a: Non-existent Tag

**What Was Tried:**
- Attempted to use tag `v0.17.5-beta.rc1.ltc1`
- This tag doesn't exist in the ltcsuite/lnd repository

**Error:**
```
error: pathspec 'v0.17.5-beta' did not match any file(s) known to git
```

**Why It Failed:**
- The ltcsuite/lnd repository has different versioning than lightningnetwork/lnd
- Latest stable release is `v0.14.2-beta` (much older than v0.17.5-beta)
- The repository doesn't have a v0.17.5-beta equivalent

### Attempt 2b: Main Branch with Go 1.21

**What Was Tried:**
- Used `ltcsuite/lnd` main branch (latest code)
- Built with Go 1.21-alpine (as used in original Dockerfile)

**Error:**
```
go: go.mod requires go >= 1.24.2 (running go 1.21.13; GOTOOLCHAIN=local)
```

**Why It Failed:**
- The main branch of ltcsuite/lnd requires Go 1.24.2 or higher
- The Dockerfile was using Go 1.21-alpine
- Go 1.24 doesn't exist yet (as of 2024, latest is Go 1.23)
- This suggests the main branch may be using experimental/unreleased Go features or has incorrect go.mod requirements

**Conclusion:** The main branch is not suitable for production use due to Go version requirements.

---

## Current Solution: ltcsuite/lnd with Tag Selection

### What We're Using Now
- Repository: `ltcsuite/lnd` (Litecoin's official fork)
- Go Version: `1.23-alpine` (latest stable Go version)
- Version Strategy: Automatically selects the latest available beta tag, falls back to `v0.14.2-beta`

### Dockerfile Strategy
The current Dockerfile:
1. Clones the full ltcsuite/lnd repository
2. Fetches all tags
3. Automatically finds the latest `v*beta*` tag
4. Falls back to `v0.14.2-beta` if no tags are found
5. Uses Go 1.23 (compatible with older LND versions)

### Why This Should Work
- `ltcsuite/lnd` is specifically maintained for Litecoin compatibility
- Using tagged releases ensures stability
- Go 1.23 is compatible with older LND versions (v0.14.2-beta era)
- Tagged releases have tested go.mod requirements

### Potential Issues
- **Older LND Version:** v0.14.2-beta is significantly older than v0.17.5-beta
  - May lack newer features
  - May have security updates missing
  - But should be compatible with Litecoin Core
  
- **Go Version Mismatch:** If the latest tag requires Go 1.24+, the build will fail
  - Need to either:
    - Use an older tag that works with Go 1.23
    - Wait for Go 1.24 release (if it's real)
    - Use a pre-release Go version (not recommended)

---

## Next Steps & Recommendations

### Option 1: Use Known Working Tag (Recommended)
Pin to a specific known-working tag:
```dockerfile
RUN git checkout v0.14.2-beta
```

### Option 2: Update Go Version
If newer ltcsuite/lnd tags require Go 1.24+:
- Wait for official Go 1.24 release
- Or use Go 1.23 and pin to compatible tags

### Option 3: Build from Specific Commit
If tags are problematic, use a specific commit hash that's known to work:
```dockerfile
RUN git checkout <commit-hash>
```

### Option 4: Contribute to ltcsuite/lnd
- Report the Go version requirement issue
- Help maintain Litecoin compatibility
- Update documentation

---

## Testing Checklist

After building, verify:
- [ ] Container builds successfully
- [ ] LND starts without errors
- [ ] Wallet creation works
- [ ] Can connect to litecoind RPC
- [ ] No SoftForks unmarshaling errors
- [ ] Can create channels (if testing full functionality)

---

## Key Learnings

1. **lightningnetwork/lnd ≠ Litecoin Compatible**
   - Official LND is Bitcoin-focused
   - Litecoin compatibility was removed in newer versions
   - Older versions incompatible with modern Litecoin Core

2. **ltcsuite/lnd is the Solution**
   - Official Litecoin fork
   - Maintained for Litecoin compatibility
   - But versioning is different and older

3. **Version Management is Critical**
   - Tag selection vs main branch matters
   - Go version compatibility must match
   - RPC format compatibility is version-dependent

4. **Docker Build Strategy**
   - Use tagged releases for stability
   - Match Go version to LND requirements
   - Have fallback versions ready

---

## References

- [lightningnetwork/lnd](https://github.com/lightningnetwork/lnd) - Official LND (Bitcoin)
- [ltcsuite/lnd](https://github.com/ltcsuite/lnd) - Litecoin LND fork
- [LND Documentation](https://docs.lightning.engineering/)
- [Litecoin Lightning Network](https://litecoin-foundation.org/)

---

## Error Logs Reference

### Error 1: SoftForks Unmarshaling
```
[ERR] LTND: unable to create partial chain control: unable to determine if bitcoind is pruned: 
json: cannot unmarshal object into Go struct field SoftForks.softforks of type []*btcjson.SoftForkDescription
```
**Solution:** Use ltcsuite/lnd instead of lightningnetwork/lnd

### Error 2: Tag Not Found
```
error: pathspec 'v0.17.5-beta' did not match any file(s) known to git
```
**Solution:** Check available tags: `git ls-remote --tags https://github.com/ltcsuite/lnd.git`

### Error 3: Go Version Too Old
```
go: go.mod requires go >= 1.24.2 (running go 1.21.13; GOTOOLCHAIN=local)
```
**Solution:** Use tagged release instead of main branch, or update Go version

### Error 4: Invalid Docker Image Tag
```
failed to solve: golang:latest-alpine: not found
```
**Error Details:**
- Attempted to use `golang:latest-alpine` which doesn't exist
- Docker Hub doesn't have a `latest-alpine` tag

**Solution:** Use `golang:alpine` or a specific version like `golang:1.23-alpine`

### Error 5: Git Version Description Error
```
fatal: No names found, cannot describe anything.
```
**Error Details:**
- Occurs when using `git clone --depth 1` (shallow clone)
- Build process tries to get version from git tags, but shallow clone doesn't include tags

**Solution:** Use full clone instead of shallow clone:
```dockerfile
RUN git clone https://github.com/ltcsuite/lnd.git
# Instead of:
RUN git clone --depth 1 https://github.com/ltcsuite/lnd.git
```

### Error 6: go.mod Updates Required
```
go: updates to go.mod needed; to update it:
  go mod tidy
```
**Error Details:**
- Dependencies in go.mod are out of sync
- Need to run `go mod tidy` before building

**Solution:** Add `go mod tidy` step before `make install`:
```dockerfile
WORKDIR /go/src/github.com/ltcsuite/lnd
RUN go mod tidy
RUN make install tags="signrpc walletrpc chainrpc invoicesrpc"
```

### Error 7: Compilation Error - FinalizePsbt
```
lnwallet/btcwallet/psbt.go:523:53: not enough arguments in call to b.wallet.FinalizePsbt
  have (*waddrmgr.KeyScope, uint32, *psbt.Packet)
  want (*waddrmgr.KeyScope, uint32, *mweb.Keychain, *psbt.Packet)
```
**Error Details:**
- Main branch of ltcsuite/lnd has breaking changes
- API signature mismatch between lnd code and wallet library
- Indicates version incompatibility

**Solution:** Use a stable release tag instead of main branch:
```dockerfile
RUN git clone https://github.com/ltcsuite/lnd.git && \
    cd lnd && \
    git fetch --tags && \
    LATEST_TAG=$(git tag -l 'v*beta*' | sort -V | tail -1) && \
    git checkout ${LATEST_TAG:-v0.14.2-beta}
```

### Error 8: ZMQ Connection Refused (host.docker.internal)
```
[ERR] LTND: unable to subscribe for zmq block events: dial tcp 192.168.65.254:28333: connect: connection refused
```
**Error Details:**
- LND trying to connect via `host.docker.internal` (Docker Desktop's special hostname)
- Resolves to `192.168.65.254` but connection fails
- ZMQ ports not accessible through Docker's host gateway

**Initial Attempts:**
1. Tried `host.docker.internal` - doesn't work reliably for ZMQ on macOS
2. Tried `localhost` - resolves to IPv6 `[::1]` which may not be listening
3. Tried `127.0.0.1` - works but requires host networking mode

**Solution:** Use container networking (see Error 9)

### Error 9: ZMQ Connection Refused (IPv6)
```
[ERR] LTND: unable to subscribe for zmq block events: dial tcp [::1]:28333: connect: connection refused
```
**Error Details:**
- Using `localhost` resolves to IPv6 `[::1]` 
- Litecoin node may only be listening on IPv4 `127.0.0.1`
- Or Litecoin node is in a different Docker container

**Solution:** Connect LND to the same Docker network as Litecoin node:
```yaml
# docker-compose.yml
services:
  lnd:
    networks:
      - node_bitcoin  # Same network as Litecoin node

networks:
  node_bitcoin:
    external: true
```

And update `.env` to use container name:
```
LITECOIND_RPCHOST="node-node-1:19332"
LITECOIND_ZMQPUBRAWBLOCK=tcp://node-node-1:28333
LITECOIND_ZMQPUBRAWTX=tcp://node-node-1:28332
```

---

## Complete Build Issues & Solutions

### Issue 1: Go Version Progression

**Problem:** Multiple Go version issues encountered

**Timeline:**
1. Started with `golang:1.21-alpine` - too old for main branch
2. Tried `golang:latest-alpine` - tag doesn't exist
3. Tried `golang:alpine` - works but may be too new
4. Settled on `golang:1.23-alpine` - latest stable, compatible with v0.14.2-beta

**Solution:**
```dockerfile
FROM golang:1.23-alpine AS builder
```

### Issue 2: Git Clone Strategy

**Problem:** Shallow clones cause version detection issues

**Attempts:**
1. `git clone --depth 1` - fails with "No names found"
2. `git clone --depth 1 --branch v0.18.0-beta` - tag may not exist
3. Full clone with tag checkout - works

**Solution:**
```dockerfile
RUN git clone https://github.com/ltcsuite/lnd.git && \
    cd lnd && \
    git fetch --tags && \
    LATEST_TAG=$(git tag -l 'v*beta*' | sort -V | tail -1) && \
    if [ -n "$LATEST_TAG" ]; then \
        git checkout $LATEST_TAG; \
    else \
        git checkout v0.14.2-beta; \
    fi
```

### Issue 3: Dependency Management

**Problem:** go.mod out of sync

**Solution:** Always run `go mod tidy` before building:
```dockerfile
WORKDIR /go/src/github.com/ltcsuite/lnd
RUN go mod tidy
RUN make install tags="signrpc walletrpc chainrpc invoicesrpc"
```

---

## Network Configuration Issues

### Issue 1: Host Networking vs Bridge Networking

**Problem:** LND needs to connect to Litecoin node running in another Docker container

**Attempt 1: Host Networking**
```yaml
network_mode: host
```
- **Pros:** Direct access to host ports
- **Cons:** Can't easily connect to other Docker containers
- **Result:** Failed - couldn't reach Litecoin container

**Attempt 2: Bridge Networking with External Network**
```yaml
networks:
  - node_bitcoin

networks:
  node_bitcoin:
    external: true
```
- **Pros:** Can connect to Litecoin container by name
- **Cons:** Requires Litecoin node to be on same network
- **Result:** ✅ Success - LND connects to `node-node-1` container

**Final Solution:**
```yaml
services:
  lnd:
    ports:
      - "9735:9735"
      - "10009:10009"
      - "8080:8080"
    networks:
      - node_bitcoin

networks:
  node_bitcoin:
    external: true
```

### Issue 2: Hostname Resolution

**Problem:** Finding correct hostname for Litecoin node

**Attempts:**
1. `host.docker.internal` - doesn't work for container-to-container
2. `localhost` / `127.0.0.1` - only works with host networking
3. Container IP `172.19.0.2` - works but not stable
4. Container name `node-node-1` - ✅ Best solution

**Final .env Configuration:**
```bash
LITECOIND_RPCHOST="node-node-1:19332"
LITECOIND_ZMQPUBRAWBLOCK=tcp://node-node-1:28333
LITECOIND_ZMQPUBRAWTX=tcp://node-node-1:28332
```

---

## Final Working Configuration

### Dockerfile
```dockerfile
FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git make gcc musl-dev

WORKDIR /go/src/github.com/ltcsuite
RUN git clone https://github.com/ltcsuite/lnd.git && \
    cd lnd && \
    git fetch --tags && \
    LATEST_TAG=$(git tag -l 'v*beta*' | sort -V | tail -1) && \
    if [ -n "$LATEST_TAG" ]; then \
        git checkout $LATEST_TAG; \
    else \
        git checkout v0.14.2-beta; \
    fi

WORKDIR /go/src/github.com/ltcsuite/lnd
RUN go mod tidy
RUN make install tags="signrpc walletrpc chainrpc invoicesrpc"

FROM alpine:3.19
RUN apk add --no-cache bash curl
COPY --from=builder /go/bin/lnd /usr/local/bin/
COPY --from=builder /go/bin/lncli /usr/local/bin/
RUN adduser -D -u 1000 lnd
RUN mkdir -p /home/lnd/.lnd && chown -R lnd:lnd /home/lnd
USER lnd
WORKDIR /home/lnd
EXPOSE 9735 10009 8080
ENTRYPOINT ["lnd"]
```

### docker-compose.yml
```yaml
services:
  lnd:
    build:
      context: ./lnd
      dockerfile: Dockerfile
    container_name: litecoin-lnd
    restart: unless-stopped
    ports:
      - "9735:9735"
      - "10009:10009"
      - "8080:8080"
    volumes:
      - lnd-data:/home/lnd/.lnd
      - ./lnd/lnd.conf:/home/lnd/.lnd/lnd.conf:ro
    command:
      - --configfile=/home/lnd/.lnd/lnd.conf
      - --litecoind.rpchost=${LITECOIND_RPCHOST}
      - --litecoind.rpcuser=${LITECOIND_RPCUSER}
      - --litecoind.rpcpass=${LITECOIND_RPCPASS}
      - --litecoind.zmqpubrawblock=${LITECOIND_ZMQPUBRAWBLOCK}
      - --litecoind.zmqpubrawtx=${LITECOIND_ZMQPUBRAWTX}
    networks:
      - node_bitcoin

volumes:
  lnd-data:
    driver: local

networks:
  node_bitcoin:
    external: true
```

### .env
```bash
LITECOIND_RPCHOST="node-node-1:19332"
LITECOIND_RPCUSER="bcn-admin"
LITECOIND_RPCPASS="your_password"
LITECOIND_ZMQPUBRAWBLOCK=tcp://node-node-1:28333
LITECOIND_ZMQPUBRAWTX=tcp://node-node-1:28332
```

---

## Verification Steps

After setup, verify everything works:

1. **Check LND is running:**
   ```bash
   docker compose logs lnd
   ```

2. **Verify ZMQ connection:**
   Look for these log messages:
   ```
   [INF] LNWL: Started listening for litecoind block notifications via ZMQ
   [INF] LNWL: Started listening for litecoind transaction notifications via ZMQ
   ```

3. **Check node status:**
   ```bash
   docker exec litecoin-lnd lncli --network=regtest --chain=litecoin getinfo
   ```

4. **Verify sync status:**
   ```bash
   docker exec litecoin-lnd lncli --network=regtest --chain=litecoin getinfo | grep synced
   ```

---

## Key Takeaways

1. **Always use ltcsuite/lnd for Litecoin** - not lightningnetwork/lnd
2. **Use tagged releases** - main branch has compatibility issues
3. **Match Go version to LND requirements** - Go 1.23 works with v0.14.2-beta
4. **Full git clone required** - shallow clones break version detection
5. **Run go mod tidy** - always sync dependencies before building
6. **Container networking** - connect LND to Litecoin node's Docker network
7. **Use container names** - more reliable than IPs for Docker networking
8. **ZMQ ports must match** - verify Litecoin node's ZMQ configuration matches LND's expectations

