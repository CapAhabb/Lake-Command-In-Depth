# Roadmap

## Phase 1: Bezel Lock

Goal: make the current chartplotter UI stable, polished, and testable.

Tasks:

- Preserve dark plastic housing.
- Preserve smaller left data bezel.
- Preserve white/beige layer buttons.
- Preserve orange glow on active layer buttons.
- Prevent top info bar overflow at test and small widths.
- Keep toolbox and compass visually raised.
- Verify with `flutter analyze` and `flutter test`.

Status:

- Analyze passes.
- Tests pass.
- Top info bar overflow fixed.
- Dead unused knob code removed.

## Phase 2: File Cleanup

Goal: make the app workable for future contributors.

Tasks:

- Split `chart_plotter_screen.dart` into smaller widgets.
- Keep behavior unchanged during the split.
- Add focused tests for data bezel, toolbox, and chart layers.
- Keep reference images in root until a better asset folder is chosen.

Suggested split:

- `lib/widgets/chart_plotter_shell.dart`
- `lib/widgets/data_bezel_panel.dart`
- `lib/widgets/chart_area.dart`
- `lib/widgets/top_info_bar.dart`
- `lib/widgets/toolbox_menu.dart`
- `lib/widgets/compass_widget.dart`

## Phase 3: MVP Workflow

Goal: useful demo before backend or AI services.

Tasks:

- Pick lake.
- Pick target species.
- Show likely zones.
- Show weather/depth/species signals.
- Save simple captain note.
- Export/share trip summary.

## Phase 4: Data Layer

Goal: replace mock-only data with reliable low-cost sources.

Tasks:

- Define lake signal model.
- Define species signal model.
- Define route/trip note model.
- Add local JSON seed data.
- Add offline-first repository.

## Phase 5: Agents

Goal: build the team only after the app is organized and the MVP path is clear.

Rules:

- Free/local agents first.
- One agent, one narrow task.
- No paid swarm until working model and revenue path.
- No commit or push without captain approval.
