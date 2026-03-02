---
name: fizzy
description: Manages Fizzy boards, cards, steps, comments, reactions, and pins. Use when user asks about boards, cards, tasks, backlog or anything Fizzy.
---

# Fizzy CLI Skill

Manage Fizzy boards, cards, steps, comments, reactions, and pins.

## Quick Reference

| Resource | List | Show | Create | Update | Delete | Other |
|----------|------|------|--------|--------|--------|-------|
| board | `board list` | `board show ID` | `board create` | `board update ID` | `board delete ID` | `migrate board ID` |
| card | `card list` | `card show NUMBER` | `card create` | `card update NUMBER` | `card delete NUMBER` | `card move NUMBER` |
| search | `search QUERY` | - | - | - | - | - |
| column | `column list --board ID` | `column show ID --board ID` | `column create` | `column update ID` | `column delete ID` | - |
| comment | `comment list --card NUMBER` | `comment show ID --card NUMBER` | `comment create` | `comment update ID` | `comment delete ID` | `comment attachments show --card NUMBER` |
| step | - | `step show ID --card NUMBER` | `step create` | `step update ID` | `step delete ID` | - |
| reaction | `reaction list` | - | `reaction create` | - | `reaction delete ID` | - |
| tag | `tag list` | - | - | - | - | - |
| user | `user list` | `user show ID` | - | - | - | - |
| notification | `notification list` | - | - | - | - | - |
| pin | `pin list` | - | - | - | - | `card pin NUMBER`, `card unpin NUMBER` |

---

## ID Formats

**IMPORTANT:** Cards use TWO identifiers:

| Field | Format | Use For |
|-------|--------|---------|
| `id` | `03fe4rug9kt1mpgyy51lq8i5i` | Internal ID (in JSON responses) |
| `number` | `579` | CLI commands (`card show`, `card update`, etc.) |

**All card CLI commands use the card NUMBER, not the ID.**

Other resources (boards, columns, comments, steps, reactions, users) use their `id` field.

---

## Response Structure

All responses follow this structure:

```json
{
  "success": true,
  "data": { ... },
  "summary": "4 boards",
  "breadcrumbs": [ ... ],
  "meta": {
    "timestamp": "2026-01-12T21:21:48Z"
  }
}
```

**Error responses:**
```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Not Found",
    "status": 404
  }
}
```

---

## Card Statuses

By default, `fizzy card list` returns **open cards only**. To fetch other states:

| Status | How to fetch |
|--------|--------------|
| Open (default) | `fizzy card list` |
| Closed/Done | `fizzy card list --indexed-by closed` |
| Not Now | `fizzy card list --indexed-by not_now` |
| Golden | `fizzy card list --indexed-by golden` |
| Stalled | `fizzy card list --indexed-by stalled` |

Pseudo-columns: `--column done`, `--column not-now`, `--column maybe`

---

## Common Commands

### Boards

```bash
fizzy board list
fizzy board show BOARD_ID
fizzy board create --name "Name"
fizzy board update BOARD_ID --name "New Name"
fizzy board delete BOARD_ID
```

### Cards

```bash
fizzy card list [--board ID] [--column ID] [--assignee ID] [--tag ID] [--sort newest|oldest|latest] [--all]
fizzy card show CARD_NUMBER
fizzy card create --board ID --title "Title" [--description "HTML"] [--tag-ids "id1,id2"]
fizzy card update CARD_NUMBER [--title "Title"] [--description "HTML"]
fizzy card delete CARD_NUMBER
fizzy card close CARD_NUMBER
fizzy card reopen CARD_NUMBER
fizzy card postpone CARD_NUMBER
fizzy card column CARD_NUMBER --column COLUMN_ID
fizzy card move CARD_NUMBER --to BOARD_ID
fizzy card assign CARD_NUMBER --user USER_ID
fizzy card self-assign CARD_NUMBER
fizzy card tag CARD_NUMBER --tag "name"
fizzy card pin CARD_NUMBER
fizzy card unpin CARD_NUMBER
fizzy card golden CARD_NUMBER
fizzy card ungolden CARD_NUMBER
```

### Search

```bash
fizzy search "query" [--board ID] [--sort newest|oldest|latest] [--all]
```

### Columns

```bash
fizzy column list --board BOARD_ID
fizzy column create --board BOARD_ID --name "Name"
```

### Comments

```bash
fizzy comment list --card NUMBER
fizzy comment create --card NUMBER --body "HTML"
fizzy comment update COMMENT_ID --card NUMBER --body "HTML"
fizzy comment delete COMMENT_ID --card NUMBER
```

### Steps (To-Do Items)

```bash
fizzy step create --card NUMBER --content "Text" [--completed]
fizzy step update STEP_ID --card NUMBER [--completed] [--not-completed]
fizzy step delete STEP_ID --card NUMBER
```

### Other

```bash
fizzy tag list
fizzy user list
fizzy pin list
fizzy notification list
fizzy notification read-all
fizzy reaction create --card NUMBER --content "emoji"
fizzy identity show
```

---

## Pagination

```bash
fizzy card list --page 2        # Specific page
fizzy card list --all           # All pages
```

---

## Useful jq Patterns

```bash
fizzy card list | jq '[.data[] | {number, title, board: .board.name}]'
fizzy card list | jq '.data[:5]'
fizzy board list | jq '[.data[].id]'
fizzy comment list --card 42 | jq '[.data[].body.plain_text]'
```

---

## Workflow: Create Card with Steps

```bash
CARD=$(fizzy card create --board BOARD_ID --title "Task" | jq -r '.data.number')
fizzy step create --card $CARD --content "Step 1"
fizzy step create --card $CARD --content "Step 2"
```

## Workflow: Move Card Through Board

```bash
fizzy card column 42 --column COLUMN_ID
fizzy card self-assign 42
fizzy card close 42
```
