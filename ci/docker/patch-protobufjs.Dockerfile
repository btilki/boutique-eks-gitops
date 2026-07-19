# Force every nested protobufjs copy to 7.5.5 (CVE-2026-41242).
# Top-level npm install alone leaves vulnerable nested copies (e.g. under otel).
# Build with: --build-arg BASE_IMAGE=<ecr-image>
ARG BASE_IMAGE=busybox:1.36
FROM ${BASE_IMAGE}
USER root
WORKDIR /usr/src/app
RUN apk add --no-cache npm \
  && mkdir -p /tmp/pb \
  && cd /tmp/pb \
  && npm pack protobufjs@7.5.5 \
  && tar -xzf protobufjs-7.5.5.tgz \
  && find /usr/src/app/node_modules -type d -name protobufjs | while read -r d; do \
       rm -rf "$d"; \
       mkdir -p "$d"; \
       cp -a /tmp/pb/package/. "$d/"; \
     done \
  && find /usr/src/app/node_modules -path '*/protobufjs/package.json' -print \
  && find /usr/src/app/node_modules -path '*/protobufjs/package.json' -exec \
       node -e 'const p=require(process.argv[1]); if (p.version!=="7.5.5") { console.error("BAD", process.argv[1], p.version); process.exit(1);} console.log("OK", process.argv[1]);' {} \; \
  && rm -rf /tmp/pb \
  && apk del npm
