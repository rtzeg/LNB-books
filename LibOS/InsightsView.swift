import SwiftUI
import Charts

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.gold)
            Text(value).font(.largeTitle.bold()).fontDesign(.serif)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}
struct InsightCard: View {
    let insight: Insight
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(insight.title, systemImage: "lightbulb").font(.headline)
            Text(insight.evidence).font(.subheadline).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}
struct CountRow: Identifiable {
    let id: String
    let count: Int
}
struct InsightsView: View {
    @Bindable var state: AppState
    @State private var source = "All"
    @State private var confirmReset = false
    private var responses: [SurveyResponse] {
        switch source {
        case "Local": state.submissions
        case "Demo": state.demoResponses
        default: state.demoResponses + state.submissions
        }
    }
    private func counts(_ values: [String]) -> [CountRow] {
        Dictionary(grouping: values, by: { $0 }).map { CountRow(id: $0.key, count: $0.value.count) }
            .sorted { $0.count == $1.count ? $0.id < $1.id : $0.count > $1.count }
    }
    private func share(_ segment: VisitorSegment) -> String {
        guard !responses.isEmpty else { return "0%" }
        return (Double(responses.filter { $0.segment == segment }.count) / Double(responses.count)).formatted(.percent.precision(.fractionLength(0)))
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SectionHeader(title: "Listen beyond the library.", subtitle: "Prototype admin dashboard · not a secured production interface")
                    Picker("Response dataset", selection: $source) {
                        Text("All").tag("All")
                        Text("Demo data").tag("Demo")
                        Text("Local only").tag("Local")
                    }.pickerStyle(.segmented)
                    DemoDataLabel(text: "\(state.demoResponses.count) synthetic demo responses · \(state.submissions.count) local submissions")
                    Text(source == "All" ? "Charts combine demo data and local submissions. Use Local only to inspect actual on-device responses." : source == "Demo" ? "Synthetic examples only. These are not research findings." : "Actual submissions on this device only; no claim of unique respondents.")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        StatCard(title: "Responses in view", value: "\(responses.count)", icon: "bubble.left.and.bubble.right")
                        StatCard(title: "New local responses", value: "\(state.submissions.count)", icon: "person.crop.circle.badge.plus")
                    }
                    HStack {
                        StatCard(title: "Never-user share", value: share(.never), icon: "person")
                        StatCard(title: "Lapsed-user share", value: share(.lapsed), icon: "clock")
                    }
                    SectionHeader(title: "Who we are hearing from")
                    Chart(VisitorSegment.allCases) { segment in
                        BarMark(x: .value("Segment", segment.shortLabel), y: .value("Responses", responses.filter { $0.segment == segment }.count))
                            .foregroundStyle(Theme.navy)
                    }.frame(height: 180).padding().background(.white, in: RoundedRectangle(cornerRadius: 18))
                    countSection("Main barriers", rows: counts(responses.flatMap(\.barriers)))
                    countSection("Popular interests", rows: counts(responses.flatMap(\.interests)))
                    countSection("Requested services", rows: counts(responses.flatMap(\.services)))
                    countSection("Recruitment sources", rows: counts(responses.map(\.source)))
                    SectionHeader(title: "Proposed pilot · 400 responses", subtitle: "Recruitment targets, not achieved results. Progress below counts local submissions only.")
                    ForEach(VisitorSegment.allCases) { segment in
                        let count = state.submissions.filter { $0.segment == segment }.count
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(segment.shortLabel)
                                Spacer()
                                Text("\(count) / \(segment.target) · \(segment.target / 4)% target").font(.caption)
                            }
                            ProgressView(value: Double(min(count, segment.target)), total: Double(segment.target)).tint(.teal)
                        }
                    }
                    SectionHeader(title: "Signals into action", subtitle: "Deterministic suggestions from the selected dataset. Validate through a representative pilot.")
                    ForEach(InsightsEngine.suggestions(responses)) { InsightCard(insight: $0) }
                    if responses.isEmpty { Text("No responses in this dataset yet. Complete Your Voice to begin.").foregroundStyle(.secondary) }
                    SectionHeader(title: "Recent feedback")
                    ForEach(Array(responses.filter { !$0.feedback.isEmpty }.sorted { $0.timestamp > $1.timestamp }.prefix(5))) { response in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(response.feedback)
                            Text("\(response.isDemo ? "Demo data" : "Local submission") · \(response.segment.shortLabel) · \(response.timestamp.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.white, in: RoundedRectangle(cornerRadius: 16))
                    }
                    SectionHeader(title: "Private by design")
                    Text("No accounts, tracking or network services. Responses stay on this iPhone. Production deployment requires further privacy, security and GDPR review. Avoid entering personal information.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Delete local responses & reset preferences", role: .destructive) { confirmReset = true }
                        .disabled(state.submissions.isEmpty)
                    Text("The fixed synthetic dataset remains available for the demonstration.").font(.caption).foregroundStyle(.secondary)
                }.padding(20)
            }.background(Theme.ivory).foregroundStyle(Theme.navy)
                .navigationTitle("Insights").navigationBarTitleDisplayMode(.inline)
                .confirmationDialog("Delete all locally submitted responses?", isPresented: $confirmReset, titleVisibility: .visible) {
                    Button("Delete local responses", role: .destructive) { state.reset() }
                } message: { Text("This also clears the interests used for recommendations. Demo data is preserved.") }
        }
    }
    private func countSection(_ title: String, rows: [CountRow]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title)
            if rows.isEmpty { Text("No responses yet").font(.subheadline).foregroundStyle(.secondary) }
            ForEach(rows) { row in
                HStack {
                    Text(row.id).font(.subheadline)
                    Spacer()
                    Text("\(row.count)").font(.subheadline.monospacedDigit().bold())
                }
            }
        }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}
