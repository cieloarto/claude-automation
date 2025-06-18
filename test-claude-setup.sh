#!/bin/bash

# Test script to investigate Claude Code setup behavior

echo "=== Testing Claude Code Setup Bypass ==="

# Test 1: Try environment variables
echo "Test 1: Testing with environment variables"
export CLAUDE_NO_SETUP=1
export CLAUDE_SKIP_SETUP=1
export CLAUDE_HEADLESS=1

# Test with simple print command
echo "Running: claude --dangerously-skip-permissions --print 'test'"
claude --dangerously-skip-permissions --print "test"

# Test 2: Check config files
echo -e "\n=== Current Configuration ==="
echo "Config at ~/.config/claude/:"
cat ~/.config/claude/config.json 2>/dev/null || echo "Config file not found"

echo -e "\nClaude config list output:"
claude config list

# Test 3: Try to create a minimal session input
echo -e "\n=== Test 3: Automated input ==="
echo "Creating automated input file..."
cat > /tmp/claude_input.txt << 'EOF'
exit
EOF

echo "Testing with automated input:"
claude --dangerously-skip-permissions < /tmp/claude_input.txt &
PID=$!
sleep 3
kill $PID 2>/dev/null
wait $PID 2>/dev/null

# Clean up
rm -f /tmp/claude_input.txt

echo -e "\n=== Test Complete ==="