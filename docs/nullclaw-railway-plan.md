# NullClaw + Telegram + Fizzy on Railway Plan

## Premise

This repository should not be treated as the source of truth for NullClaw integration details.

NullClaw is moving quickly, so the plan should be based on current upstream NullClaw and current upstream `fizzy-cli`, then adapted into this repo as a thin deployment wrapper only if needed.

That means the first goal is not "patch the old wrapper until it works".
The first goal is "refresh the wrapper around the latest upstream runtime and current config model".

## Goal

Deploy a Railway-hosted bot that:

- uses current upstream NullClaw
- uses Telegram as the only user interface
- uses OpenRouter model `google/gemma-4-31b-it:free`
- uses current `fizzy-cli` as the main integration surface to Fizzy
- replies in short Telegram-friendly messages
- supports `/start` and `/end` as the only session-management commands you care about

## Local-First Testing Order

Because you can validate everything locally before touching Railway, the working plan should follow this order:

1. prove that NullClaw can connect to your local agent setup at all
2. prove that Telegram can reach the local bot cleanly
3. prove that `/start` and `/end` behave the way you want for session control
4. prove that the agent can control Fizzy through `fizzy-cli`
5. only then package the result for Railway

This keeps the highest-risk unknowns isolated.

- if NullClaw cannot talk to the agent locally, deployment work is premature
- if Telegram is not wired correctly, `/start` and `/end` are impossible to judge
- if session control is wrong, Fizzy testing will produce confusing results
- if Fizzy control fails locally, Railway will only add more variables to debug

## High-Level Architecture

1. Telegram user sends a message.
2. NullClaw receives it through its Telegram channel.
3. NullClaw calls OpenRouter with `openrouter/google/gemma-4-31b-it:free`.
4. When it needs to inspect or mutate Fizzy state, it uses `fizzy-cli`.
5. NullClaw summarizes the result into a Telegram reply.
6. Railway runs one long-lived container plus a persistent volume for NullClaw state.

## Main Design Decision

Use the latest upstream NullClaw runtime and latest upstream `fizzy-cli` first.

Do not start by extending the current local `Dockerfile`, `entrypoint.sh`, or `config.template.json` unless they are deliberately rewritten to match current upstream behavior.

That avoids three problems:

- stale config keys that no longer match current NullClaw
- stale packaging choices when upstream already ships a better deployment path
- stale skills or command assumptions that fight newer NullClaw behavior

## Recommended Implementation Strategy

Build the deployment in two layers.

### Layer 1: Upstream Runtime

This layer should come almost entirely from upstream projects:

- latest NullClaw release or official container image
- latest `fizzy-cli` release from `basecamp/fizzy-cli`
- latest NullClaw config structure
- latest NullClaw skill/workspace conventions

### Layer 2: Thin Project-Specific Customization

This repo should contain only the minimum custom pieces:

- Railway deployment wiring
- your repo-owned `config.template.json`
- your rendered runtime `config.json`
- your Fizzy-focused skill or workspace prompt
- the minimal `/end` behavior if upstream does not already expose it the way you want

## Phase 0: Refresh The Baseline

Before implementing features, align the project with upstream.

Work items:

1. Decide whether to use the official NullClaw image directly or rebuild a fresh wrapper image around the latest NullClaw binary.
2. Replace the old pinned `fizzy-cli` source with the current upstream `basecamp/fizzy-cli` release flow.
3. Regenerate the NullClaw config from current upstream docs instead of editing the old local config in place.
4. Treat existing local wrapper files as disposable scaffolding unless they clearly match upstream.

Preferred outcome:

- this repo becomes a thin deployment repo, not a forked NullClaw distribution

## Phase 1: Refresh The Local Runtime Baseline

Before testing behavior, make the local runtime look like the intended production runtime as closely as possible.

Work items:

1. Install the latest upstream NullClaw locally.
2. Install the latest upstream `basecamp/fizzy-cli` locally.
3. Run `nullclaw onboard --interactive` locally and use that output to shape `config.template.json`.
4. Keep local secrets in env vars or an uncommitted local config, not in tracked files.

Exit criteria:

- you can start NullClaw locally without Railway in the loop
- the local config shape matches current upstream assumptions
- `fizzy-cli` is available in the same environment the bot will use

## Phase 2: Local NullClaw-Agent Connection

Test the primary thing first: whether you can actually connect to your agent through NullClaw.

What to verify locally:

1. NullClaw starts cleanly with your local config.
2. The selected OpenRouter model path is valid.
3. A simple direct prompt gets a normal text reply.
4. The agent stays within the intended workspace and tool boundaries.

Suggested local smoke checks:

1. start NullClaw locally with the rendered config
2. send one simple non-Fizzy prompt
3. send one short prompt that requires a basic tool-capable answer
4. confirm the reply is stable and not blocked by auth or config errors

Only move on after this works. Telegram and Fizzy are downstream of this path.

## Phase 3: Local Telegram Connection

Once the agent path works locally, add Telegram while still keeping Fizzy out of scope.

What to verify locally:

1. the bot process connects to Telegram successfully
2. only the allowed Telegram user can interact with it
3. a normal Telegram message reaches the same agent path you already validated locally

Suggested local smoke checks:

1. start the local bot with `TELEGRAM_BOT_TOKEN` and `TELEGRAM_ALLOW_FROM`
2. send a plain text message from the allowed account
3. confirm you receive a normal reply in Telegram
4. confirm the logs show no channel or auth errors

At this stage the test is only "Telegram can reach the agent", not yet session control or Fizzy.

## Phase 4: Local Session Commands

After Telegram works, check the conversation lifecycle commands in isolation.

### `/start`

Verify locally that `/start`:

- opens or reactivates a usable conversation
- introduces the bot as a Fizzy assistant
- leaves the session ready for follow-up messages

### `/end`

Verify locally that `/end`:

- ends the active conversation
- clears the conversational context
- causes the next free-text message to behave like a fresh session

Suggested local smoke checks:

1. send `/start`
2. send one follow-up message that creates recognizable context
3. send `/end`
4. send a fresh message and confirm the previous context is gone

Only once `/start` and `/end` are settled does it make sense to test Fizzy behavior.

## Phase 5: Local Fizzy Control

Fizzy comes last in the local validation ladder.

Start by proving the tool surface itself works before judging the agent's higher-level behavior.

What to verify locally:

1. `fizzy-cli` authenticates with your local env vars.
2. the agent prefers `fizzy-cli` for board and card actions.
3. Telegram replies stay short and readable instead of dumping raw CLI output.
4. the agent asks for clarification when a board or card match is ambiguous.

Suggested local smoke checks, in order:

1. ask the bot to show your boards
2. ask the bot to list cards on a specific board
3. ask the bot to create a card
4. ask the bot to move a card
5. ask the bot to add a comment

This is the point where you answer the final question: whether Fizzy can actually be controlled by the agent.

## Phase 6: Railway Runtime Setup

Deploy one service only.

Recommended Railway shape:

1. One app service running NullClaw continuously.
2. One persistent volume mounted for NullClaw state.
3. One replica only for the MVP.
4. Health checks enabled.

Why one replica:

- Telegram bot state and local session state are simpler with a single instance
- NullClaw memory and session handling stay deterministic
- you avoid accidental multi-instance session splitting

Expected persistent data:

- rendered `config.json`
- local SQLite memory or other NullClaw runtime state
- workspace files and skills if they are stored on the volume

## Phase 7: Current NullClaw Configuration

Create a fresh NullClaw config from current upstream schema.

Recommended workflow:

1. Run `nullclaw onboard --interactive` locally with the latest upstream binary.
2. Use the generated config as the baseline for this repo's `config.template.json`.
3. Remove live secrets from the committed template.
4. Render the final runtime `config.json` during container startup with Railway env vars.

The plan should assume these core areas are configured:

1. `models.providers.openrouter`
2. `agents.defaults.model.primary = openrouter/google/gemma-4-31b-it:free`
3. `channels.telegram.accounts.main`
4. local memory backend, preferably SQLite for the MVP
5. conservative autonomy and security settings

Important rules from current upstream behavior:

- use the current config structure, not old top-level shortcuts
- do not assume `${ENV_VAR}` interpolation inside config strings
- render the config file before startup if secrets must come from env vars
- keep Telegram access locked to your Telegram user ID

Minimum secrets/config inputs on Railway:

- `OPENROUTER_API_KEY`
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_ALLOW_FROM`
- `FIZZY_TOKEN`
- `FIZZY_PROFILE` or equivalent current Fizzy CLI profile selector
- optional `FIZZY_API_URL`
- optional default board setting

## Phase 8: Fizzy Integration Path

Use current `fizzy-cli` as the primary tool surface.

That is still the right choice even with a fresh NullClaw baseline because:

- it is maintained specifically for agent usage
- it already exposes a broad Fizzy command surface
- it returns structured output that is easier for the agent to summarize
- it avoids writing and maintaining a separate direct Fizzy client immediately

Planned work:

1. Install the latest `fizzy-cli` release in the runtime image.
2. Verify `fizzy board list` works with Railway env vars.
3. Verify `fizzy card list`, `fizzy card create`, `fizzy card move`, `fizzy card close`, and `fizzy comment create` all work in the deployed environment.
4. Make the agent strongly prefer `fizzy-cli` for all Fizzy operations.

MVP intents:

- show my boards
- show cards on a board
- search cards
- create a card
- move a card
- close or reopen a card
- add a comment
- summarize a board

Fallback rule:

- only add direct Fizzy API calls later if `fizzy-cli` lacks an action you truly need

## Phase 9: Agent Behavior And Prompting

Use current NullClaw customization mechanisms, not a large custom fork.

The customization should be small and explicit:

1. A Fizzy-focused skill or workspace prompt.
2. Instructions to keep replies short and Telegram-friendly.
3. Instructions to ask for clarification only when board/card matching is ambiguous.
4. Instructions to avoid dumping raw JSON unless explicitly requested.

Behavior rules for the assistant:

- prefer `fizzy-cli` over unrelated tools
- confirm destructive actions if the command is ambiguous or high impact
- summarize outcomes in plain text after tool use
- stay focused on Fizzy management instead of acting like a general-purpose agent

## Phase 10: Session Commands `/start` and `/end`

This should be implemented with the least invasive approach possible.

### `/start`

Plan:

1. Reuse upstream NullClaw's native `/start` handling if it already exists.
2. Customize only the greeting and expected behavior through prompt/skill files, not core code, unless absolutely necessary.

Desired `/start` behavior:

- open or reactivate the session
- present the bot as a Fizzy assistant
- hint at supported actions like board listing, card creation, and card updates

### `/end`

Plan:

1. Check whether current upstream behavior already provides a close-enough reset command such as `/new`, `/stop`, or `/abort`.
2. If not, implement `/end` as the thinnest possible alias to the current upstream session reset path.
3. Do not redesign session management internals unless forced.

Desired `/end` behavior:

- end the current session
- clear active conversational context
- make the next normal message behave like a fresh session
- send one short confirmation reply

Acceptance criteria:

- `/start` reliably begins a usable session
- `/end` reliably resets it
- free-text after `/end` has no stale conversational baggage

## Phase 11: Telegram UX Constraints

Keep the Telegram experience intentionally minimal.

For the MVP:

- private chat only
- no advanced topic routing
- no multi-user group workflows
- no extra slash commands beyond what is necessary
- short replies by default

Reply style guidelines:

- one or two short paragraphs for most answers
- bullet points only for lists of cards or actions
- no raw CLI output unless asked
- no huge JSON payloads in chat

## Phase 12: Validation Plan

Validate the system in this order.

1. Confirm NullClaw starts cleanly in local development.
2. Confirm you can reach the local agent path through NullClaw.
3. Confirm local Telegram delivery works.
4. Confirm `/start` behavior locally.
5. Confirm `/end` resets session behavior locally.
6. Confirm `fizzy-cli` auth works locally.
7. Confirm board read actions work locally.
8. Confirm card write actions work locally.
9. Repeat the same smoke checks after packaging for Railway.

Suggested smoke tests:

1. send one plain message and confirm NullClaw can answer locally
2. send a plain Telegram message and confirm it reaches the agent
3. `/start`
4. send one contextual follow-up message
5. `/end`
6. send a fresh normal message and verify the old session context is gone
7. "show my boards"
8. "show cards on board X"
9. "create a card called Y"
10. "move card N to column Z"
11. "comment on card N: ..."

## Risks

The main risks are:

1. The current local repo may encode old NullClaw config keys or old assumptions.
2. Free OpenRouter models may be rate-limited or temporarily unstable.
3. Upstream NullClaw slash-command behavior may have shifted since older examples.
4. Old `fizzy-cli` packaging or env var names in this repo may no longer match current upstream.
5. Railway-specific debugging may hide problems that would have been obvious in local testing.

## Recommended Order Of Work

Use this sequence.

1. Refresh the runtime baseline to latest NullClaw and latest `fizzy-cli`.
2. Verify the local NullClaw-to-agent path before enabling Telegram.
3. Verify Telegram + OpenRouter locally without Fizzy writes first.
4. Verify `/start` and `/end` locally.
5. Verify `fizzy-cli` commands locally.
6. Add the Fizzy-focused skill/prompt.
7. Build a fresh current-config deployment for Railway.
8. Repeat the end-to-end Telegram smoke tests on Railway.

## Nice-To-Have Features Later

After the MVP works, these would be good additions.

1. Board aliases like `inbox`, `backlog`, or `marketing`.
2. Destructive-action confirmation for deletes or cross-board moves.
3. A daily summary of stalled or newly updated cards.
4. Fizzy webhook notifications forwarded into Telegram.
5. A backup model if the free Gemma route becomes flaky.
6. A dedicated read-only mode for group chats.
7. A tiny audit log of executed Fizzy mutations.

## Definition Of Done

The MVP is done when:

1. the deployment runs on Railway using a fresh upstream-based NullClaw runtime
2. the local NullClaw-to-agent path has already been proven before deployment
3. Telegram messages reach the bot reliably
4. the bot uses `openrouter/google/gemma-4-31b-it:free`
5. the bot can read and update Fizzy through current `fizzy-cli`
6. responses are short and usable in Telegram
7. `/start` begins a session and `/end` resets it cleanly
