FROM alpine:3.23

# Versions — bump these to update
ARG NULLCLAW_VERSION=2026.2.26
ARG FIZZY_CLI_VERSION=3.0.1

# Install dependencies
RUN apk add --no-cache curl ca-certificates bash

# Install NullClaw
RUN curl -fsSL \
    "https://github.com/nullclaw/nullclaw/releases/download/v${NULLCLAW_VERSION}/nullclaw-linux-x86_64.bin" \
    -o /usr/local/bin/nullclaw \
  && chmod +x /usr/local/bin/nullclaw

# Install fizzy-cli
RUN curl -fsSL \
    "https://github.com/robzolkos/fizzy-cli/releases/download/v${FIZZY_CLI_VERSION}/fizzy-linux-amd64" \
    -o /usr/local/bin/fizzy \
  && chmod +x /usr/local/bin/fizzy

# runtime
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
