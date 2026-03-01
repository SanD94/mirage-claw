#!/bin/bash
set -e

# Write fizzy config
mkdir -p /root/.fizzy
cat > /root/.fizzy/config.yaml << EOF
token: "${FIZZY_TOKEN}"
account: "${FIZZY_ACCOUNT}"
api_url: "${FIZZY_API_URL:-https://app.fizzy.do}"
EOF

# Start Telegram channel
nullclaw channel start telegram &

# Start gateway
exec nullclaw gateway --host 0.0.0.0 --port "${PORT:-3000}"

