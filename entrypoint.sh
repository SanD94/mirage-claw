#!/bin/bash
set -e

mkdir -p /root/.nullclaw/workspace/skills

# Patch telegram secrets and optional model override into the baked config.
# API key is NOT in the config — NullClaw resolves OPENROUTER_API_KEY from env natively.
jq_filter='.channels.telegram.accounts.default.bot_token = $token
  | .channels.telegram.accounts.default.allow_from = $allow'
jq_args=(--arg token "$TELEGRAM_BOT_TOKEN" --argjson allow "${TELEGRAM_ALLOW_FROM:-[]}")

if [ -n "$NULLCLAW_MODEL" ]; then
  jq_filter="$jq_filter | .agents.defaults.model.primary = \$model"
  jq_args+=(--arg model "$NULLCLAW_MODEL")
fi

jq "${jq_args[@]}" "$jq_filter" /etc/nullclaw/config.json > /root/.nullclaw/config.json

# Sync skills from image into the volume so NullClaw discovers them
cp -r /etc/nullclaw/skills/* /root/.nullclaw/workspace/skills/

exec nullclaw gateway --host 0.0.0.0 --port "${PORT:-3000}"
