# Project State

## Product

Lake Command In Depth is a Flutter chartplotter-style fishing command center.
The working UI direction is the physical device look: dark plastic housing,
left-side data bezel, orange active glow, compact controls, map/chart screen,
toolbox menu, compass, and trip telemetry.

## Source Of Truth

- GitHub repo: `CapAhabb/Lake-Command-In-Depth`
- Default branch: `main`
- Active app: `starter_app/`
- Main UI file: `starter_app/lib/chart_plotter_screen.dart`

## Current Health

- `flutter analyze`: passing
- `flutter test`: passing
- Local branch tracks `origin/main`

## Immediate Backlog

1. Finish bezel polish from the Codespace plan.
2. Keep bezel layout stable across desktop, tablet, and phone sizes.
3. Split `chart_plotter_screen.dart` into focused widgets after visual behavior is stable.
4. Define the first real data model for lake, weather, depth, species, and route signals.
5. Replace mock scenario data with local/offline providers first.
6. Add a narrow MVP path: open app, pick lake/species, view likely zones, save trip notes.

## Not Now

- No paid agent swarm.
- No large backend.
- No complex AI service until the manual workflow proves useful.
- No redesign away from the bezel without explicit approval.

## Imported Plan

Codespace plan source:
`/home/captain/flutter-apps/starter_app/.agents_tmp/PLAN.md`

That plan is captured as actionable work in `docs/ROADMAP.md`.
