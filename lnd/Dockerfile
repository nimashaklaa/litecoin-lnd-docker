# LND Dockerfile for Litecoin Lightning Network
# Use Go 1.23 (latest stable) - ltcsuite/lnd main requires Go 1.24.2+, but 1.23 should work with older tags
FROM golang:1.23-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make gcc musl-dev

# Using ltcsuite/lnd - Litecoin's official LND fork
# Clone and build ltcsuite/lnd (Litecoin-compatible fork)
# Use v0.14.2-beta (latest stable release from ltcsuite/lnd)
WORKDIR /go/src/github.com/ltcsuite
RUN git clone https://github.com/ltcsuite/lnd.git && \
    cd lnd && \
    git fetch --tags && \
    # Use the latest available tag, or fallback to a known working version \
    LATEST_TAG=$(git tag -l 'v*beta*' | sort -V | tail -1) && \
    if [ -n "$LATEST_TAG" ]; then \
        echo "Checking out tag: $LATEST_TAG" && \
        git checkout $LATEST_TAG || git checkout v0.14.2-beta; \
    else \
        echo "Using fallback tag: v0.14.2-beta" && \
        git checkout v0.14.2-beta; \
    fi
WORKDIR /go/src/github.com/ltcsuite/lnd
# Update go.mod before building
RUN go mod tidy
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
