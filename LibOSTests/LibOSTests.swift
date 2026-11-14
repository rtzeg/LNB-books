import Foundation
import Testing
import SceneKit
@testable import LibOS

@MainActor
struct LibOSTests {
    @Test func catalogAndGraphResources() throws {
        let books: [Book] = try ResourceLoader.load("DemoBooks")
        let graph: NavigationConfiguration = try ResourceLoader.load("LibraryNavigation")
        let seeds: [SurveyResponse] = try ResourceLoader.load("DemoResponses")
        #expect(books.count == 31)
        let potter = books.filter { $0.title.hasPrefix("Harry Potter") }
        #expect(potter.count == 7)
        #expect(potter.allSatisfy { $0.shelfID == "SHELF_1" && $0.floor == 1 })
        #expect(seeds.count == 40)
        #expect(seeds.allSatisfy { $0.isDemo })
        #expect(Set(books.map(\.id)).count == books.count)
        for book in books {
            let shelf = try #require(graph.shelves.first { $0.id == book.shelfID })
            #expect(graph.nodes.contains { $0.id == shelf.accessNodeID })
            #expect(RoutingEngine.path(from: "ENTRANCE", to: shelf.accessNodeID, graph: graph) != nil)
        }
    }

    @Test func routesUseConnectedClearCorridors() throws {
        let graph: NavigationConfiguration = try ResourceLoader.load("LibraryNavigation")
        for start in graph.nodes {
            for destination in graph.shelves {
                let route = try #require(RoutingEngine.path(from: start.id, to: destination.accessNodeID, graph: graph))
                #expect(route.first?.id == start.id)
                #expect(route.last?.id == destination.accessNodeID)
                for (a, b) in zip(route, route.dropFirst()) {
                    #expect(graph.edges.contains { ($0.fromNode == a.id && $0.toNode == b.id) || ($0.toNode == a.id && $0.fromNode == b.id) })
                    // Sample every route edge against shelf footprints and exterior walls,
                    // with a 0.2m clearance beyond the procedural shelf geometry.
                    for i in 0...100 {
                        let fraction = Double(i) / 100
                        let x = a.position.x + (b.position.x - a.position.x) * fraction
                        let z = a.position.z + (b.position.z - a.position.z) * fraction
                        #expect(x > 20.2 && x < 84 && z > -6.8 && z < 6.8)
                        for shelf in graph.shelves {
                            #expect(!(abs(x - shelf.position.x) < 1.8 && abs(z - shelf.position.z) < 0.525))
                        }
                        // No interior OBJ obstacles occupy this eastern collection zone.
                    }
                }
            }
        }
    }

    @Test func shortestPathAndMissingDestination() throws {
        let graph: NavigationConfiguration = try ResourceLoader.load("LibraryNavigation")
        let path = try #require(RoutingEngine.path(from: "ENTRANCE", to: "A6", graph: graph))
        #expect(path.map(\.id) == ["ENTRANCE", "J0", "J1", "J2", "A6"])
        #expect(RoutingEngine.path(from: "ENTRANCE", to: "UNKNOWN", graph: graph) == nil)
        #expect(RoutingEngine.path(from: "UNKNOWN", to: "A1", graph: graph) == nil)
        #expect(RoutingEngine.path(from: "A1", to: "A1", graph: graph)?.count == 1)
        let disconnected = NavigationConfiguration(sceneName: graph.sceneName, coordinateSystem: graph.coordinateSystem, modelFilename: nil, modelTransform: graph.modelTransform, floors: graph.floors, nodes: graph.nodes, edges: [], shelves: graph.shelves)
        #expect(RoutingEngine.path(from: "ENTRANCE", to: "A1", graph: disconnected) == nil)
    }

    @Test func adaptiveSurveyAndRecommendations() throws {
        #expect(!SurveyFlow.questions(for: .never).contains { $0.id == "ease" })
        #expect(SurveyFlow.questions(for: .active).contains { $0.id == "ease" })
        #expect(SurveyFlow.questions(for: .lapsed).first?.title == "Why did you stop visiting?")
        let books: [Book] = try ResourceLoader.load("DemoBooks")
        let ranked = RecommendationEngine.ranked(books, interests: ["Technology", "History"], language: nil)
        #expect(ranked.prefix(8).allSatisfy { ["Technology", "History"].contains($0.genre) })
        #expect(RecommendationEngine.ranked([], interests: [], language: nil).isEmpty)
        #expect(InsightsEngine.suggestions([]).isEmpty)
    }

    @Test func persistenceSubmissionAndInsights() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let repository = SurveyRepository(url: url)
        #expect(try repository.load().isEmpty)
        let state = AppState(repository: repository)
        let response = SurveyResponse(id: "LOCAL_TEST", timestamp: Date(), segment: .never, barriers: ["Lack of awareness"], services: ["Digital resources"], interests: ["Technology", "History"], motivation: [], navigationEase: nil, source: "University", feedback: "", language: "English", isDemo: false)
        #expect(state.submit(response))
        #expect(state.submissions.count == 1)
        #expect(state.interests == ["Technology", "History"])
        #expect(InsightsEngine.suggestions(state.submissions).contains { $0.id == "Lack of awareness" && $0.evidence.hasPrefix("1 of 1") })
        let relaunched = AppState(repository: repository)
        #expect(relaunched.submissions.first?.id == "LOCAL_TEST")
        relaunched.reset()
        #expect(try repository.load().isEmpty)
        #expect(relaunched.interests.isEmpty)
        #expect(relaunched.demoResponses.count == 40)
    }

    @Test func importedModelAndStablePlacement() throws {
        let graph: NavigationConfiguration = try ResourceLoader.load("LibraryNavigation")
        let scene = try ImportedLibrarySceneProvider().makeScene(configuration: graph)
        let mesh = try #require(scene.rootNode.childNode(withName: "buildingMesh", recursively: false))
        #expect(mesh.childNodes.count == 20)
        #expect(mesh.childNodes.contains { ($0.name ?? "").hasPrefix("Stavs_1_") })
        let books: [Book] = try ResourceLoader.load("DemoBooks")
        #expect(books.first?.shelfID == "SHELF_1")
        #expect(graph.shelves.first?.position == Point3(x: 28, y: 0.15, z: -1))
        let reloaded: NavigationConfiguration = try ResourceLoader.load("LibraryNavigation")
        #expect(graph.shelves.map(\.position) == reloaded.shelves.map(\.position))
        let controller = LibrarySceneController(graph: graph)
        let view = SCNView()
        controller.update(book: books.first, start: "ENTRANCE", command: 0, mode: "route", view: view)
        let building = try #require(controller.scene.rootNode.childNode(withName: "buildingMesh", recursively: false))
        #expect(building.childNodes.filter { !$0.isHidden }.count == 1)
        controller.update(book: books.first, start: "ENTRANCE", command: 1, mode: "building", view: view)
        #expect(building.childNodes.filter { !$0.isHidden }.count > 1)
    }

    @Test func proceduralFallback() throws {
        let graph: NavigationConfiguration = try ResourceLoader.load("LibraryNavigation")
        let missingModel = NavigationConfiguration(sceneName: graph.sceneName, coordinateSystem: graph.coordinateSystem, modelFilename: "missing.usdz", modelTransform: graph.modelTransform, floors: graph.floors, nodes: graph.nodes, edges: graph.edges, shelves: graph.shelves)
        let controller = LibrarySceneController(graph: missingModel)
        #expect(controller.usedFallback)
        for shelf in graph.shelves {
            #expect(controller.scene.rootNode.childNode(withName: shelf.id, recursively: true) != nil)
        }
    }
}
