import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    enum Period: String, CaseIterable, Identifiable {
        case today = "Today"
        case week = "Week"
        case month = "Month"
        case all = "All"

        var id: String { rawValue }
    }

    @State private var period: Period = .today

    private var filteredVictories: [Victory] {
        let calendar = Calendar.current
        let victories = appViewModel.victories
        switch period {
        case .today:
            return victories.filter { calendar.isDateInToday($0.date) }
        case .week:
            guard let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else { return [] }
            return victories.filter { $0.date >= start }
        case .month:
            guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return [] }
            return victories.filter { $0.date >= start }
        case .all:
            return victories
        }
    }

    private var minutesByCategory: [(category: Category, minutes: Int)] {
        let categoryIdToMinutes = Dictionary(grouping: filteredVictories, by: { $0.categoryId })
            .mapValues { $0.reduce(0) { $0 + $1.minutes } }
        let categories = appViewModel.categories
        return categoryIdToMinutes.compactMap { (key, value) in
            guard let cat = categories.first(where: { $0.id == key }) else { return nil }
            return (cat, value)
        }.sorted { $0.minutes > $1.minutes }
    }

    private var eggProgress: Double {
        let total = max(appViewModel.achievements.count, 1)
        let unlocked = appViewModel.achievements.filter { $0.isUnlocked }.count
        return Double(unlocked) / Double(total)
    }

    private struct DayPoint: Identifiable { let id = UUID(); let date: Date; let minutes: Int }

    private var minutesByDay: [DayPoint] {
        let calendar = Calendar.current
        let dayToMinutes = Dictionary(grouping: filteredVictories, by: { calendar.startOfDay(for: $0.date) })
            .mapValues { $0.reduce(0) { $0 + $1.minutes } }
        let sortedDays = dayToMinutes.keys.sorted()
        return sortedDays.map { DayPoint(date: $0, minutes: dayToMinutes[$0] ?? 0) }
    }

    private var topActions: [(action: Action, count: Int)] {
        let actionIdToCount = Dictionary(grouping: filteredVictories, by: { $0.actionId })
            .mapValues { $0.count }
        return actionIdToCount.compactMap { (key, value) in
            guard let action = appViewModel.actions.first(where: { $0.id == key }) else { return nil }
            return (action, value)
        }
        .sorted { $0.count > $1.count }
        .prefix(5)
        .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                periodPicker
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.cardBackground)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .padding(.vertical, 4)

                if minutesByCategory.isEmpty == false {
                    Text("Categories (min)")
                        .foregroundColor(Theme.textPrimary)
                        .font(.headline)
                    
                    PieChart(slices: minutesByCategory.map { (Color(hex: $0.category.colorHex), Double($0.minutes)) })
                        .frame(height: 180)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.cardBackground)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .padding(.vertical, 4)
                }

                if appViewModel.achievements.isEmpty == false {
                    EggProgressView(progress: eggProgress)
                }

                if minutesByDay.count > 1 {
                    Text("Minutes by day")
                        .foregroundColor(Theme.textPrimary)
                        .font(.headline)
                    
                    LineChart(points: minutesByDay.map { ($0.date, Double($0.minutes)) })
                        .frame(height: 160)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.cardBackground)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .padding(.vertical, 4)
                }

                if topActions.isEmpty == false {
                    Text("Top 5 actions")
                        .foregroundColor(Theme.textPrimary)
                        .font(.headline)
                    
                    ForEach(Array(topActions.enumerated()), id: \.offset) { idx, item in
                        HStack {
                            Text("\(idx + 1). \(item.action.title)")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(item.count)")
                                .foregroundColor(Theme.success)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.cardBackground)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .padding(.vertical, 4)
                    }
                }

                Text("Victories")
                    .foregroundColor(Theme.textPrimary)
                    .font(.headline)
                
                if filteredVictories.isEmpty {
                    Text("No data for period")
                        .foregroundColor(Theme.textSecondary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.cardBackground)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .padding(.vertical, 4)
                } else {
                    ForEach(filteredVictories.sorted { $0.date > $1.date }) { v in
                        let action = appViewModel.actions.first { $0.id == v.actionId }
                        let category = appViewModel.categories.first { $0.id == v.categoryId }
                        HStack(spacing: 12) {
                            Circle().fill(Color(hex: category?.colorHex ?? "#808080")).frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(action?.title ?? "Untitled")
                                    .foregroundColor(Theme.textPrimary)
                                Text(category?.title ?? "Uncategorized").font(.caption).foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            Text("\(v.minutes) min").bold()
                                .foregroundColor(Theme.success)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.cardBackground)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Theme.primaryBackground.ignoresSafeArea())
        .foregroundColor(Theme.textPrimary)
        .navigationTitle("Statistics")
    }

    private var periodPicker: some View {
        Picker("Period", selection: $period) {
            ForEach(Period.allCases) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

private struct PieChart: View {
    struct Slice: Identifiable { let id = UUID(); let color: Color; let value: Double }
    let slices: [Slice]

    init(slices: [(Color, Double)]) {
        let total = max(slices.reduce(0) { $0 + max(0, $1.1) }, 0.0001)
        self.slices = slices.map { Slice(color: $0.0, value: max(0, $0.1) / total) }
    }

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            let segments: [(start: Angle, end: Angle, color: Color)] = {
                var current = -90.0
                return slices.map { s in
                    let start = Angle(degrees: current)
                    let end = Angle(degrees: current + s.value * 360.0)
                    current = end.degrees
                    return (start, end, s.color)
                }
            }()

            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    Path { path in
                        path.move(to: center)
                        path.addArc(center: center, radius: radius, startAngle: seg.start, endAngle: seg.end, clockwise: false)
                    }
                    .fill(seg.color)
                }
            }
        }
    }
}

private struct LineChart: View {
    let points: [(Date, Double)]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let sorted = points.sorted { $0.0 < $1.0 }
            let maxY = max(sorted.map { $0.1 }.max() ?? 1, 1)
            let minX = sorted.first?.0.timeIntervalSince1970 ?? 0
            let maxX = sorted.last?.0.timeIntervalSince1970 ?? 1
            let dx = max(maxX - minX, 1)

            Path { path in
                for (i, p) in sorted.enumerated() {
                    let x = CGFloat((p.0.timeIntervalSince1970 - minX) / dx) * width
                    let y = height - CGFloat(p.1 / maxY) * height
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Theme.success, lineWidth: 2)

            ForEach(sorted, id: \.0) { p in
                let x = CGFloat((p.0.timeIntervalSince1970 - minX) / dx) * width
                let y = height - CGFloat(p.1 / maxY) * height
                Circle()
                    .fill(Theme.success.opacity(0.8))
                    .frame(width: 6, height: 6)
                    .position(x: x, y: y)
            }
        }
    }
}

#Preview {
    NavigationView {
        StatsView()
            .environmentObject(AppViewModel())
    }
}

