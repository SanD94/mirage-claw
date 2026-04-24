# Mirage Claw
Personal AI assistant running NullClaw + fizzy-cli on DigitalOcean.

## Environment variables

| Variable | Description |
|---|---|
| `OPENROUTER_API_KEY` | OpenRouter API key |
| `OPENCODE_API_KEY` | OpenCode API key |
| `FIZZY_TOKEN` | Fizzy personal access token |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token from BotFather |
| `TELEGRAM_ALLOW_FROM` | JSON array of allowed Telegram user IDs, e.g. `[123456789]` |
| `FIZZY_PROFILE` | Fizzy profile/account slug |
| `FIZZY_ACCOUNT` | Fallback for `FIZZY_PROFILE` |

## DigitalOcean deployment

The app runs as a single App Platform container with a persistent volume for NullClaw state.

## Updating versions

- NullClaw: bump `NULLCLAW_VERSION` in Dockerfile
- fizzy-cli: bump `FIZZY_CLI_VERSION` in Dockerfile