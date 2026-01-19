# Build stage - compile LND from source
FROM golang:1.23-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make gcc musl-dev

# Clone ltcsuite/lnd (Litecoin's official LND fork)
WORKDIR /go/src/github.com/ltcsuite
RUN git clone https://github.com/ltcsuite/lnd.git && \
    cd lnd && \
    git fetch --tags && \
    # Find latest beta tag, fallback to v0.14.2-beta if none found \
    LATEST_TAG=$(git tag -l 'v*beta*' | sort -V | tail -1) && \
    if [ -n "$LATEST_TAG" ]; then \
        echo "Checking out tag: $LATEST_TAG" && \
        git checkout $LATEST_TAG || git checkout v0.14.2-beta; \
    else \
        echo "Using fallback tag: v0.14.2-beta" && \
        git checkout v0.14.2-beta; \
    fi

# Build LND with required RPC tags
WORKDIR /go/src/github.com/ltcsuite/lnd
RUN go mod tidy
RUN make install tags="signrpc walletrpc chainrpc invoicesrpc"

# Runtime stage - minimal Alpine image
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache bash curl

# Copy compiled binaries from builder
COPY --from=builder /go/bin/lnd /usr/local/bin/
COPY --from=builder /go/bin/lncli /usr/local/bin/

# Create non-root user for security
RUN adduser -D -u 1000 lnd
RUN mkdir -p /home/lnd/.lnd && chown -R lnd:lnd /home/lnd

# Switch to non-root user
USER lnd
WORKDIR /home/lnd

# Expose LND ports: 9735 (P2P), 10009 (gRPC), 8080 (REST)
EXPOSE 9735 10009 8080

ENTRYPOINT ["lnd"]
