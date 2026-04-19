# NullClaw Refresh Implementation Checklist

## Purpose

This checklist turns the upstream-first plan into concrete work against this repository.

The goal is to transform this repo from an aging wrapper into a thin, current deployment layer for:

- latest upstream NullClaw
- latest upstream `basecamp/fizzy-cli`
- Railway deployment
- Telegram as the only interface
- OpenRouter `nvidia/nemotron-3-super-120b-a12b:free`
- `/start` and `/end` session controls

## Current Repo Assessment

These files are the main places that need attention:

| File | Current role | Action |
|---|---|---|
| `README.md` | Documents old wrapper assumptions and env vars | Rewrite |
| `Dockerfile` | Pins older NullClaw and an outdated `fizzy-cli` source | Rewrite |
| `entrypoint.sh` | Renders the runtime config from env vars at startup | Keep aligned with the template flow |
| `config.template.json` | Repo-owned NullClaw config template | Keep aligned with current upstream schema |
| `skills/fizzy/SKILL.md` | Useful starting point, but should be reviewed against current `fizzy-cli` | Refresh |

## Guiding Rule

Prefer replacing stale wrapper logic over incrementally patching it.

If a file encodes old upstream assumptions, rewrite it from a fresh upstream model instead of preserving its structure.

## Local-First Testing Rule

Before deploying to Railway, prove the stack locally in this order:

1. NullClaw can reach your agent path.
2. Telegram can reach the local bot.
3. `/start` and `/end` manage sessions correctly.
4. the agent can control Fizzy through `fizzy-cli`.

Do not treat Railway as the place to discover first-time integration problems.

## Phase 0: Decide Packaging Strategy

- [x] Choose one packaging path for NullClaw:
  - [x] use the official upstream container image directly
  - [ ] or build a fresh wrapper image around the latest upstream binary
- [x] Keep `nullhub` out of the required production path for this Railway deployment
- [x] Treat git-tracked config plus env-based rendering as the source of truth instead of UI-managed live config
- [x] Choose one packaging path for `fizzy-cli`:
  - [x] install from current `basecamp/fizzy-cli` release assets
  - [x] avoid the old non-upstream release source currently referenced in `Dockerfile`
- [x] Pin explicit versions for both NullClaw and `fizzy-cli`
- [x] Record those version choices in the repo docs

## Phase 1: Rewrite Container Setup

### `Dockerfile`

- [ ] Remove the old `NULLCLAW_VERSION=2026.2.26` assumption unless intentionally pinning that exact release
- [ ] Remove the outdated `robzolkos/fizzy-cli` download source
- [ ] Install current upstream `basecamp/fizzy-cli`
- [ ] Keep the image minimal and suitable for Railway
- [ ] Ensure required runtime tools exist only if truly needed, such as `curl` or `jq`
- [ ] Expose the app port used by Railway health checks

### `entrypoint.sh`

- [ ] Stop treating the image-baked template as the authoritative runtime config
- [ ] Generate or render a fresh runtime config from current schema
- [ ] Generate config from repo-owned templates or files, not `nullhub`-managed instance state
- [ ] Inject Telegram and OpenRouter settings in a way that matches current NullClaw behavior
- [ ] Inject Fizzy env vars in a way that matches current `fizzy-cli` behavior
- [ ] Keep the startup logic minimal: render config, copy skill files if needed, start NullClaw
- [ ] Ensure the script works cleanly with a persistent volume mounted for NullClaw state

## Phase 2: Replace The NullClaw Config

### `config.template.json`

- [x] Replace the existing file with a fresh config based on current upstream structure
- [x] Use upstream docs/schema as the reference, not `nullhub`'s mutable UI state
- [x] Set the default model to `openrouter/nvidia/nemotron-3-super-120b-a12b:free`
- [x] Configure only the Telegram channel
- [x] Lock Telegram usage to your allowed user ID
- [x] Keep memory local and simple for the MVP
- [x] Keep autonomy conservative enough to avoid unrelated tool use
- [x] Set `block_high_risk_commands: true` for security
- [x] Set `allowed_commands: ["fizzy"]` to only allow fizzy through
- [x] Remove unneeded capabilities that are irrelevant to the MVP
- [x] Verify the config does not rely on unsupported env interpolation rules

### Session behavior

- [ ] Confirm whether current upstream already handles `/start` the way you need
- [ ] Confirm whether `/new`, `/stop`, or `/abort` can serve as the basis for `/end`
- [ ] If not, add the thinnest possible `/end` integration
- [ ] Ensure `/end` causes the next user message to start from fresh context

## Phase 3: Refresh The Fizzy Skill Layer

### `skills/fizzy/SKILL.md`

- [ ] Review all documented commands against the current `basecamp/fizzy-cli` surface
- [ ] Remove any stale commands or output assumptions
- [ ] Add explicit instructions to prefer `fizzy-cli` for all Fizzy actions
- [ ] Add explicit instructions to summarize results for Telegram instead of dumping raw JSON
- [ ] Add explicit guidance for ambiguous board or card names
- [ ] Add explicit guidance for destructive actions

### Skill packaging

- [ ] Decide whether to keep the current local skill structure or adopt the current upstream preferred manifest layout
- [ ] Ensure the runtime actually loads the Fizzy skill from the expected directory
- [ ] Ensure the skill survives redeploys via image copy or persistent volume sync

## Phase 4: Local Validation

### NullClaw to agent

- [x] Start NullClaw locally with the current config shape
- [x] Confirm a plain local prompt gets a normal reply
- [x] Confirm the selected OpenRouter model path works
- [x] Confirm there are no auth or config errors before Telegram is introduced

### Telegram connection

- [ ] Start the bot locally with `TELEGRAM_BOT_TOKEN` and `TELEGRAM_ALLOW_FROM`
- [ ] Confirm the allowed Telegram user can reach the bot
- [ ] Confirm a plain Telegram message gets a normal reply
- [ ] Confirm the logs show no Telegram channel setup errors

### Session controls

- [ ] Confirm `/start` opens or reactivates a usable session
- [ ] Confirm `/start` frames the bot as a Fizzy assistant
- [ ] Confirm `/end` clears the active conversational context
- [ ] Confirm a fresh message after `/end` behaves like a new session

### Fizzy control

- [x] Confirm `fizzy-cli` auth works locally
- [x] Confirm asking for boards returns a useful reply
- [x] Confirm asking for cards on a board returns a useful reply
- [ ] Confirm creating a card works
- [ ] Confirm moving a card works
- [ ] Confirm adding a comment works
- [ ] Confirm replies stay concise instead of dumping raw CLI output

## Phase 5: Railway Environment Contract

### Docs and env vars

- [x] Rewrite `README.md` to describe the refreshed runtime, not the old wrapper
- [x] Copy `.fizzy.yaml` to nullclaw workspace for token access
- [ ] Document all required env vars clearly:
  - [x] `OPENROUTER_API_KEY`
  - [x] `TELEGRAM_BOT_TOKEN`
  - [x] `TELEGRAM_ALLOW_FROM`
  - [x] `FIZZY_PROFILE` (optional, for config template)
- [ ] Document Railway volume requirements
- [ ] Document the single-replica requirement for the MVP

### Fizzy Token Setup (jj)

NullClaw reads `.fizzy.yaml` from its workspace directory to authenticate with Fizzy. The token must be present in the workspace, not as an environment variable.

- [x] Create `.fizzy.yaml` in nullclaw workspace (`~/.nullclaw/workspace/.fizzy.yaml`)
- [x] The file should contain:
  ```yaml
  token: <your-fizzy-token>
  account: "<your-account-id>"
  api_url: https://app.fizzy.do
  board: ""
  ```
- [x] Ensure the workspace has read access to this file

### Runtime behavior on Railway

- [ ] Ensure the app binds to Railway's assigned port
- [ ] Ensure the process can restart cleanly without losing persistent state
- [ ] Ensure the health check path is stable
- [ ] Ensure config rendering does not fail when optional env vars are missing

## Phase 6: End-To-End Validation

### Boot validation

- [ ] NullClaw starts successfully on Railway after local validation already passed
- [ ] Telegram channel comes up successfully on Railway
- [ ] OpenRouter auth works on Railway
- [ ] `fizzy-cli` auth works on Railway

### Conversation validation

- [ ] `/start` opens a usable Fizzy-focused session on Railway
- [ ] asking for boards returns a useful reply on Railway
- [ ] asking for cards on a board returns a useful reply on Railway
- [ ] creating a card works on Railway
- [ ] moving a card works on Railway
- [ ] adding a comment works on Railway
- [ ] `/end` clears the session on Railway
- [ ] a new free-text message after `/end` behaves like a fresh chat on Railway

## Suggested Execution Order

1. Rewrite `Dockerfile`.
2. Rewrite `entrypoint.sh`.
3. Replace `config.template.json`.
4. Refresh `skills/fizzy/SKILL.md`.
5. Confirm NullClaw can reach the agent locally.
6. Confirm Telegram reaches the local bot.
7. Confirm `/start` and `/end` behave correctly.
8. Confirm the agent can control Fizzy locally.
9. Rewrite `README.md`.
10. Deploy to Railway.
11. Re-run the same smoke tests on Railway and then run the BDD scenarios from `docs/nullclaw-bdd.md`.

## BDD Tests Created

### Test Files

- [x] `tests/features/nullclaw_agent_fizzy.feature` - Gherkin feature file with BDD scenarios
- [x] `tests/run_bdd.sh` - BDD test runner for nullclaw agent and fizzy integration

### Test Coverage

- [x] Security: `block_high_risk_commands: true` is enabled
- [x] Security: `allowed_commands: ["fizzy"]` blocks non-fizzy commands
- [x] Board operations: `fizzy board list` returns boards
- [x] Agent uses nemotron model for tool calling

### Test Results (Local)

```
✓ PASS: nullclaw is available
✓ PASS: fizzy is available
✓ PASS: Security block is enabled
✓ PASS: fizzy is in allowed_commands
✓ PASS: fizzy board list executes successfully
✓ PASS: Board list returned successfully

Test Results: 6 passed, 0 failed
```

## Definition Of Complete

This checklist is complete when:

- the repo is no longer coupled to stale NullClaw assumptions
- the local test ladder has been completed before Railway deployment
- the deployment uses current upstream NullClaw and current upstream `fizzy-cli`
- the bot works through Telegram for the core Fizzy use cases
- `/start` and `/end` behave as intended
- the Railway deployment can be re-created from the docs in this repo
