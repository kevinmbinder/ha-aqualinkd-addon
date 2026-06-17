ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base-debian:bookworm
ARG AQUALINKD_VERSION=v2.3.6

# ── Stage 1: compile AqualinkD from source ────────────────────────────────────
FROM debian:bookworm AS builder
ARG AQUALINKD_VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl make gcc && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN curl -fsSL \
    "https://github.com/aqualinkd/AqualinkD/archive/refs/tags/${AQUALINKD_VERSION}.tar.gz" \
    | tar xz --strip-components=1

# AQ_MANAGER=false removes the -lsystemd linkage that requires a running
# systemd journal socket — not present in a Home Assistant add-on container.
# Core functionality (RS-485 → MQTT, web UI, scheduling) is unaffected.
RUN make clean && make AQ_MANAGER=false container

# ── Stage 2: runtime image ────────────────────────────────────────────────────
FROM ${BUILD_FROM}

RUN apt-get update && \
    apt-get install -y --no-install-recommends cron socat && \
    # Allow cron.d drop-in files (the -l flag)
    sed -i 's/^#\(EXTRA_OPTS="-l"\)/\1/' /etc/default/cron && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/release/aqualinkd /usr/local/bin/aqualinkd
COPY --from=builder /build/web/              /var/www/aqualinkd/
COPY --from=builder /build/release/aqualinkd.conf /etc/aqualinkd.conf.defaults

COPY run.sh /run.sh
# Normalise line endings (safe even on Windows-built sources) and make executable
RUN sed -i 's/\r$//' /run.sh && chmod a+x /run.sh

CMD ["/run.sh"]
