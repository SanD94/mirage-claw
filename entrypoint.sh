#!/bin/bash
set -e

# Write NullClaw config if it doesn't exist yet
mkdir -p /root/.nullclaw
if [ ! -f /root/.nullclaw/config.json ]; then
  cat > /root/.nullclaw/config.json << 'EOF'
{
  "models": {
    "providers": {
      "openrouter": { "api_key": "${NULLCLAW_API_KEY}" }
    }
  },

  "agents": {
    "defaults": {
      "model": { "primary": "openrouter/google/gemma-3-4b-it" },
      "heartbeat": { "every": "30m" }
    }
  },

  "channels": {
    "telegram": {
      "accounts": {
        "main": {
          "bot_token": "${NULLCLAW_TELEGRAM_TOKEN}",
          "allow_from": ["${NULLCLAW_TELEGRAM_ALLOWLIST}"],
          "reply_in_private": true
        }
      }
    }
  },

  "memory": {
    "backend": "sqlite",
    "auto_save": true
  },

  "gateway": {
    "port": 3000,
    "host": "0.0.0.0",
    "require_pairing": false,
    "allow_public_bind": true
  },

  "autonomy": {
    "level": "supervised",
    "workspace_only": true,
    "max_actions_per_hour": 20
  },

  "security": {
    "sandbox": { "backend": "auto" },
    "audit": { "enabled": true }
  },

  "hooks": {
    "before_llm": [
      {
        "match": "^/fizzy (.+)",
        "run": "fizzy $1 --format json",
        "inject_as": "system",
        "label": "Fizzy context"
      }
    ]
  },

  "schedule": [
    {
      "cron": "0 8 * * *",
      "channel": "telegram",
      "new_session": true,
      "shell": "fizzy card list --all --format json",
      "prompt": "Good morning! Here is today's Fizzy board data. Give me a brief, friendly summary: what's in progress, anything that looks stalled, and 2-3 suggested priorities for today."
    }
  ],

  "system_prompt": "You are a personal productivity assistant. The user manages their work using Fizzy kanban boards. Be concise and actionable."
}
EOF
fi

mkdir -p /root/.fizzy
cat > /root/.fizzy/config.yaml << EOF
token: "${FIZZY_TOKEN}"
account: "${FIZZY_ACCOUNT}"
api_url: "${FIZZY_API_URL:-https://app.fizzy.do}"
EOF

# Start NullClaw
exec nullclaw gateway --host 0.0.0.0 --port 3000
