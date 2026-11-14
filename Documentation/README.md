# LNB Beyond

The supplied Gaismas pils OBJ is now active, with permanent first-floor demo shelves and Building/Route/Shelf views. See MODEL_IMPORT.md for exact coordinates.

An offline native iOS 17+ hackathon prototype implemented in the existing `LibOS.xcodeproj`. The bundle identifier remains `rmn.LibOS`; automatic signing is preserved. The original deployment target was iOS 26.4 and is now 17.0. Swift language mode remains 5.0. Display name: LNB Beyond.

## Launch

Open `LibOS.xcodeproj`, choose the **LibOS** scheme, choose an iPhone simulator and press Run (⌘R). No package installation, network service, account or API key is required. The three JSON resources live inside the file-system-synchronized app group and are bundled by Xcode.

For a physical iPhone: connect/unlock it, trust the Mac, enable Developer Mode if prompted, select the device as run destination and choose your development team under LibOS → Signing & Capabilities if Xcode requires one. No team was supplied in the starter project, so deployment may require selecting yours. Preserve the existing bundle ID unless your account cannot provision it. Press Run, then rehearse with airplane mode enabled. This delivery does not claim testing on your physical iPhone.

## Implemented

- Four native tabs, warm editorial styling and reusable cards/actions.
- 24 searchable books in six genres, details, six shared shelf mappings and cross-tab navigation.
- Stable procedural library: floor, cutaway walls, corridors, entrance, bookshelves, information desk and reading area.
- SceneKit orbit, pinch zoom, reset, route focus, shelf focus, shelf highlighting, start/destination markers and cyan graph route.
- Independent Dijkstra routing; unknown/disconnected destinations show an empty/error state without a fabricated route.
- Four adaptive survey branches, single/multiple selection, optional text/language/source, validation, previous/next, anonymous ID/timestamp and atomic local persistence.
- Deterministic interest/language recommendations and explanations.
- Swift Charts segments, barrier/interest/service/source counts, evidence-based suggestions, recent feedback and local-only quota progress.
- 40 fixed synthetic records stored separately from submissions; All/Demo/Local filters and local deletion/reset.
- Replaceable scene provider, imported SCN/DAE/USDZ loading path and missing-model fallback. OBJ conversion workflow is documented in MODEL_IMPORT.md.

## Deferred

QR scanning and AVFoundation camera permissions, localized UI, actual catalog integration, real building geometry and navigation validation, automatic positioning, multi-floor routing, AR, cloud backend and secured administration. No camera permission is requested because there is no scanner. The manual location selector is the reliable demonstration path.

## Data and architecture

`LibraryModels.swift` contains Codable models, routing, persistence, recommendations and observable shared state. `LibraryScene.swift` isolates SceneKit. Discover and navigation UI live in `ContentView.swift`; survey and analytics have separate feature files. The existing unused starter `Item.swift` remains intact.

`DemoBooks.json`, `DemoResponses.json` and `LibraryNavigation.json` are the bundled seed/configuration data. Local responses are stored atomically in the app Documents directory as `lnb-responses.json`. Relaunch restores interests from the most recent local response. Seed data never overwrites local submissions. Optional free text is limited to 1,000 characters. No telemetry or network calls are included.

## Validation

Xcode BuildProject succeeded for the app and subsequently for build-for-testing. Six Swift Testing cases cover bundled resources, shelf mapping, all start/shelf route connectivity and geometric clearance, missing/disconnected destinations, survey branching, recommendation ranking, persistence/relaunch/reset, insight evidence and missing-model fallback. Run with Product → Test (⌘U), or `xcodebuild -project LibOS.xcodeproj -scheme LibOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:LibOSTests test`.

The command-line test attempt in the coding sandbox could not connect to CoreSimulatorService. Xcode's test-run tool subsequently reported cancellation by user interaction. A compiled test target is not a passing test run; execution remains unconfirmed unless updated in VALIDATION.md.

Simulator interaction verified survey → recommendations → book detail → 3D route → orbit → changed start → updated Insights, including 40→41 total and 1 local response, plus a search with no results. A visual pass found and corrected prominent-button contrast; final verification status is recorded in VALIDATION.md.

## Rehearsal checklist

1. Launch on the actual presentation iPhone, then enable airplane mode and relaunch.
2. Follow the exact actions in PITCH.md. Verify readable buttons, a visible route and responsive orbit/pinch.
3. Change the starting location and check route distance/instructions.
4. Relaunch and confirm the local response and interest recommendations persist.
5. Use Insights → Local only; delete local responses if resetting for the jury.
6. Keep the original procedural graph and `modelFilename: null` for the reliable demo.

## Roadmap

1. Offline SwiftUI prototype (this delivery).
2. Import measured building geometry and align/validate navigation.
3. Integrate approved catalog, holdings and shelf data.
4. Conduct an externally recruited audience pilot (~400 target; 30% never, 30% lapsed, 20% occasional, 20% active).
5. Deploy secure institutional analytics with privacy review and improve recommendations.
6. Evaluate additional libraries, universities and museums; test B2B licensing as a hypothesis.

This proposed pilot does not assert that LNB lacks existing services or non-visitor research. Sample statistics are not real findings. Production requires further privacy, security and GDPR review.
