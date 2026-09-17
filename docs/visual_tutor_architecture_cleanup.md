# Visual Tutor architecture cleanup

## Production navigation

The only production entry path is:

`AiTutorApp -> AppRoutes -> TutorShell -> DashboardScreen / VisualTutorHomeScreen / TutorScreen`.

`lib/screens/dashboard/dashboard_screen.dart` is the authoritative dashboard.
The retired `lib/screens/Dashboard/dashboard.dart` was not reachable from that
route tree and has been removed.

The retired Riverpod lesson-selection prototype was also unreachable. It used
an incompatible, separate state model and required packages that the shipped
application does not use. It was removed instead of adding unused dependencies.

## Active tutor boundaries

- `TutorScreen` remains the screen composition root and session/turn owner.
- `TutorStreamCoordinator` owns the active SSE iterator and turn epoch. A
  cancelled or replaced stream cannot update a newer screen state.
- `TeachingCanvasBoard` owns board playback, pause/replay, reduced motion, and
  board scrolling.
- `StudentInteractionPanel` owns typed response input and voice controls.
- `LiveTeachingBoard` and `BoardElementRenderer` own declarative board output.

## Analyzer status

`flutter analyze` has zero errors after removing the unreachable prototype.
The remaining 31 diagnostics are warnings/info only. They are confined to:

- deprecated Flutter radio APIs in `step_interaction_widget.dart`;
- unused legacy helpers still co-located in `tutor_screen.dart`;
- style nits in the teaching-plan contract and tests.

They do not block compilation. The next safe refactor is to move the live
screen's co-located widgets into separate files one group at a time, with the
existing canvas tests migrated to `LiveTeachingBoard` keys before deleting the
old widget assertions.

## Test migration note

`test/tutor_canvas_screen_test.dart` includes assertions for removed canvas
keys (`tutor-speech-quote-panel`, `jump-to-latest-step`, and
`teaching-board-action-*`). These must be rewritten against the current
declarative live-board semantics, not used as a reason to reintroduce dead UI.
