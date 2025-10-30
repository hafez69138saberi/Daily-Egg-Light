import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if appViewModel.achievements.isEmpty {
                    Text("No achievements")
                        .foregroundColor(Theme.textSecondary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.cardBackground)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .padding(.vertical, 4)
                } else {
                    ForEach(appViewModel.achievements, id: \.id) { achievement in
                        AchievementRow(achievement: achievement)
                            .padding(12)
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
        .navigationTitle("Achievements")
    }
}

private struct AchievementRow: View {
    let achievement: Achievement

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(achievement.isUnlocked ? "egg" : "egg")
                .foregroundColor(achievement.isUnlocked ? Theme.bronze : Theme.textSecondary)
                .imageScale(.large)
                .shadow(color: achievement.isUnlocked ? Theme.bronze : Theme.textSecondary, radius: 2, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(achievement.title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    StatusBadge(isUnlocked: achievement.isUnlocked)
                }
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(16)
    }
}

private struct StatusBadge: View {
    let isUnlocked: Bool
    var body: some View {
        Text(isUnlocked ? "Unlocked" : "Locked")
            .font(.caption).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isUnlocked ? Theme.success.opacity(0.25) : Theme.cardBackground.opacity(0.5))
            .foregroundColor(isUnlocked ? Theme.success : Theme.textSecondary)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationView {
        AchievementsView()
            .environmentObject(AppViewModel())
    }
}


