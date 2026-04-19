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

jq -n --argjson allow_from "$TELEGRAM_ALLOW_FROM" '$allow_from' >/dev/null

jq \
  --arg openrouter_api_key "$OPENROUTER_API_KEY" \
  --arg fizzy_token "$FIZZY_TOKEN" \
  --arg telegram_bot_token "$TELEGRAM_BOT_TOKEN" \
  --argjson telegram_allow_from "$TELEGRAM_ALLOW_FROM" \
  --arg model "${NULLCLAW_MODEL:-openrouter/nvidia/nemotron-3-super-120b-a12b:free}" \
  --argjson port "${PORT:-3000}" \
  --argjson require_pairing "${NULLCLAW_REQUIRE_PAIRING:-true}" \
  '
  .models.providers.openrouter.api_key = $openrouter_api_key
  | .models.providers.openrouter.env.FIZZY_TOKEN = $fizzy_token
  | .runtime.env.FIZZY_TOKEN = $fizzy_token
  | .agents.defaults.model.primary = $model
  | .channels.telegram.accounts.default.bot_token = $telegram_bot_token
  | .channels.telegram.accounts.default.allow_from = $telegram_allow_from
  | .gateway.port = $port
  | .gateway.require_pairing = $require_pairing
  ' \
  /etc/nullclaw/config.template.json > /root/.nullclaw/config.json

cp -R /etc/nullclaw/skills/. /root/.nullclaw/workspace/skills/

exec nullclaw gateway