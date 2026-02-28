#!/bin/bash
# Install pre-commit hook that runs all checks including tests

HOOK_PATH=$(git rev-parse --git-dir)/hooks/pre-commit

cat > "$HOOK_PATH" << 'EOF'
#!/bin/bash
# Pre-commit hook for TR-Dungeons
# Ensures no errors are committed to the repository

echo "🔍 Running pre-commit checks..."

# Get the working tree directory
WORK_TREE=$(git rev-parse --show-toplevel)

# Check if any CDK Python files are being committed
cdk_files=$(git diff --cached --name-only --diff-filter=ACM | grep "^infrastructure/cdk/.*\.py$" || true)

if [ -n "$cdk_files" ]; then
    echo "   Checking CDK Python files..."
    
    cd "$WORK_TREE/infrastructure/cdk" || exit 1
    
    # Check if venv exists
    if [ ! -d ".venv" ]; then
        echo "⚠️  Virtual environment not found - skipping CDK checks"
        echo "   Run: cd infrastructure/cdk && pipenv install --dev"
    else
        # Run Black formatting check
        if ! .venv/bin/black --check . 2>&1 | tee /tmp/black-check.log; then
            echo ""
            echo "❌ COMMIT BLOCKED: Black formatting errors!"
            echo ""
            echo "Run this to fix:"
            echo "  cd infrastructure/cdk && .venv/bin/black ."
            echo ""
            exit 1
        fi
        
        # Run ruff linting
        if ! .venv/bin/ruff check . 2>&1 | tee /tmp/ruff-check.log; then
            echo ""
            echo "❌ COMMIT BLOCKED: Ruff linting errors!"
            echo ""
            echo "Run this to fix:"
            echo "  cd infrastructure/cdk && .venv/bin/ruff check . --fix"
            echo ""
            exit 1
        fi
        
        # Run mypy type checking (warnings only, don't block)
        if ! .venv/bin/mypy stacks/ tests/ 2>&1 | tee /tmp/mypy-check.log; then
            echo "⚠️  Mypy type checking warnings (not blocking)"
        fi
        
        # Run pytest tests
        echo "   Running pytest tests..."
        if ! .venv/bin/pytest tests/unit/ -v 2>&1 | tee /tmp/pytest-check.log; then
            echo ""
            echo "❌ COMMIT BLOCKED: Tests failed!"
            echo ""
            echo "Fix the failing tests before committing."
            echo "Full log: /tmp/pytest-check.log"
            echo ""
            exit 1
        fi
    fi
    
    echo "✅ CDK checks passed"
    cd "$WORK_TREE" || exit 1
fi

# Check if any game files are being committed
game_files=$(git diff --cached --name-only --diff-filter=ACM | grep "^apps/game-client/" || true)

if [ -n "$game_files" ]; then
    echo "   Testing game for errors (5 second check)..."
    
    # Change to game directory
    cd "$WORK_TREE/apps/game-client" || exit 1
    
    # Run game headless for 5 seconds and capture output
    timeout 5 godot --headless . > /tmp/godot-precommit.log 2>&1
    
    # Check for errors (not warnings)
    if grep -E "(ERROR:|SCRIPT ERROR:)" /tmp/godot-precommit.log > /tmp/godot-errors.log; then
        echo ""
        echo "❌ COMMIT BLOCKED: Game has errors!"
        echo ""
        echo "Errors found:"
        echo "----------------------------------------"
        cat /tmp/godot-errors.log
        echo "----------------------------------------"
        echo ""
        echo "Fix all errors before committing."
        echo "Full log: /tmp/godot-precommit.log"
        echo ""
        echo "To bypass this check (NOT RECOMMENDED):"
        echo "  git commit --no-verify"
        echo ""
        echo "Only use --no-verify with explicit user approval!"
        exit 1
    fi
    
    # Check for warnings (informational only)
    warning_count=$(grep -c "WARNING:" /tmp/godot-precommit.log || true)
    if [ "$warning_count" -gt 0 ]; then
        echo "⚠️  Found $warning_count warning(s) - commit allowed but consider fixing"
    fi
    
    echo "✅ Game checks passed"
fi

echo "✅ All pre-commit checks passed"
exit 0
EOF

chmod +x "$HOOK_PATH"

echo "✅ Pre-commit hook installed at: $HOOK_PATH"
echo ""
echo "The hook will now run:"
echo "  - Black formatting checks"
echo "  - Ruff linting"
echo "  - Mypy type checking"
echo "  - Pytest unit tests"
echo "  - Godot game error checks"
