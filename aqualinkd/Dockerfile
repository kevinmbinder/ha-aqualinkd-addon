ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base-debian:bookworm
ARG AQUALINKD_VERSION=v2.3.6

# ── Stage 1: compile AqualinkD from source ────────────────────────────────────
FROM debian:bookworm AS builder
ARG AQUALINKD_VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl make gcc libc6-dev libsystemd-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN curl -fsSL \
    "https://github.com/aqualinkd/AqualinkD/archive/refs/tags/${AQUALINKD_VERSION}.tar.gz" \
    | tar xz --strip-components=1

# Build with default AQ_MANAGER=true so MQTT discovery and all config
# parameters are available. libsystemd is present at runtime in the HA base
# image; the journal socket simply won't exist so logging falls back to stderr.
ARG CACHE_BUST=20260617
RUN make clean && make AQ_CONTAINER=true AQ_MANAGER=true

# ── Stage 2: runtime image ────────────────────────────────────────────────────
FROM ${BUILD_FROM}

RUN apt-get update && \
    apt-get install -y --no-install-recommends cron socat libsystemd0 && \
    sed -i 's/^#\(EXTRA_OPTS="-l"\)/\1/' /etc/default/cron && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/release/aqualinkd /usr/local/bin/aqualinkd
COPY --from=builder /build/web/              /var/www/aqualinkd/

COPY run.sh /run.sh
RUN sed -i 's/\r$//' /run.sh && chmod a+x /run.sh

CMD ["/run.sh"]
