# Imported model update

Simulator launch succeeded (PID 36150). Direct visual interaction confirmed the imported first floor, six fixed shelves and cyan route. Building overview and Route cutaway switching both worked. No crash observed. Later menu interaction was inconclusive because the view changed between taps; do not count it as a verified starting-location change for this revision.

- BuildProject with buildForTesting succeeded after OBJ integration, no compiler errors.
- Runtime execution: FALLBACK false; 20 distinct OBJ objects; exactly the first-floor object visible in route view; 16 building objects in overview (4 distant context objects omitted).
- All 24 catalog books resolve to reachable fixed shelf access nodes.
- All 11 walkable graph edges sampled against shelf footprints with clearance and constrained to the free eastern first-floor zone.
- Existing tests updated for the new layout; added imported-object/cutaway and deterministic-coordinate checks. Test targets compile; this update does not claim the full test suite executed.
- The absent AppIntents dependency only produces Xcode’s metadata-extraction warning; this application has no App Intents feature.

# Validation record — 14 November 2026

## Build

- Final Xcode `BuildProject(buildForTesting: true)`: **succeeded**, 1.234 seconds, no reported build errors.
- Final build log: `/var/folders/l5/rb5pl7vx4ms0d8qmb0n7xywc0000gn/T/ActionArtifacts/2C1FA034-FD91-468E-B37E-DCEF50B254B3/BuildProject/BuildProject-Log-20261114-034416.txt`.
- All three bundled JSON resources loaded during simulator execution: 24 books, graph/shelves and 40 seed responses were visible and functional.
- Six meaningful Swift Testing cases compile. Execution is **not confirmed**. Command-line xcodebuild could not access CoreSimulatorService in the sandbox and exited with an unavailable-destination error. Xcode RunAllTests reported cancellation by user interaction; no passing-test claim is made.

## Simulator verification

Device: iPhone 17 simulator, iOS 27.2.

Passed through direct interaction:

1. Discover opens, catalog/detail work, unmatched search displays an empty state.
2. Never-user survey validates required answers, accepts lack of awareness and technology/history interests, skips optional language and submits successfully.
3. Recommendations update to history/technology, including The Histories.
4. Find in Library resolves the correct shelf and displays a visible corridor route and marker.
5. Drag rotates the SceneKit map.
6. Entrance → Reading area changes the route from 8m to 13m with matching textual directions.
7. Insights increases from 40 to 41 total, and Local only shows 1 response and 100% never-users.
8. Reinstall/relaunch preserves recommendations from the local submission.
9. No crashes observed in that sequence.

The visual pass identified prominent action labels with insufficient contrast and overly distant camera framing. Both were adjusted and the final project builds. Those final visual changes were **not re-inspected on screen**. Decorative miniature cover titles may truncate; adjacent full book titles remain available.

## Remaining verification

Run the compiled tests and rehearse on the physical presentation iPhone. Explicit airplane-mode startup, physical-device performance, pinch zoom, all other survey branches and deletion/reset have not been manually verified. QR scanning is deferred, so camera-denied behavior is not applicable. Imported geometry is not validated because no real asset was supplied.

Simulator screenshots are under:
`/var/folders/l5/rb5pl7vx4ms0d8qmb0n7xywc0000gn/T/ActionArtifacts/2C1FA034-FD91-468E-B37E-DCEF50B254B3/DeviceInteractionSynthesize/`

- `Verify LNB Beyond Demo-03_37_58_833-screenshot.png` — rotated map.
- `Verify LNB Beyond Demo-03_38_17_343-screenshot.png` — recalculated route.
- `Verify LNB Beyond Demo-03_38_31_968-screenshot.png` — local Insights.
- `Verify LNB Beyond Fixes-03_42_14_262-screenshot.png` — persisted recommendations.
