# Mirage Claw
Personal AI assistant running NullClaw + fizzy-cli on Railway.

## How it works
- `config.template.json` is the repo-owned NullClaw config template
- Entrypoint renders `~/.nullclaw/config.json` from that template on every boot
- `OPENROUTER_API_KEY`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOW_FROM`, and optional `NULLCLAW_MODEL` are injected during render
- Entrypoint writes Fizzy auth config to `~/.nullclaw/workspace/.fizzy.yaml` and `~/.config/fizzy/config.yaml`
- Fizzy auth is sourced from `FIZZY_TOKEN` plus `FIZZY_PROFILE` or `FIZZY_ACCOUNT`

## Fizzy Auth Setup

Set these Railway variables and the entrypoint will write the required Fizzy config files at boot:

```yaml
token: <your-fizzy-token>
account: "<your-fizzy-profile-or-account-slug>"
api_url: https://app.fizzy.do
board: ""
```

## Railway env vars

| Variable | Required | Description |
|---|---|---|
| `OPENROUTER_API_KEY` | ✅ | OpenRouter API key rendered into the runtime NullClaw config |
| `FIZZY_TOKEN` | ✅ | Fizzy personal access token written into the runtime Fizzy config files |
| `FIZZY_PROFILE` | ✅* | Preferred Fizzy profile/account slug written into the runtime Fizzy config files |
| `FIZZY_ACCOUNT` | ✅* | Backward-compatible fallback for `FIZZY_PROFILE` |
| `TELEGRAM_BOT_TOKEN` | ✅ | Telegram bot token from BotFather |
| `TELEGRAM_ALLOW_FROM` | ✅ | JSON array of allowed Telegram user IDs, e.g. `[123456789]` |
| `FIZZY_API_URL` | ❌ | Override Fizzy API URL (default: `https://app.fizzy.do`) |
| `FIZZY_BOARD` | ❌ | Default Fizzy board to include in generated config |
| `NULLCLAW_MODEL` | ❌ | Override model (default: `openrouter/nvidia/nemotron-3-super-120b-a12b:free`) |
| `PORT` | ❌ | Gateway port used when `NULLCLAW_GATEWAY_PORT` is not set; Railway typically injects `8080` |
| `NULLCLAW_GATEWAY_PORT` | ❌ | Explicit NullClaw gateway port override |

`*` Set either `FIZZY_PROFILE` or `FIZZY_ACCOUNT`.

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
