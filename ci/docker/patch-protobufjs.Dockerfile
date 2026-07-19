# Patch transitive protobufjs for CVE-2026-41242 (CRITICAL).
# Used by currencyservice / paymentservice after ECR bootstrap pull.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
USER root
WORKDIR /usr/src/app
RUN apk add --no-cache npm \
  && npm install protobufjs@7.5.5 --omit=dev \
  && apk del npm
