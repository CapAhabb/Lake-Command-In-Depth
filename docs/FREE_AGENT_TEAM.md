# Free Agent Team

## Current Rule

No paid agent swarm yet.

Use free/local work until:

- the app runs clean
- the MVP path is usable
- the product story is clear
- there is a revenue path

## Team Shape

### PM Agent

Owner: main thread.

Jobs:

- maintain vision
- keep scope tight
- approve task handoff
- block commits until captain approves

### UI Cleanup Agent

Jobs:

- split large UI files
- preserve bezel look
- run widget tests

Allowed files:

- `starter_app/lib/chart_plotter_screen.dart`
- future `starter_app/lib/widgets/*`
- `starter_app/test/widget_test.dart`

### Data Model Agent

Jobs:

- define simple lake/species/trip models
- keep offline-first
- add tests

Allowed files:

- `starter_app/lib/models/*`
- `starter_app/lib/services/*`
- `starter_app/test/*`

### QA Agent

Jobs:

- run analyze/tests
- report failures
- do not edit unless assigned

Commands:

```bash
cd starter_app
flutter analyze
flutter test
```

## Agent Output Format

Each agent reports:

- files changed
- tests run
- pass/fail
- risk
- next step
