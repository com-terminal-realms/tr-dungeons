---
inclusion: auto
---

# Debugging Workflow - Log-Based Development Process

## Philosophy
Logs are our common language between builder (AI) and tester (human).

## Core Principles
1. Never guess - Add logging to understand what's happening
2. Logs are truth - Trust what logs show
3. Comprehensive logging - Log entry, exit, state changes, decisions
4. Persistent across sessions

## Standard Format
```gdscript
print("ComponentName: action -> detail")
```

## Workflow
1. Identify Problem
2. Add Logging
3. Run & Collect Logs
4. Analyze Together
5. Fix Based on Evidence
