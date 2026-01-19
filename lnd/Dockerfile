# LND Dockerfile for Litecoin Lightning Network
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make gcc musl-dev

# Set build arguments for LND version
# Using v0.17.5-beta - last version with Litecoin support
ARG LND_VERSION=v0.17.5-beta

# Clone and build LND with Litecoin + litecoind support
WORKDIR /go/src/github.com/lightningnetwork
RUN git clone https://github.com/lightningnetwork/lnd.git
WORKDIR /go/src/github.com/lightningnetwork/lnd
RUN git checkout ${LND_VERSION}
RUN make install tags="signrpc walletrpc chainrpc invoicesrpc"

# Final image
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache bash curl

# Copy LND binaries from builder
COPY --from=builder /go/bin/lnd /usr/local/bin/
COPY --from=builder /go/bin/lncli /usr/local/bin/

# Create lnd user and directories
RUN adduser -D -u 1000 lnd
RUN mkdir -p /home/lnd/.lnd && chown -R lnd:lnd /home/lnd

# Switch to lnd user
USER lnd
WORKDIR /home/lnd

# Expose LND ports
# 9735 - P2P Lightning Network
# 10009 - gRPC
# 8080 - REST API
EXPOSE 9735 10009 8080

# Default entrypoint
ENTRYPOINT ["lnd"]
