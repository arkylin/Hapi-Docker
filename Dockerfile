FROM node:20-slim AS build

RUN npm install -g @twsxtd/hapi --registry=https://registry.npmjs.org

FROM node:20-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=build /usr/local/bin/hapi /usr/local/bin/hapi

RUN mkdir -p /root/.hapi

EXPOSE 3006

ENV HAPI_LISTEN_HOST=0.0.0.0
ENV HAPI_LISTEN_PORT=3006

ENTRYPOINT ["hapi"]
CMD ["hub"]
