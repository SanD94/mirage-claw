# Mirage Claw
Personal AI assistant running NullClaw + fizzy-cli on Railway.

## How it works
- `config.template.json` is the repo-owned NullClaw config template
- Entrypoint renders `~/.nullclaw/config.json` from that template on every boot
- `OPENROUTER_API_KEY`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOW_FROM`, and optional `NULLCLAW_MODEL` are injected during render
- Fizzy uses env vars directly such as `FIZZY_TOKEN`, `FIZZY_PROFILE`, and `FIZZY_API_URL`

## Railway env vars

| Variable | Required | Description |
|---|---|---|
| `OPENROUTER_API_KEY` | ✅ | OpenRouter API key rendered into the runtime NullClaw config |
| `TELEGRAM_BOT_TOKEN` | ✅ | Telegram bot token from BotFather |
| `TELEGRAM_ALLOW_FROM` | ✅ | JSON array of allowed Telegram user IDs, e.g. `[123456789]` |
| `FIZZY_TOKEN` | ✅ | Fizzy API token |
| `FIZZY_PROFILE` | ✅ | Fizzy profile or account slug |
| `FIZZY_API_URL` | ❌ | Fizzy API URL (default: `https://app.fizzy.do`) |
| `FIZZY_BOARD` | ❌ | Default board ID |
| `FIZZY_NO_KEYRING` | ✅ | Set to `1` in Railway or other headless environments |
| `NULLCLAW_MODEL` | ❌ | Override model (default: `openrouter/google/gemma-4-31b-it:free`) |
| `PORT` | ❌ | Gateway port (default: `3000`) |

## Updating versions
- NullClaw: bump `NULLCLAW_VERSION` in Dockerfile
- fizzy-cli: bump `FIZZY_CLI_VERSION` in Dockerfile

## Refreshing the config template

When upstream NullClaw changes its config schema, regenerate a fresh baseline locally:

```bash
nullclaw onboard --interactive
```

Then copy the generated `~/.nullclaw/config.json` into `config.template.json`, remove live secrets, trim it down to the Telegram + Fizzy deployment shape you want, and commit the sanitized template.

## Changing config
- Structural changes: edit `config.template.json`, push, redeploy
- Secrets/model: update Railway env vars (service restarts automatically)
