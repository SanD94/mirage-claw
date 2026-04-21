#!/bin/bash
set -euo pipefail

require_env() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "$name is required" >&2
    exit 1
  fi
}

resolve_fizzy_profile() {
  if [ -n "${FIZZY_PROFILE:-}" ]; then
    printf '%s' "$FIZZY_PROFILE"
    return
  fi

  if [ -n "${FIZZY_ACCOUNT:-}" ]; then
    printf '%s' "$FIZZY_ACCOUNT"
    return
  fi

  echo "FIZZY_PROFILE or FIZZY_ACCOUNT is required" >&2
  exit 1
}

write_fizzy_config() {
  local path="$1"

  cat > "$path" <<EOF
token: "$FIZZY_TOKEN"
account: "$fizzy_profile"
api_url: "$fizzy_api_url"
board: "$fizzy_board"
EOF

  chmod 600 "$path"
}

require_env OPENROUTER_API_KEY
require_env FIZZY_TOKEN
require_env TELEGRAM_BOT_TOKEN
require_env TELEGRAM_ALLOW_FROM

fizzy_profile="$(resolve_fizzy_profile)"
fizzy_api_url="${FIZZY_API_URL:-https://app.fizzy.do}"
fizzy_board="${FIZZY_BOARD:-}"

mkdir -p /root/.nullclaw/workspace/skills /root/.config/fizzy

write_fizzy_config /root/.nullclaw/workspace/.fizzy.yaml
write_fizzy_config /root/.config/fizzy/config.yaml

jq -n --argjson allow_from "$TELEGRAM_ALLOW_FROM" '$allow_from' >/dev/null

jq \
  --arg openrouter_api_key "$OPENROUTER_API_KEY" \
  --arg fizzy_token "$FIZZY_TOKEN" \
  --arg fizzy_profile "$fizzy_profile" \
  --arg telegram_bot_token "$TELEGRAM_BOT_TOKEN" \
  --argjson telegram_allow_from "$TELEGRAM_ALLOW_FROM" \
  --arg model "${NULLCLAW_MODEL:-openrouter/nvidia/nemotron-3-super-120b-a12b:free}" \
  --arg port "${NULLCLAW_GATEWAY_PORT:-${PORT:-3000}}" \
  --arg host "${NULLCLAW_GATEWAY_HOST:-0.0.0.0}" \
  --argjson require_pairing "${NULLCLAW_REQUIRE_PAIRING:-true}" \
  '
  .models.providers.openrouter.api_key = $openrouter_api_key
  | .models.providers.openrouter.env.FIZZY_TOKEN = $fizzy_token
  | .models.providers.openrouter.env.FIZZY_PROFILE = $fizzy_profile
  | .models.providers.openrouter.env.FIZZY_ACCOUNT = $fizzy_profile
  | .runtime.env.FIZZY_TOKEN = $fizzy_token
  | .runtime.env.FIZZY_PROFILE = $fizzy_profile
  | .runtime.env.FIZZY_ACCOUNT = $fizzy_profile
  | .agents.defaults.model.primary = $model
  | .channels.telegram.accounts.default.bot_token = $telegram_bot_token
  | .channels.telegram.accounts.default.allow_from = $telegram_allow_from
  | .gateway.port = ($port | tonumber)
  | .gateway.host = $host
  | .gateway.require_pairing = $require_pairing
  ' \
  /etc/nullclaw/config.template.json > /root/.nullclaw/config.json

cp -R /etc/nullclaw/skills/. /root/.nullclaw/workspace/skills/

exec nullclaw gateway
