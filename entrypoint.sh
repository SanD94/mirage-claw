#!/bin/bash
set -euo pipefail

require_env() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "$name is required" >&2
    exit 1
  fi
}

require_env OPENROUTER_API_KEY
require_env TELEGRAM_BOT_TOKEN
require_env TELEGRAM_ALLOW_FROM

mkdir -p /root/.nullclaw/workspace/skills

# NullClaw treats config values as literals, so provider keys and Telegram secrets
# must be rendered into the runtime config before startup.
jq -n --argjson allow_from "$TELEGRAM_ALLOW_FROM" '$allow_from' >/dev/null

jq \
  --arg openrouter_api_key "$OPENROUTER_API_KEY" \
  --arg telegram_bot_token "$TELEGRAM_BOT_TOKEN" \
  --argjson telegram_allow_from "$TELEGRAM_ALLOW_FROM" \
  --arg model "${NULLCLAW_MODEL:-openrouter/google/gemma-4-31b-it:free}" \
  --argjson port "${PORT:-3000}" \
  '
  .models.providers.openrouter.api_key = $openrouter_api_key
  | .agents.defaults.model.primary = $model
  | .channels.telegram.accounts.main.bot_token = $telegram_bot_token
  | .channels.telegram.accounts.main.allow_from = $telegram_allow_from
  | .gateway.port = $port
  ' \
  /etc/nullclaw/config.template.json > /root/.nullclaw/config.json

# Sync skills from image into the workspace so NullClaw discovers them.
cp -R /etc/nullclaw/skills/. /root/.nullclaw/workspace/skills/

exec nullclaw gateway
