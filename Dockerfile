FROM debian:bookworm-slim

# Versions — bump these to update
ARG NULLCLAW_VERSION=2026.2.26
ARG FIZZY_CLI_VERSION=3.0.1

# Install curl to grab the release
RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*

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

COPY config.json /etc/nullclaw/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000
ENTRYPOINT ["/entrypoint.sh"]
