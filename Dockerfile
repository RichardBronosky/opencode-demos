# syntax=docker/dockerfile:1
#FROM ubuntu:24.04
FROM ubuntu:24.04@sha256:84e77dee7d1bc93fb029a45e3c6cb9d8aa4831ccfcc7103d36e876938d28895b

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && \
    apt-get install -y -qq curl ca-certificates tmux && \
    rm -rf /var/lib/apt/lists/*

# Zscaler root CA — only needed on Zscaler networks.
# Pass --build-arg ZSCALER_CERT_B64="$(base64 -w0 /path/to/cert.pem)" to inject it.
# The default is empty; the RUN step is a no-op in the common case.
ARG ZSCALER_CERT_B64=
RUN if [ -n "$ZSCALER_CERT_B64" ]; then \
      echo "=== Installing Zscaler root CA ===" && \
      echo "$ZSCALER_CERT_B64" | base64 -d > /usr/local/share/ca-certificates/zscaler-root-ca.crt && \
      update-ca-certificates --fresh; \
    fi

ARG HOST_UID=1000
# ubuntu:24.04 ships with a user at uid 1000 — rename it to 'oc', or create fresh if uid differs.
RUN if getent passwd "${HOST_UID}" > /dev/null; then \
      usermod -l oc -d /home/oc -m "$(getent passwd "${HOST_UID}" | cut -d: -f1)"; \
    else \
      useradd -m -u "${HOST_UID}" -s /bin/bash oc; \
    fi

USER oc
RUN curl -fsSL https://opencode.ai/install | bash

ENV PATH="/home/oc/.opencode/bin:$PATH"

ENTRYPOINT ["opencode"]
