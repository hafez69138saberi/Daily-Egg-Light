import SwiftUI

struct MainView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var isPresentingAdd = false

    private var todayVictories: [Victory] {
        let calendar = Calendar.current
        return appViewModel.victories
            .filter { calendar.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    private var todayMinutesTotal: Int {
        todayVictories.reduce(0) { $0 + $1.minutes }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    todayHeader
                    if todayVictories.isEmpty == false {
                        Text("Today")
                            .foregroundColor(Theme.textPrimary)
                            .font(.headline)

                        ForEach(todayVictories) { victory in
                            VictoryRow(
                                victory: victory,
                                action: appViewModel.actions.first { $0.id == victory.actionId },
                                category: appViewModel.categories.first { $0.id == victory.categoryId }
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(Theme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Daily Egg Light")

            Button(action: { isPresentingAdd = true }) {
                Text("Add Victory +")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding()
            .accessibilityIdentifier("addVictoryButton")
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddVictoryView()
                .environmentObject(appViewModel)
        }
    }

    private var todayHeader: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text("\(todayVictories.count) victory(ies)")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Minutes")
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Text("\(todayMinutesTotal)")
                        .font(.title3).bold()
                        .foregroundColor(Theme.success)
                }
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

private struct VictoryRow: View {
    let victory: Victory
    let action: Action?
    let category: Category?

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        return df
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: category?.colorHex ?? "#808080"))
                    .frame(width: 10, height: 10)
                Text(action?.title ?? "Untitled")
                    .font(.body).bold()
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(victory.minutes) min")
                    .font(.body).bold()
                    .foregroundColor(Theme.success)
            }
            HStack {
                Text(category?.title ?? "Uncategorized")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text(Self.timeFormatter.string(from: victory.date))
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
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

#Preview {
    NavigationView {
        MainView()
            .environmentObject(AppViewModel())
    }
}


