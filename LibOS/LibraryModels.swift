import Foundation
import Observation

struct Book: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let genre: String
    let language: String
    let description: String
    let shelfID: String
    let floor: Int
    let keywords: [String]
}

struct Point3: Codable, Equatable {
    var x: Double
    var y: Double
    var z: Double
    func distance(to p: Point3) -> Double {
        sqrt(pow(x - p.x, 2) + pow(y - p.y, 2) + pow(z - p.z, 2))
    }
}
struct NavigationNode: Codable, Identifiable {
    let id: String
    let label: String
    let position: Point3
    let floor: Int
    let type: String
}
struct NavigationEdge: Codable {
    let fromNode: String
    let toNode: String
    let weight: Double
    let accessible: Bool
}
struct ShelfLocation: Codable, Identifiable {
    let id: String
    let label: String
    let accessNodeID: String
    let position: Point3
    let floor: Int
}
struct ModelTransform: Codable {
    let scale: Point3
    let rotation: Point3
    let translation: Point3
}
struct NavigationConfiguration: Codable {
    let sceneName: String
    let coordinateSystem: String
    let modelFilename: String?
    let modelTransform: ModelTransform
    let floors: [Int]
    let nodes: [NavigationNode]
    let edges: [NavigationEdge]
    let shelves: [ShelfLocation]
}

enum RoutingEngine {
    // Dijkstra only traverses explicitly authored, bidirectional walkable edges.
    static func path(from start: String, to end: String, graph: NavigationConfiguration) -> [NavigationNode]? {
        let nodes = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })
        guard nodes[start] != nil, nodes[end] != nil else { return nil }
        var distances = [start: 0.0]
        var previous: [String: String] = [:]
        var remaining = Set(nodes.keys)
        while let current = remaining.min(by: { distances[$0, default: .infinity] < distances[$1, default: .infinity] }) {
            guard distances[current, default: .infinity].isFinite else { break }
            remaining.remove(current)
            if current == end {
                var ids = [end]
                while let parent = previous[ids[0]] { ids.insert(parent, at: 0) }
                return ids.compactMap { nodes[$0] }
            }
            for edge in graph.edges where edge.weight >= 0 && edge.weight.isFinite {
                let next: String
                if edge.fromNode == current { next = edge.toNode }
                else if edge.toNode == current { next = edge.fromNode }
                else { continue }
                guard remaining.contains(next) else { continue }
                let candidate = distances[current, default: .infinity] + edge.weight
                if candidate < distances[next, default: .infinity] {
                    distances[next] = candidate
                    previous[next] = current
                }
            }
        }
        return nil
    }
}

enum VisitorSegment: String, Codable, CaseIterable, Identifiable {
    case never, lapsed, occasional, active
    var id: String { rawValue }
    var label: String {
        switch self {
        case .never: "Never or not in more than five years"
        case .lapsed: "Not in the last year"
        case .occasional: "One to five times"
        case .active: "Six or more times"
        }
    }
    var shortLabel: String { rawValue.capitalized }
    var target: Int { self == .never || self == .lapsed ? 120 : 80 }
}
struct SurveyResponse: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let segment: VisitorSegment
    let barriers: [String]
    let services: [String]
    let interests: [String]
    let motivation: [String]
    let navigationEase: String?
    let source: String
    let feedback: String
    let language: String?
    let isDemo: Bool
}
enum ResourceLoader {
    static func load<T: Decodable>(_ name: String) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
}
struct SurveyRepository {
    let url: URL
    init(url: URL? = nil) {
        self.url = url ?? URL.documentsDirectory.appending(path: "lnb-responses.json")
    }
    func load() throws -> [SurveyResponse] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([SurveyResponse].self, from: Data(contentsOf: url))
    }
    func save(_ responses: [SurveyResponse]) throws {
        try JSONEncoder().encode(responses).write(to: url, options: .atomic)
    }
}
enum RecommendationEngine {
    static func score(_ book: Book, interests: [String], language: String?) -> Int {
        (interests.contains(book.genre) ? 10 : 0) + (language == book.language ? 2 : 0)
    }
    static func ranked(_ books: [Book], interests: [String], language: String?) -> [Book] {
        books.sorted {
            let a = score($0, interests: interests, language: language)
            let b = score($1, interests: interests, language: language)
            return a == b ? $0.id < $1.id : a > b
        }
    }
}
struct Insight: Identifiable {
    let id: String
    let title: String
    let evidence: String
}
enum InsightsEngine {
    static func suggestions(_ responses: [SurveyResponse]) -> [Insight] {
        guard !responses.isEmpty else { return [] }
        let rules = [
            ("Lack of awareness", "Increase awareness of library services through external outreach."),
            ("Difficulty finding books", "Investigate improved signage and book-finding tools."),
            ("Opening hours", "Explore whether different opening hours would better serve audiences.")
        ]
        var result = rules.compactMap { key, title -> Insight? in
            let count = responses.filter { $0.barriers.contains(key) }.count
            guard count > 0 else { return nil }
            return Insight(id: key, title: title, evidence: "\(count) of \(responses.count) responses selected \(key.lowercased()).")
        }
        let digital = responses.filter { $0.services.contains("Digital resources") }.count
        if digital > 0 {
            result.append(Insight(id: "digital", title: "Improve communication about available digital options.", evidence: "\(digital) of \(responses.count) requested digital resources."))
        }
        return result
    }
}
@Observable
final class AppState {
    var tab = 0
    var books: [Book] = []
    var graph: NavigationConfiguration?
    var selectedBook: Book?
    var startNodeID = "ENTRANCE"
    var submissions: [SurveyResponse] = []
    var demoResponses: [SurveyResponse] = []
    var error: String?
    private let repository: SurveyRepository
    init(repository: SurveyRepository = SurveyRepository()) {
        self.repository = repository
        do {
            books = try ResourceLoader.load("DemoBooks")
            graph = try ResourceLoader.load("LibraryNavigation")
            demoResponses = try ResourceLoader.load("DemoResponses")
            submissions = try repository.load()
            selectedBook = books.first
        } catch { self.error = "Could not load local data: \(error.localizedDescription)" }
    }
    var interests: [String] { submissions.last?.interests ?? [] }
    var recommendations: [Book] {
        RecommendationEngine.ranked(books, interests: interests, language: submissions.last?.language)
    }
    func explanation(_ book: Book) -> String {
        interests.contains(book.genre) ? "Because you chose \(book.genre.lowercased())" : "Explore \(book.genre.lowercased())"
    }
    func navigate(to book: Book) {
        selectedBook = book
        tab = 2
    }
    func submit(_ response: SurveyResponse) -> Bool {
        do {
            let updated = submissions + [response]
            try repository.save(updated)
            submissions = updated
            return true
        } catch { self.error = "Your response could not be saved. Please try again."; return false }
    }
    func reset() {
        do {
            try repository.save([])
            submissions = []
            startNodeID = "ENTRANCE"
        } catch { self.error = "Could not delete local responses." }
    }
}
