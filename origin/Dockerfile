FROM oven/bun:1.3.14-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --depth 1 --branch main https://github.com/tiann/hapi.git .

RUN bun install
RUN bun run download:tunwg
RUN bun run build:web
RUN cd hub && bun run generate:embedded-web-assets

ARG TARGETARCH
RUN case "$TARGETARCH" in \
    amd64) \
        cd /build/cli && bun run build:exe:allinone --target bun-linux-x64-baseline && \
        cp dist-exe/bun-linux-x64-baseline/hapi /tmp/hapi \
        ;; \
    arm64) \
        cd /build/cli && bun run build:exe:allinone --target bun-linux-arm64 && \
        cp dist-exe/bun-linux-arm64/hapi /tmp/hapi \
        ;; \
    *) \
        echo "Unsupported architecture: $TARGETARCH" && exit 1 \
        ;; \
    esac

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/hapi /usr/local/bin/hapi
RUN chmod +x /usr/local/bin/hapi

RUN mkdir -p /root/.hapi

EXPOSE 3006

ENV HAPI_LISTEN_HOST=0.0.0.0
ENV HAPI_LISTEN_PORT=3006

ENTRYPOINT ["hapi"]
CMD ["hub"]
