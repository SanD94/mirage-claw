#!/bin/bash
set -e

# NullClaw Agent and Fizzy BDD Test Runner
# This script runs the BDD test scenarios against the local NullClaw agent

NULLCLAW_CMD="nullclaw agent -m"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

passed=0
failed=0

log_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    passed=$((passed + 1))
}

log_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    failed=$((failed + 1))
}

log_info() {
    echo -e "${YELLOW}→ INFO${NC}: $1"
}

# ==========================================
# PREFLIGHT CHECKS
# ==========================================

log_info "Running preflight checks..."

# Check nullclaw is available
if ! command -v nullclaw &> /dev/null; then
    log_fail "nullclaw not found in PATH"
    exit 1
fi
log_pass "nullclaw is available"

# Check fizzy is available
if ! command -v fizzy &> /dev/null; then
    log_fail "fizzy not found in PATH"
    exit 1
fi
log_pass "fizzy is available"

# Check security config
block_high_risk=$(nullclaw config get autonomy.block_high_risk_commands 2>/dev/null || echo "error")
if [ "$block_high_risk" != "true" ]; then
    log_fail "block_high_risk_commands should be true, got: $block_high_risk"
else
    log_pass "Security block is enabled"
fi

# Check allowed_commands
allowed_cmds=$(nullclaw config get autonomy.allowed_commands 2>/dev/null || echo "[]")
if [[ "$allowed_cmds" == *"fizzy"* ]]; then
    log_pass "fizzy is in allowed_commands"
else
    log_fail "fizzy should be in allowed_commands, got: $allowed_cmds"
fi

echo ""
log_info "Starting BDD test scenarios..."
echo ""

# ==========================================
# SECURITY SCENARIOS
# ==========================================

log_info "=== Security Scenarios ==="

# Test: Fizzy command passes through security
log_info "Scenario: Fizzy command passes through security"
result=$($NULLCLAW_CMD "fizzy board list" 2>&1 | tail -5)
if echo "$result" | grep -q "Coding\|Discipline\|To-Do"; then
    log_pass "fizzy board list executes successfully"
else
    log_fail "fizzy board list failed: $result"
fi

echo ""

# ==========================================
# BOARD SCENARIOS
# ==========================================

log_info "=== Board Scenarios ==="

# Test: User requests list of boards
log_info "Scenario: User requests list of boards"
result=$($NULLCLAW_CMD "list my fizzy boards" 2>&1 | tail -10)
if echo "$result" | grep -q "Coding\|Discipline\|To-Do"; then
    log_pass "Board list returned successfully"
else
    log_fail "Board list failed or no boards found"
fi

echo ""

# ==========================================
# SUMMARY
# ==========================================

echo ""
echo "=========================================="
echo -e "Test Results: ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC}"
echo "=========================================="

if [ $failed -gt 0 ]; then
    exit 1
fi

exit 0
