FROM node:20-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @twsxtd/hapi --registry=https://registry.npmjs.org

RUN mkdir -p /root/.hapi

EXPOSE 3006

ENV HAPI_LISTEN_HOST=0.0.0.0
ENV HAPI_LISTEN_PORT=3006

ENTRYPOINT ["hapi"]
CMD ["hub"]
