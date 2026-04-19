# NullClaw Telegram Fizzy BDD

## Purpose

These scenarios define the acceptance behavior for the refreshed NullClaw, Telegram, and Fizzy setup.

They are written in the order the system should be validated: locally first, then on Railway.

## Feature: Local NullClaw runtime boots

### Scenario: Local runtime starts with current upstream config

Given local environment variables are configured for NullClaw and OpenRouter
When NullClaw is started locally
Then the process starts successfully
And the config loads without schema errors
And NullClaw stays running as a long-lived process

### Scenario: Missing required local secret fails predictably

Given NullClaw is started locally without `OPENROUTER_API_KEY`
When the process starts
Then startup fails clearly
And the logs indicate which required configuration is missing

## Feature: Local NullClaw can reach the agent path

### Scenario: Simple local prompt gets a normal reply

Given NullClaw is running locally
When the operator sends a simple non-Fizzy prompt through the local path
Then the agent returns a normal text reply
And the reply is not blocked by auth or configuration errors

### Scenario: Tool-capable local prompt does not escape the intended boundaries

Given NullClaw is running locally
When the operator sends a prompt that requires a basic tool-capable answer
Then the agent completes the request successfully
And the agent remains within the intended workspace and tool boundaries

## Feature: NullClaw security configuration

### Scenario: Security block is enabled by default

Given NullClaw is running locally with security config
When the config has `block_high_risk_commands: true`
Then shell commands are blocked by default
And only whitelisted commands can execute

### Scenario: Only fizzy is allowed through security

Given NullClaw security is enabled with `allowed_commands: ["fizzy"]`
When the agent attempts to run `fizzy board list`
Then the command executes successfully
And the board list is returned

### Scenario: Non-fizzy commands are blocked

Given NullClaw security is enabled with `allowed_commands: ["fizzy"]`
When the agent attempts to run other shell commands
Then those commands are blocked by the security policy
And the agent receives a blocked response

## Feature: Local Telegram access is restricted

### Scenario: Allowed user can talk to the local bot

Given the Telegram user ID is present in `TELEGRAM_ALLOW_FROM`
And the bot is running locally with a valid `TELEGRAM_BOT_TOKEN`
When that user sends a plain message to the bot
Then the bot responds in Telegram

### Scenario: Non-allowed user cannot use the local bot

Given a Telegram user ID is not present in `TELEGRAM_ALLOW_FROM`
When that user sends a message to the local bot
Then the bot does not execute Fizzy actions for that user
And the bot remains inaccessible to that user according to the configured policy

## Feature: Local session lifecycle

### Scenario: `/start` opens a usable Fizzy session

Given the local bot is running and reachable in Telegram
When the allowed user sends `/start`
Then the bot replies with a short welcome message
And the message presents the bot as a Fizzy assistant
And the message hints at supported actions such as listing boards or creating cards

### Scenario: `/end` resets the conversation

Given the allowed user has an active conversation with the local bot
When the user sends `/end`
Then the bot confirms the session is ended
And the current conversational context is cleared

### Scenario: Message after `/end` starts fresh

Given the user previously ended the session with `/end`
When the user sends a new normal message to the local bot
Then the bot handles it as a fresh conversation
And the reply does not depend on stale context from the previous session

## Feature: Local OpenRouter model usage

### Scenario: Bot responds using Nemotron free model configuration

Given the local service is configured with `openrouter/nvidia/nemotron-3-super-120b-a12b:free`
When the allowed user asks a normal question in Telegram
Then the bot returns a text response
And the response is produced through the configured OpenRouter provider path

## Feature: Local Fizzy board reads

### Scenario: User asks for their boards

Given `fizzy-cli` is authenticated successfully in the local bot environment
When the user says "show my boards"
Then the bot invokes the Fizzy integration path
And the bot returns a short Telegram-friendly summary of the available boards
And the bot does not dump raw JSON unless explicitly requested

### Scenario: User asks for cards on a board

Given the user has access to a Fizzy board
When the user asks the local bot to list cards on that board
Then the bot retrieves the relevant cards through `fizzy-cli`
And the bot summarizes the results clearly in Telegram

## Feature: Local Fizzy card writes

### Scenario: User creates a card

Given the user identifies a target board
When the user asks the local bot to create a card with a title
Then the bot creates the card through `fizzy-cli`
And the bot confirms the created card in Telegram

### Scenario: User moves a card

Given a card exists and the target destination is valid
When the user asks the local bot to move the card
Then the bot performs the move through `fizzy-cli`
And the bot confirms the result in Telegram

### Scenario: User comments on a card

Given a card exists
When the user asks the local bot to add a comment to that card
Then the bot creates the comment through `fizzy-cli`
And the bot confirms the comment was added

## Feature: Ambiguity handling

### Scenario: Bot asks a short clarification question

Given multiple boards or cards match the user's request
When the user asks for an action that cannot be resolved safely
Then the bot asks one short clarification question
And the bot does not execute a mutation until the ambiguity is resolved

## Feature: Telegram-friendly responses

### Scenario: Output is concise by default

Given the bot completes any successful Fizzy action
When it replies in Telegram
Then the reply is concise and readable
And the reply avoids raw CLI output by default
And the reply avoids large JSON payloads by default

## Feature: Railway packaging preserves validated behavior

### Scenario: Service starts on Railway after local validation passes

Given the local validation scenarios already pass
And Railway has the required environment variables configured
And a persistent volume is mounted for NullClaw state
When the service is deployed to Railway
Then the container starts successfully
And the health check endpoint reports success
And NullClaw stays running as a long-lived process

### Scenario: Service restart preserves runtime state

Given the Railway service has already been configured and used
When Railway restarts the service
Then the bot starts successfully again
And required local runtime state is still available from the persistent volume

### Scenario: Core Telegram and Fizzy flows still work on Railway

Given the bot has already been proven locally
When the allowed user repeats the local smoke tests on Railway
Then `/start` works on Railway
And `/end` resets the session on Railway
And board and card actions still work through `fizzy-cli`

## Feature: Documentation-driven re-deploy

### Scenario: Repo docs are sufficient to recreate deployment

Given an engineer has only this repository
When they follow the plan, checklist, and local validation order
Then they can reproduce the local setup first
And they can reproduce the Railway deployment setup
And they can validate it using these BDD scenarios
