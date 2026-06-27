# Lake Command In Depth

Flutter chartplotter app for Great Lakes fishing intelligence.

The active app lives in `starter_app/`. The current product direction is the
dark plastic chartplotter bezel: data controls on the left, full-screen map
surface, toolbox menu, compass, and live trip telemetry.

## Current Focus

- Keep the bezel reference intact: dark housing, tight data panel, white layer
  buttons, orange active glow.
- Make the app usable before expanding agents or services.
- Keep work cheap: local code, tests, and docs first. No paid agent swarm until
  there is a working model and revenue path.

## Project Map

- `starter_app/lib/chart_plotter_screen.dart` - main chartplotter UI
- `starter_app/lib/main.dart` - app entry
- `starter_app/lib/models/` - observation and scenario data models
- `starter_app/lib/services/` - mock data and scenario aggregation
- `starter_app/test/` - widget and service tests
- `.agents_tmp/PLAN.md` - older visual implementation plan
- `docs/PROJECT_STATE.md` - current operating state
- `docs/AGENT_PROTOCOL.md` - rules for future agents

## Commands

```bash
cd starter_app
flutter pub get
flutter analyze
flutter test
flutter run
```

## Git Rule

Do not commit, push, or merge without captain approval.
