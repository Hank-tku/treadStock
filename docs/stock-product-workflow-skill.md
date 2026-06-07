---
name: stock-product-workflow
description: Use when improving StockPilot / TrendStock product flows, strategy learning, recommendation UX, finance wording, Flutter architecture, QA, or release readiness. Combines gstack-style specialist review with claude-harness-style staged delivery for this repo.
---

# Stock Product Workflow

Use this skill for non-trivial work in `/Users/henry/code/stock`, especially when the user asks to make the app easier for ordinary people to use or learn strategies.

## Workflow

Run the smallest path that fits the task:

- **Hotfix**: reproduce or trace the bug -> find root cause -> patch -> focused test.
- **Feature**: product framing -> UX/state design -> implementation -> focused tests -> broader `flutter analyze` / `flutter test` when shared behavior changes.
- **Product review**: product/UX/engineering/security/QA passes -> ranked findings -> recommended implementation slices.

## Specialist Passes

Use these roles as internal checkpoints:

- **Product / Office Hours**: identify the real user pain, target user, narrowest wedge, success signal, and non-goals.
- **CEO Review**: challenge whether the scope is too broad, too vague, or solving the wrong problem.
- **Design Review**: score information architecture, interaction states, ordinary-user comprehension, empty/error states, mobile layout, and AI-slop risk.
- **Engineering Review**: inspect routing, Riverpod state, service boundaries, data flow, tests, performance, and edge cases before coding.
- **QA Review**: verify the affected user journey, not just the changed function.
- **Security / Compliance Review**: preserve first-launch disclaimer, avoid guaranteed-return or buy/sell wording, do not add secrets to the client, and keep HTTPS-only data sources.
- **Documentation / Learning Review**: when user-facing behavior changes, update nearby learning copy or docs so the app explains itself.

## StockPilot Rules

- Keep the app pure-client unless the user explicitly asks for backend work.
- Use existing Flutter/Riverpod/GoRouter/Drift patterns.
- For strategy features, separate four user states: no strategy, strategy exists but no matches, insufficient review sample, and true error.
- Ordinary users should see goals and observations before raw parameters.
- Financial copy should use words like `观察`, `复盘`, `线索`, and `仅供参考`; avoid `买入`, `卖出`, `稳赚`, `保证`.
- When a screenshot shows a broken page, trace the route/state path before proposing visual-only changes.

## Review Output

For analysis-only requests, return:

1. **Top Finding**: the highest-risk product or engineering issue.
2. **Why It Happens**: code/path evidence.
3. **User Impact**: what an ordinary user experiences.
4. **Fix Order**: small implementation slices.
5. **QA Gate**: commands or scenarios that prove the fix.

For implementation requests, make the change and finish with validation results.
