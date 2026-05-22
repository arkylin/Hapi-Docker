FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
COPY hapi-${TARGETARCH} /usr/local/bin/hapi
RUN chmod +x /usr/local/bin/hapi

RUN mkdir -p /root/.hapi

EXPOSE 3006

ENV HAPI_LISTEN_HOST=0.0.0.0
ENV HAPI_LISTEN_PORT=3006

ENTRYPOINT ["hapi"]
CMD ["hub"]
