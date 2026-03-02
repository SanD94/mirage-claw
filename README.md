# Mirage Claw
Personal AI assistant running NullClaw + fizzy-cli on Railway.

## How it works
- `config.json` is the NullClaw config, baked into the image at build time
- Entrypoint patches in Telegram secrets via `jq`, writes to `~/.nullclaw/config.json`
- API key is **not** in the config — NullClaw resolves `OPENROUTER_API_KEY` from env natively
- Fizzy uses env vars directly (`FIZZY_TOKEN`, `FIZZY_ACCOUNT`, etc.)

## Railway env vars

| Variable | Required | Description |
|---|---|---|
| `OPENROUTER_API_KEY` | ✅ | OpenRouter API key (resolved by NullClaw natively) |
| `TELEGRAM_BOT_TOKEN` | ✅ | Telegram bot token from BotFather |
| `TELEGRAM_ALLOW_FROM` | ✅ | JSON array of allowed Telegram user IDs, e.g. `[123456789]` |
| `FIZZY_TOKEN` | ✅ | Fizzy API token |
| `FIZZY_ACCOUNT` | ✅ | Fizzy account slug |
| `FIZZY_API_URL` | ❌ | Fizzy API URL (default: `https://app.fizzy.do`) |
| `FIZZY_BOARD` | ❌ | Default board ID |
| `NULLCLAW_MODEL` | ❌ | Override model (default: `openrouter/google/gemini-2.5-flash-lite`) |
| `PORT` | ❌ | Gateway port (default: `3000`) |

## Updating versions
- NullClaw: bump `NULLCLAW_VERSION` in Dockerfile
- fizzy-cli: bump `FIZZY_VERSION` in Dockerfile

## Changing config
- Structural changes: edit `config.json`, push, redeploy
- Secrets/model: update Railway env vars (service restarts automatically)
