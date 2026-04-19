Feature: NullClaw Agent and Fizzy Integration

  This feature defines the acceptance behavior for NullClaw agent interacting
  with Fizzy boards through the secure shell execution path.

  Background:
    Given NullClaw is configured with security enabled
    And the security policy has `block_high_risk_commands: true`
    And the security policy has `allowed_commands` including "fizzy"
    And FIZZY_TOKEN environment variable is configured in runtime.env

  # ==========================================
  # SECURITY SCENARIOS
  # ==========================================

  Scenario: Security block prevents non-whitelisted commands
    Given security is enabled with `allowed_commands: ["fizzy"]`
    When the agent attempts to run `curl https://example.com`
    Then the command is blocked by the security policy
    And the agent receives a blocked response

  Scenario: Fizzy command passes through security
    Given security is enabled with `allowed_commands: ["fizzy"]`
    When the agent runs `fizzy board list`
    Then the command executes successfully
    And the board list is returned

  # ==========================================
  # BOARD SCENARIOS
  # ==========================================

  Scenario: User requests list of boards
    Given the agent is running with Fizzy access
    When the user asks "show my boards" or "list my fizzy boards"
    Then the agent invokes `fizzy board list`
    And returns a summary of available boards

  Scenario: User requests details of a specific board
    Given the user knows a board ID
    When the user asks to show that board
    Then the agent invokes `fizzy board show <board_id>`
    And returns the board details

  # ==========================================
  # CARD SCENARIOS
  # ==========================================

  Scenario: User requests cards on a board
    Given the user has access to a Fizzy board
    When the user asks to list cards on that board
    Then the agent invokes `fizzy card list --board <board_id>`
    And returns the open cards on that board

  Scenario: User creates a new card
    Given the user identifies a target board
    When the user asks to create a card with a title
    And the user provides the card title
    Then the agent invokes `fizzy card create --board <board_id> --title "<title>"`
    And confirms the created card

  Scenario: User updates an existing card
    Given a card exists on a board
    When the user asks to update the card title
    And the user provides the new title
    Then the agent invokes `fizzy card update <card_number> --title "<new_title>"`
    And confirms the updated card

  Scenario: User closes a card
    Given a card exists on a board
    When the user asks to close the card
    Then the agent invokes `fizzy card close <card_number>`
    And confirms the card is closed

  # ==========================================
  # COMMENT SCENARIOS
  # ==========================================

  Scenario: User adds a comment to a card
    Given a card exists
    When the user asks to add a comment to that card
    And the user provides the comment text
    Then the agent invokes `fizzy comment create --card <card_number> --body "<comment>"`
    And confirms the comment was added

  # ==========================================
  # STEP SCENARIOS
  # ==========================================

  Scenario: User adds a step to a card
    Given a card exists
    When the user asks to add a step to that card
    And the user provides the step content
    Then the agent invokes `fizzy step create --card <card_number> --content "<step>"`
    And confirms the step was added

  # ==========================================
  # TELEGRAM-FRIENDLY RESPONSE SCENARIOS
  # ==========================================

  Scenario: Output is concise by default
    Given the agent completes any successful Fizzy action
    When it responds to the user
    Then the reply is concise and readable
    And the reply avoids raw CLI output by default
    And the reply avoids large JSON payloads by default