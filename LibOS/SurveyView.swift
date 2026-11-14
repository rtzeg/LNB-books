import SwiftUI

struct SurveyQuestion: Identifiable {
    let id: String
    let title: String
    let options: [String]
    var multiple = true
    var required = true
}
enum SurveyFlow {
    static let barriers = ["Lack of awareness", "Opening hours", "Travel distance", "Difficulty finding books", "Accessibility", "No relevant recommendations", "No barriers"]
    static let services = ["Digital resources", "Study spaces", "Events", "Book recommendations", "Research support"]
    static let interests = ["Technology", "History", "Psychology", "Fiction", "Science", "Culture"]
    static func questions(for segment: VisitorSegment) -> [SurveyQuestion] {
        let barrierTitle: String
        let serviceTitle: String
        let motivationTitle: String
        switch segment {
        case .never:
            barrierTitle = "Why have you not visited?"
            serviceTitle = "What services interest you?"
            motivationTitle = "What would motivate a first visit?"
        case .lapsed:
            barrierTitle = "Why did you stop visiting?"
            serviceTitle = "Which services would be valuable?"
            motivationTitle = "What would bring you back?"
        case .occasional:
            barrierTitle = "What prevents more frequent visits?"
            serviceTitle = "What brings you to the library?"
            motivationTitle = "What would make your next visit better?"
        case .active:
            barrierTitle = "What problems have you encountered?"
            serviceTitle = "What do you value?"
            motivationTitle = "What improvements matter most?"
        }
        var questions = [
            SurveyQuestion(id: "barriers", title: barrierTitle, options: barriers),
            SurveyQuestion(id: "services", title: serviceTitle, options: services),
            SurveyQuestion(id: "motivation", title: motivationTitle, options: ["A welcoming introduction", "Relevant recommendations", "Flexible hours", "Clearer navigation", "Accessible facilities", "More events"])
        ]
        if segment == .active || segment == .occasional {
            questions.append(SurveyQuestion(id: "ease", title: segment == .active ? "How easy is navigation?" : "How easy is it to find books?", options: ["Very easy", "Mostly easy", "Sometimes difficult", "Very difficult"], multiple: false))
        }
        questions.append(SurveyQuestion(id: "interests", title: "Which subjects interest you?", options: interests))
        questions.append(SurveyQuestion(id: "language", title: "Preferred reading language", options: ["English", "Latvian", "Russian"], multiple: false, required: false))
        questions.append(SurveyQuestion(id: "source", title: "Where did you hear about this pilot?", options: ["University", "Café", "Community center", "Library", "Social media", "Other"], multiple: false, required: false))
        return questions
    }
}
struct SurveyProgressView: View {
    let current: Int
    let total: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("YOUR VOICE").font(.caption.weight(.bold)).tracking(2)
                Spacer()
                Text("\(current) of \(total)").font(.caption)
            }
            ProgressView(value: Double(current), total: Double(total)).tint(Theme.gold)
        }
    }
}
struct SurveyQuestionCard: View {
    let question: SurveyQuestion
    @Binding var selected: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.title).font(.title2.bold()).fontDesign(.serif)
            Text(question.required ? (question.multiple ? "Choose all that apply." : "Choose one answer.") : "Optional · you can skip this question.")
                .font(.subheadline).foregroundStyle(.secondary)
            ForEach(question.options, id: \.self) { option in
                Button {
                    if question.multiple {
                        if selected.contains(option) { selected.removeAll { $0 == option } }
                        else {
                            if question.id == "barriers" {
                                if option == "No barriers" { selected = [] }
                                else { selected.removeAll { $0 == "No barriers" } }
                            }
                            selected.append(option)
                        }
                    } else { selected = [option] }
                } label: {
                    HStack(spacing: 12) {
                        Text(option).frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: selected.contains(option) ? "checkmark.circle.fill" : "circle")
                    }.padding(17).foregroundStyle(selected.contains(option) ? .white : Theme.navy)
                        .background(selected.contains(option) ? Theme.navy : Color.white, in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain).accessibilityAddTraits(selected.contains(option) ? .isSelected : [])
            }
        }
    }
}
struct SurveyView: View {
    @Bindable var state: AppState
    @State private var started = false
    @State private var step = 0
    @State private var segment: VisitorSegment?
    @State private var answers: [String: [String]] = [:]
    @State private var feedback = ""
    @State private var completed: SurveyResponse?
    private var questions: [SurveyQuestion] { segment.map { SurveyFlow.questions(for: $0) } ?? [] }
    private var total: Int { questions.count + 2 }
    private var valid: Bool {
        if step == 0 { return segment != nil }
        if step > questions.count { return true }
        let q = questions[step - 1]
        return !q.required || !(answers[q.id] ?? []).isEmpty
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let completed {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 56)).foregroundStyle(.teal).accessibilityHidden(true)
                        SectionHeader(title: "You’re part of the next chapter.", subtitle: "Thank you. Your response is saved on this iPhone.")
                        Text("Your interests now shape your book recommendations.")
                        PrimaryActionButton(title: "Explore recommended books", icon: "sparkles") { state.tab = 0 }
                        Text("Anonymous response: \(completed.id)\n\(completed.timestamp.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                        Button("Start another response") { restart() }
                    } else if !started {
                        Image(systemName: "quote.bubble").font(.system(size: 54)).foregroundStyle(Theme.gold).accessibilityHidden(true)
                        Text("Help us build a library for everyone.").font(.largeTitle.bold()).fontDesign(.serif)
                        Text("Whether you visit every week or have never stepped inside, your perspective matters.").font(.title3)
                        Label("2–3 minutes", systemImage: "clock")
                        Label("Anonymous · stored only on this device", systemImage: "lock.shield")
                        Text("This proposed pilot aims to hear from people beyond existing library visitors. Please avoid names, contact details or other personal information in your feedback.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        PrimaryActionButton(title: "Share your perspective") { started = true }
                    } else {
                        SurveyProgressView(current: step + 1, total: total)
                        if step == 0 {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("How often have you visited the library in the last 12 months?").font(.title2.bold()).fontDesign(.serif)
                                ForEach(VisitorSegment.allCases) { value in
                                    Button {
                                        if segment != value { answers = [:] }
                                        segment = value
                                    } label: {
                                        HStack {
                                            Text(value.label).frame(maxWidth: .infinity, alignment: .leading)
                                            Image(systemName: segment == value ? "checkmark.circle.fill" : "circle")
                                        }.padding(18).foregroundStyle(segment == value ? .white : Theme.navy)
                                            .background(segment == value ? Theme.navy : Color.white, in: RoundedRectangle(cornerRadius: 14))
                                    }.buttonStyle(.plain)
                                }
                            }
                        } else if step <= questions.count {
                            let question = questions[step - 1]
                            SurveyQuestionCard(question: question, selected: Binding(get: { answers[question.id] ?? [] }, set: { answers[question.id] = $0 }))
                        } else {
                            SectionHeader(title: "Anything else we should understand?", subtitle: "Optional. Please do not include personal information.")
                            TextField("Your perspective…", text: $feedback, axis: .vertical).lineLimit(5...10).padding().background(.white, in: RoundedRectangle(cornerRadius: 14))
                                .onChange(of: feedback) { _, value in if value.count > 1000 { feedback = String(value.prefix(1000)) } }
                            Text("\(feedback.count)/1,000 characters").font(.caption).foregroundStyle(.secondary)
                            Text("By submitting, you save this anonymous response locally. You can delete local responses in Insights. No response is sent to LNB.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        HStack {
                            Button("Previous") { if step > 0 { step -= 1 } else { started = false } }.buttonStyle(.bordered)
                            Spacer()
                            Button(step == total - 1 ? "Submit response" : "Next") {
                                if step == total - 1 { submit() } else { step += 1 }
                            }.buttonStyle(.borderedProminent).foregroundStyle(.white).disabled(!valid)
                        }
                        if step > 0 && step <= questions.count && !questions[step - 1].required {
                            Button("Skip") { answers[questions[step - 1].id] = []; step += 1 }
                        }
                        if !valid { Text("Please choose an answer to continue.").font(.caption).foregroundStyle(.secondary) }
                    }
                }.padding(24).frame(maxWidth: 650, alignment: .leading).frame(maxWidth: .infinity)
            }.background(Theme.ivory).foregroundStyle(Theme.navy)
                .navigationTitle("Your Voice").navigationBarTitleDisplayMode(.inline)
        }
    }
    private func submit() {
        guard let segment else { return }
        let response = SurveyResponse(id: UUID().uuidString, timestamp: Date(), segment: segment,
                                      barriers: answers["barriers"] ?? [], services: answers["services"] ?? [],
                                      interests: answers["interests"] ?? [], motivation: answers["motivation"] ?? [],
                                      navigationEase: answers["ease"]?.first, source: answers["source"]?.first ?? "Not specified",
                                      feedback: feedback.trimmingCharacters(in: .whitespacesAndNewlines), language: answers["language"]?.first, isDemo: false)
        if state.submit(response) { completed = response }
    }
    private func restart() {
        completed = nil
        segment = nil
        answers = [:]
        feedback = ""
        step = 0
        started = false
    }
}
