# Active Gaismas pils integration

The bundled LNB_Gaismas_pils.obj is now active. Its 20 named objects are preserved by WavefrontSceneLoader. The navigation cutaway displays only Stavs_1_; Building displays the complete building without distant context geometry. The original OBJ is unchanged. Missing MTL colors are replaced by explicit app materials. The loader supports this asset’s convex polygons and positive/negative vertex indices; arbitrary concave OBJ polygons require triangulation before import.

All 24 books keep their existing IDs and shelf IDs. Six fixed demonstration shelves occupy the clear eastern first-floor zone: X=28/36/44m, Z=-1/6m, Y=0.15m. Access points lie on the corridor side at Z=0/5m. The collection entrance is (22, 0.15, 4), not a claim about the actual building entrance. JSON is the persistent source of truth; there is no random placement or launch-time reassignment. Positions are illustrative, not actual LNB shelf data.

Routes remain inside the model’s clear first-floor zone and avoid the added shelf footprints. The supplied building itself describes a schematic layout. Do not treat these paths as surveyed public navigation. Imported model load and all 24 book routes have been executed in Xcode’s runtime snippet; floor and overview visibility verified programmatically.

If the mesh cannot load, a simple floor and the same shelves are rendered at the same coordinates. Book locations do not move in fallback mode.

---

## General future model guidance (earlier conversion workflow)

# Replacing the demonstration library

The app works without a model. `LibrarySceneProvider` isolates SceneKit in `LibOS/LibraryScene.swift`. `LibraryNavigation.json` is the independent source for navigation and shelf metadata. SceneKit is deprecated; the provider boundary permits later replacement without changing Dijkstra routing or book mappings.

## Supported workflow

1. Export actual geometry from the custom renderer. Renderer source files are not meshes. Prefer a validated USDZ, DAE or SceneKit scene. For an OBJ export, retain the `.obj`, `.mtl` and all referenced textures with relative filenames intact. Import the OBJ into a compatible 3D authoring tool and export a validated DAE/USDZ/SCN asset; this is the reliable OBJ workflow for this MVP. Direct loading of the supplied convex-polygon OBJ is implemented; other OBJ variants require validation.
2. Open the exported asset in Xcode's scene viewer and inspect materials, normals, units and orientation. Include resources in the LibOS app target (Copy Bundle Resources). A `.scnassets` directory can keep scene resources together; use the full bundle-relative filename in configuration. Confirm textures work on an offline iPhone, not just the authoring machine.
3. Set `modelFilename` in `LibraryNavigation.json` to the bundled asset filename, including its extension. `null` selects the procedural model. Missing or unreadable assets automatically fall back to the procedural scene. Always restore the original demo graph when using the original procedural layout; fallback is not proof that a graph authored for a different building is safe.
4. Set `modelTransform.scale`, `rotation` and `translation`. Rotation uses Euler radians. The wrapper applies scale and rotation to the mesh, followed by translation. Navigation coordinates stay in canonical world space: Y up, X/Z horizontal, Y=0 floor surface, one unit = one meter. Axis alignment is performed with the rotation and scale values; do not bake arbitrary model dimensions into routing code.
5. Align at least three surveyed landmarks, including the entrance and two corridor junctions. Update nodes and shelf positions in canonical world coordinates to match the final geometry. Do not assume unit conversion or alignment occurs automatically.
6. Keep stable shelf IDs in the catalog. Each shelf resolves to one `accessNodeID`, on the accessible corridor side of that shelf. Multiple books share a shelf. For imported highlighting, name the corresponding mesh parent node exactly as its shelf ID; materials beneath it receive the highlight. The independent destination marker works without mesh names.
7. Author explicit walkable edges. Edges are currently bidirectional, weighted in meters; recompute each weight from node coordinates. Validate every edge against walls, closed rooms, furniture, doors and required pedestrian clearance. The `accessible` field is reserved metadata: this prototype does not provide a certified accessible-route mode. Do not infer navigation graphs or collision geometry from OBJ files.
8. Test every start-to-shelf pair on device, including route visibility, reset/orbit/pinch, destination focus, disconnected paths and a missing model. Remove or disable imported camera/light nodes if they interfere with the app camera and lighting. Keep geometry and texture budgets small.

## Current limits

Only floor 1 is demonstrated. Multi-floor routing, stairs/lifts, dynamic closures, live positioning and accessibility certification require further work. The procedural obstacle tests validate the demo dimensions only. Imported geometry needs its own measurements, collision/clearance validation and staff sign-off before public navigation. The app is not an evacuation or emergency navigation system.

## Files

- `LibOS/LibraryScene.swift`: providers, persistent scene, camera and route renderer.
- `LibOS/LibraryModels.swift`: Codable metadata and SceneKit-independent routing engine.
- `LibOS/LibraryNavigation.json`: mesh transform, floor, nodes, edges, shelves.
- `LibOS/DemoBooks.json`: book-to-shelf mappings.

Keep the original JSON and set `modelFilename` to null for the guaranteed hackathon fallback.
