#!/bin/bash
set -e

# Write NullClaw config if it doesn't exist yet
mkdir -p /root/.nullclaw
if [ ! -f /root/.nullclaw/config.json ]; then
  cat > /root/.nullclaw/config.json << 'EOF'
{
  "provider": "openrouter",
  "model": "google/gemma-3-4b-it",

  "session": {
    "strategy": "daily",
    "id_format": "uuidv6",
    "title": {
      "auto_generate": true,
      "prompt": "In 5 words or fewer, summarize what this conversation was about. Use plain language, no punctuation.",
      "trigger": "on_session_end"
    }
  },

  "tools": { "shell": true },

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
exec nullclaw gateway --port 8080
