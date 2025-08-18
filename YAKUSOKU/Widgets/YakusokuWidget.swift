import WidgetKit
import SwiftUI
import AppIntents
import SwiftData

struct YakusokuEntry: TimelineEntry {
    let date: Date
    let topCommitments: [CommitmentData]
    let todayCheckins: [String: Rating]
}

struct CommitmentData: Identifiable {
    let id: String
    let title: String
    let ifThen: String?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> YakusokuEntry {
        YakusokuEntry(
            date: .now,
            topCommitments: [
                CommitmentData(id: "1", title: "인스턴트 식품 안 먹기", ifThen: nil)
            ],
            todayCheckins: [:]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (YakusokuEntry) -> ()) {
        let entry = YakusokuEntry(
            date: .now,
            topCommitments: [
                CommitmentData(id: "1", title: "인스턴트 식품 안 먹기", ifThen: nil)
            ],
            todayCheckins: [:]
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<YakusokuEntry>) -> ()) {
        Task { @MainActor in
            do {
                let container = try SharedContainer.container()
                let context = container.mainContext
                
                let commitmentDescriptor = FetchDescriptor<Commitment>(
                    sortBy: [SortDescriptor(\Commitment.priority, order: .forward)]
                )
                let commitments = try context.fetch(commitmentDescriptor)
                
                let todayKey = Date().yakusokuDayKey
                let checkinDescriptor = FetchDescriptor<Checkin>(
                    predicate: #Predicate { checkin in
                        checkin.dayKey == todayKey
                    }
                )
                let checkins = try context.fetch(checkinDescriptor)
                
                var todayCheckinMap: [String: Rating] = [:]
                for checkin in checkins {
                    todayCheckinMap[checkin.commitmentID] = checkin.rating
                }
                
                let commitmentData = commitments.prefix(3).map { commitment in
                    CommitmentData(
                        id: commitment.id,
                        title: commitment.title,
                        ifThen: commitment.ifThen
                    )
                }
                
                let entry = YakusokuEntry(
                    date: .now,
                    topCommitments: commitmentData,
                    todayCheckins: todayCheckinMap
                )
                
                let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
                let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
                completion(timeline)
            } catch {
                let entry = YakusokuEntry(date: .now, topCommitments: [], todayCheckins: [:])
                let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600)))
                completion(timeline)
            }
        }
    }
}

struct YakusokuWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            LockScreenWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: YakusokuEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YAKUSOKU")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            
            if let first = entry.topCommitments.first {
                Text(first.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(Rating.allCases, id: \.self) { rating in
                        Button(intent: CheckInIntent(
                            commitmentID: first.id,
                            ratingRaw: rating.rawValue,
                            dayKey: Date().yakusokuDayKey
                        )) {
                            Text(rating.emoji)
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    entry.todayCheckins[first.id] == rating ?
                                    Color.accentColor.opacity(0.2) :
                                    Color.secondary.opacity(0.1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text("약속을 만들어주세요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

struct MediumWidgetView: View {
    let entry: YakusokuEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YAKUSOKU")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if entry.topCommitments.isEmpty {
                Text("약속을 만들어주세요")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.topCommitments.prefix(2)) { commitment in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(commitment.title)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            ForEach(Rating.allCases, id: \.self) { rating in
                                Button(intent: CheckInIntent(
                                    commitmentID: commitment.id,
                                    ratingRaw: rating.rawValue,
                                    dayKey: Date().yakusokuDayKey
                                )) {
                                    Text(rating.emoji)
                                        .font(.caption)
                                        .frame(width: 28, height: 28)
                                        .background(
                                            entry.todayCheckins[commitment.id] == rating ?
                                            Color.accentColor.opacity(0.2) :
                                            Color.secondary.opacity(0.1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

struct LockScreenWidgetView: View {
    let entry: YakusokuEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let first = entry.topCommitments.first {
                Text(first.title)
                    .font(.headline)
                    .lineLimit(2)
                    .widgetAccentable()
                
                HStack(spacing: 2) {
                    ForEach(0..<7) { day in
                        Circle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            } else {
                Text("YAKUSOKU")
                    .font(.headline)
                    .widgetAccentable()
                Text("약속을 만들어주세요")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct YakusokuWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "YakusokuWidget", provider: Provider()) { entry in
            YakusokuWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("YAKUSOKU")
        .description("오늘의 약속을 바로 체크인하세요")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}