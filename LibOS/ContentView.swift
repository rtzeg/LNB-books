import SwiftUI

enum Theme {
    static let ivory = Color(red: 0.97, green: 0.95, blue: 0.90)
    static let navy = Color(red: 0.08, green: 0.16, blue: 0.24)
    static let gold = Color(red: 0.51, green: 0.37, blue: 0.13)
}
struct ContentView: View {
    @Bindable var state: AppState
    var body: some View {
        TabView(selection: $state.tab) {
            DiscoverView(state: state).tabItem { Label("Discover", systemImage: "sparkles") }.tag(0)
            SurveyView(state: state).tabItem { Label("Your Voice", systemImage: "bubble.left.and.text.bubble.right") }.tag(1)
            BookNavigationView(state: state).tabItem { Label("Find a Book", systemImage: "map") }.tag(2)
            InsightsView(state: state).tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }.tag(3)
        }
        .alert("Local data", isPresented: Binding(get: { state.error != nil }, set: { if !$0 { state.error = nil } })) {
            Button("OK") { state.error = nil }
        } message: { Text(state.error ?? "") }
    }
}
struct DemoDataLabel: View {
    var text = "Demo data · placement and availability are illustrative"
    var body: some View {
        Label(text, systemImage: "info.circle").font(.caption).foregroundStyle(Theme.gold)
    }
}
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.title2.weight(.semibold)).fontDesign(.serif)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct PrimaryActionButton: View {
    let title: String
    var icon = "arrow.right"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon).foregroundStyle(.white).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 9)
        }.buttonStyle(.borderedProminent).tint(Theme.navy)
    }
}
struct GenreChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) { Text(title).font(.subheadline.weight(.medium)).padding(.horizontal, 16).padding(.vertical, 10)
                .background(selected ? Theme.navy : Color.white, in: Capsule())
                .foregroundStyle(selected ? .white : Theme.navy)
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
struct BookCover: View {
    let book: Book
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Theme.navy, book.genre == "History" ? Color.brown : Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "book.closed").font(.title2).foregroundStyle(.white.opacity(0.7))
                Spacer(minLength: 8)
                Text(book.title).font(.headline).fontDesign(.serif).foregroundStyle(.white)
                Rectangle().fill(Color.white.opacity(0.5)).frame(width: 30, height: 2)
            }.padding(14)
        }.clipShape(RoundedRectangle(cornerRadius: 10)).accessibilityHidden(true)
    }
}
struct BookCard: View {
    let book: Book
    var explanation: String? = nil
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            BookCover(book: book).frame(width: 88, height: 122)
            VStack(alignment: .leading, spacing: 7) {
                Text(book.genre.uppercased()).font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(Theme.gold)
                Text(book.title).font(.headline).foregroundStyle(Theme.navy)
                Text(book.author).font(.subheadline).foregroundStyle(.secondary)
                if let explanation { Text(explanation).font(.caption).foregroundStyle(.teal) }
                Text("Floor \(book.floor) · \(book.shelfID)").font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }.padding(16).background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}
struct FeaturedBookCard: View {
    let book: Book
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("THE NEXT CHAPTER").font(.caption.weight(.bold)).tracking(2).foregroundStyle(Color(red: 0.87, green: 0.75, blue: 0.47))
                Text(book.title).font(.title2.bold()).fontDesign(.serif)
                Text(book.author).font(.subheadline)
                Label("Discover this book", systemImage: "arrow.up.right").font(.caption.weight(.semibold))
            }.frame(maxWidth: .infinity, alignment: .leading)
            BookCover(book: book).frame(width: 105, height: 155).rotationEffect(.degrees(7))
        }.padding(24).foregroundStyle(.white).background(Theme.navy, in: RoundedRectangle(cornerRadius: 24))
    }
}
struct DiscoverView: View {
    @Bindable var state: AppState
    @State private var search = ""
    @State private var genre = "All"
    @State private var detail: Book?
    private var genres: [String] { ["All"] + Set(state.books.map(\.genre)).sorted() }
    private var filtered: [Book] {
        state.recommendations.filter {
            (genre == "All" || $0.genre == genre) &&
            (search.isEmpty || "\($0.title) \($0.author) \($0.genre) \($0.keywords.joined(separator: " "))".localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Image(systemName: "building.columns").font(.title)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LNB BEYOND").font(.headline).tracking(3)
                            Text("Discover. Navigate. Understand.").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    Text("A world of ideas.\nA place for you.").font(.largeTitle.bold()).fontDesign(.serif)
                    if let book = filtered.first {
                        Button { detail = book } label: { FeaturedBookCard(book: book) }.buttonStyle(.plain)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack { ForEach(genres, id: \.self) { value in GenreChip(title: value, selected: genre == value) { genre = value } } }
                    }
                    SectionHeader(title: state.interests.isEmpty ? "Find your next idea" : "Chosen for your curiosity", subtitle: state.interests.isEmpty ? "Explore the demonstration collection." : "Local recommendations based on your interests.")
                    DemoDataLabel()
                    if filtered.isEmpty { ContentUnavailableView.search(text: search) }
                    ForEach(filtered) { book in
                        Button { detail = book } label: { BookCard(book: book, explanation: state.explanation(book)) }.buttonStyle(.plain)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Your perspective belongs here", subtitle: "Even if you have never visited. Help shape a proposed library pilot.")
                        PrimaryActionButton(title: "Share your voice", icon: "bubble.left") { state.tab = 1 }
                    }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 20))
                }.padding(20)
            }.background(Theme.ivory).foregroundStyle(Theme.navy)
                .navigationTitle("Discover").navigationBarTitleDisplayMode(.inline)
                .searchable(text: $search, prompt: "Title, author or genre")
                .sheet(item: $detail) { book in
                    NavigationStack {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                BookCover(book: book).frame(width: 170, height: 220).frame(maxWidth: .infinity)
                                SectionHeader(title: book.title, subtitle: book.author)
                                Text(book.description)
                                Label("\(book.genre) · \(book.language)", systemImage: "tag")
                                Label("Floor \(book.floor) · \(book.shelfID)", systemImage: "books.vertical")
                                DemoDataLabel()
                                PrimaryActionButton(title: "Find in Library", icon: "location") { detail = nil; state.navigate(to: book) }
                            }.padding(24)
                        }.background(Theme.ivory).navigationTitle("Book details").navigationBarTitleDisplayMode(.inline)
                            .toolbar { Button("Done") { detail = nil } }
                    }
                }
        }
    }
}

struct BookNavigationView: View {
    @Bindable var state: AppState
    @State private var search = ""
    @State private var command = 0
    @State private var mode = "reset"
    private var shelf: ShelfLocation? { state.graph?.shelves.first { $0.id == state.selectedBook?.shelfID } }
    private var route: [NavigationNode]? {
        guard let graph = state.graph, let shelf else { return nil }
        return RoutingEngine.path(from: state.startNodeID, to: shelf.accessNodeID, graph: graph)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DemoDataLabel(text: "Gaismas pils model · fixed demo shelves · floor 1")
                    if !search.isEmpty {
                        ForEach(state.books.filter { "\($0.title) \($0.author) \($0.genre)".localizedCaseInsensitiveContains(search) }) { book in
                            Button { state.selectedBook = book; search = "" } label: { Text(book.title).frame(maxWidth: .infinity, alignment: .leading).padding(10) }
                        }
                    }
                    if let book = state.selectedBook { BookCard(book: book) }
                    if let graph = state.graph {
                        LibrarySceneView(graph: graph, book: state.selectedBook, start: state.startNodeID, command: command, mode: mode)
                            .frame(height: 360).clipShape(RoundedRectangle(cornerRadius: 22))
                        Text("Drag to orbit · Pinch to zoom").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            cameraButton("Building", icon: "building.2", action: "building")
                            cameraButton("Route", icon: "point.topleft.down.curvedto.point.bottomright.up", action: "route")
                            cameraButton("Shelf", icon: "scope", action: "destination")
                        }.buttonStyle(.bordered)
                        Picker("Current location", selection: $state.startNodeID) {
                            ForEach(graph.nodes) { node in Text(node.label).tag(node.id) }
                        }.pickerStyle(.menu)
                    }
                    if let route, let shelf {
                        SectionHeader(title: shelf.label, subtitle: "Floor \(shelf.floor) · \(distance(route).formatted(.number.precision(.fractionLength(0)))) m along demo corridors")
                        if route.count == 1 {
                            Label("You are at the destination shelf.", systemImage: "checkmark.circle.fill")
                        } else {
                            ForEach(Array(zip(route, route.dropFirst()).enumerated()), id: \.offset) { index, pair in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)").font(.caption.bold()).padding(8).background(.white, in: Circle())
                                    Text("Continue \(pair.0.position.distance(to: pair.1.position).formatted(.number.precision(.fractionLength(0)))) m to \(pair.1.label.lowercased()).")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            Label("Arrive at \(shelf.id). Your book is on this shelf.", systemImage: "flag.checkered")
                        }
                    } else {
                        ContentUnavailableView("No valid route", systemImage: "map", description: Text("Choose a book and a known starting location. No straight-line fallback is shown."))
                    }
                    Text("Your imported Gaismas pils model with a fixed demonstration collection on floor 1. Book positions are illustrative, not actual LNB holdings. Follow library signage on site.").font(.caption).foregroundStyle(.secondary)
                }.padding(20)
            }.background(Theme.ivory).foregroundStyle(Theme.navy)
                .navigationTitle("Find a Book").navigationBarTitleDisplayMode(.inline)
                .searchable(text: $search, prompt: "Choose a book")
        }
    }
    private func cameraButton(_ title: String, icon: String, action: String) -> some View {
        Button { mode = action; command += 1 } label: { Label(title, systemImage: icon).font(.caption).frame(maxWidth: .infinity) }
    }
    private func distance(_ nodes: [NavigationNode]) -> Double {
        zip(nodes, nodes.dropFirst()).reduce(0) { $0 + $1.0.position.distance(to: $1.1.position) }
    }
}
