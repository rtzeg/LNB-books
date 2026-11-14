# LNB Beyond — 180-second jury pitch

Rehearse at roughly 130–140 words per minute and leave the indicated pauses for taps. Timings total exactly 180 seconds; delivery should be rehearsed with the actual presenter and device.

## 0:00–0:30 — Problem (slide 1)

“A library can be full of knowledge and still feel unfamiliar to someone who rarely visits. If we hear mainly from people already inside, we risk missing the barriers experienced by people outside: uncertainty about services, inconvenient hours, or simply not knowing where to begin. We propose an audience-research pilot connected to a useful visitor experience. This complements existing library research; it does not assume LNB has never asked these questions.”

## 0:30–1:25 — Solution and live demo (slide 2)

“This is LNB Beyond: discover, navigate, understand. It runs entirely offline on this phone.

First, Your Voice welcomes everyone, including people who have never visited. I choose a low-frequency visitor group, lack of awareness, and interests in technology and history. The questions adapt to the visitor group.

When I submit, the app saves my anonymous response on this device and recommends books using transparent local rules. Here is a history recommendation. I tap Find in Library, and the app resolves its shelf and calculates a route through connected corridors.

This is the supplied schematic Gaismas pils model, with our fixed demonstration shelves, not verified real holdings. I can rotate it and change my starting location. The route updates immediately.

Finally, Insights shows the new local response separately from clearly labeled sample data.”

Pause speaking briefly during navigation and the map rotation. Keep the optional survey answers skipped in the demo.

## 1:25–1:55 — Users and value (slide 3)

“For a first-time or returning visitor, the value is a clearer starting point: relevant reading and a visible path to a shelf. For regular visitors, it is easier discovery and a structured way to describe problems. For library teams, the value is connecting barriers and interests to practical hypotheses: where outreach, signage or service communication may help. The innovation is this connected loop from listening to discovery to navigation and back to evidence.”

## 1:55–2:35 — Technical implementation (slide 4)

“The prototype uses native SwiftUI, a bundled book collection, local JSON persistence and Swift Charts. SceneKit renders the supplied building model and our fixed shelves. Navigation metadata is independent of the mesh, and Dijkstra’s algorithm traverses only explicitly connected walkable paths. A book points to a shelf, and that shelf points to an access node.

Our final model is not required for today’s demonstration. Later, we can import validated geometry, align its coordinate system and verify every navigation edge. The recommendations and dashboard suggestions are deterministic rules, not generative AI. No account, server, API key or internet connection is needed.”

## 2:35–3:00 — Next steps (slide 5)

“Next, we would validate the model and shelf data with library staff, then recruit beyond the building through universities, cafés and community partners. Our proposed pilot targets about 400 responses, with explicit quotas for never, lapsed, occasional and active visitors. Those are targets, not results. Before deployment, we need privacy and security review and protected institutional analytics. Expansion to other libraries or museums, and B2B licensing, remain hypotheses to test.”

## Five-slide outline

1. **Who is missing from the conversation?** Barriers and sampling bias; proposed pilot opportunity.
2. **One connected experience.** Survey → recommendations → shelf route → insights. Live phone demo.
3. **Value for people and institutions.** New/lapsed visitors, regular visitors, library teams.
4. **Working offline today.** SwiftUI + local data + graph routing + replaceable SceneKit view.
5. **Validate, pilot, improve.** Real model/catalog, external recruitment, secure deployment; expansion hypothesis.

## Exact demo actions

Before the pitch: install and run once, enable airplane mode, keep screen awake, close alerts, and reset local submissions in Insights if you want a 40→41 total. Return to Discover. A full survey can take more than the 55-second live slot; rehearse taps with a second presenter or pause on the final survey page before the pitch if needed, explaining that earlier answers were entered beforehand.

1. Show Discover's LNB Beyond wordmark and featured book.
2. Your Voice → Share your perspective.
3. Select Never or not in more than five years → Next.
4. Select Lack of awareness → Next.
5. Select Digital resources → Next.
6. Select A welcoming introduction → Next.
7. Select Technology and History → Next.
8. Skip preferred language; skip recruitment source (or select University → Next).
9. Leave optional text blank → Submit response.
10. Explore recommended books → tap The Histories (or another history/technology recommendation).
11. Find in Library → show cyan route and shelf marker.
12. Drag on map to rotate. Scroll to Current location and choose Reading area. The path length increases from approximately 8m to 22m for The Histories.
13. Open Insights: 41 combined responses, 1 local response after a fresh reset. Choose Local only to show the actual submission and quota progress.

## Likely jury questions and concise answers

- **Are these actual findings?** No. Forty synthetic examples are clearly labeled. Only submissions made on the phone are local responses; we have not conducted a representative study.
- **Does LNB already survey non-visitors?** We do not claim otherwise. This is a proposed complementary recruitment and service-design pilot.
- **How will you reach people outside the library?** Recruit through universities, cafés, community centers and social channels, recording recruitment sources and monitoring segment quotas.
- **Why approximately 400?** It is a practical pilot recruitment target, not a universal statistical guarantee. Sampling method, nonresponse and segment coverage need research review.
- **Is this the real building or live catalog?** No. Bibliographic examples have illustrative shelf assignments. Real geometry, holdings and shelf data require institutional approval and validation.
- **How does the phone know where I am?** You select a known location manually. There is no indoor positioning. QR scanning is deferred.
- **Can a route cross a shelf?** The current graph uses validated corridor edges; tests check the procedural shelf footprints. Imported geometry needs fresh clearance validation.
- **Where is the AI?** There is no generative AI. Recommendations rank matching interests and language; insights count selected answers and expose their evidence.
- **What happens to private information?** No account or identifiers are requested, and data stays on-device. Optional text warns against personal details. Production needs privacy/security/GDPR review and retention controls.
- **Can this be licensed?** Potentially, but B2B licensing is a business hypothesis, not validated demand or revenue.
- **What if the final model is late?** The supplied OBJ is bundled offline; a floor-and-shelves fallback preserves the same fixed book positions.

## Honest limitations

Single-floor concept layout; illustrative holdings; no live availability, indoor positioning, QR scanner, AR, localization, cloud synchronization, production admin authentication or validated accessible routing. The imported-model adapter needs a real asset and alignment testing. Local responses are not deduplicated people. SceneKit is deprecated but isolated for a future renderer replacement. Physical-device performance and signing must be checked on the team's actual presentation iPhone.
