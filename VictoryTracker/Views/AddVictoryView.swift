import SwiftUI

struct AddVictoryView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.presentationMode) private var presentation

    @State private var selectedCategoryId: UUID? = nil
    @State private var selectedActionId: UUID? = nil
    @State private var minutes: Int = 30
    @State private var date: Date = Date()

    @State private var isAddingNewAction: Bool = false
    @State private var newActionTitle: String = ""

    private var filteredActions: [Action] {
        guard let categoryId = selectedCategoryId else { return [] }
        return appViewModel.actions.filter { $0.categoryId == categoryId }
    }

    private var isSaveDisabled: Bool {
        guard let _ = selectedCategoryId, let _ = selectedActionId, minutes > 0 else { return true }
        return false
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        if appViewModel.categories.isEmpty {
                            Text("No categories. Add a category in the app.")
                                .foregroundColor(Theme.textSecondary)
                        } else {
                            Picker("Category", selection: Binding(get: {
                                selectedCategoryId ?? appViewModel.categories.first?.id
                            }, set: { newValue in
                                selectedCategoryId = newValue
                                if filteredActions.contains(where: { $0.id == selectedActionId }) == false {
                                    selectedActionId = filteredActions.first?.id
                                }
                            })) {
                                ForEach(appViewModel.categories, id: \.id) { category in
                                    Text(category.title).tag(Optional(category.id))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.cardBackground)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Action")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        if isAddingNewAction {
                            HStack {
                                TextField("Action name", text: $newActionTitle)
                                Button("Add") {
                                    guard let categoryId = selectedCategoryId else { return }
                                    let title = newActionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard title.isEmpty == false else { return }
                                    let created = appViewModel.addAction(title: title, categoryId: categoryId)
                                    selectedActionId = created.id
                                    newActionTitle = ""
                                    isAddingNewAction = false
                                }
                                .foregroundColor(Theme.accent)
                                .disabled(newActionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        } else if filteredActions.isEmpty == false {
                            Picker("Action", selection: Binding(get: {
                                selectedActionId ?? filteredActions.first?.id
                            }, set: { selectedActionId = $0 })) {
                                ForEach(filteredActions, id: \.id) { action in
                                    Text(action.title).tag(Optional(action.id))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            Button("Add new action") { isAddingNewAction = true }
                                .foregroundColor(Theme.accent)
                        } else {
                            Text("No actions for category")
                                .foregroundColor(Theme.textSecondary)
                            Button("Add new action") { isAddingNewAction = true }
                                .foregroundColor(Theme.accent)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.cardBackground)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        Stepper(value: $minutes, in: 1...24*60) {
                            Text("Minutes: \(minutes)")
                                .foregroundColor(Theme.textPrimary)
                        }
                        DatePicker("Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.cardBackground)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
            }
            .background(Theme.primaryBackground.ignoresSafeArea())
            .foregroundColor(Theme.textPrimary)
            .navigationBarTitle("New Victory", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Close") { presentation.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    guard let categoryId = selectedCategoryId, let actionId = selectedActionId else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.2)) {
                        _ = appViewModel.addVictory(minutes: minutes, categoryId: categoryId, actionId: actionId, date: date)
                    }
                    appViewModel.showToast("Victory saved")
                    presentation.wrappedValue.dismiss()
                }.disabled(isSaveDisabled)
            )
            .onAppear {
                if selectedCategoryId == nil {
                    selectedCategoryId = appViewModel.categories.first?.id
                }
                if selectedActionId == nil {
                    selectedActionId = filteredActions.first?.id
                }
            }
        }
    }
}

#Preview {
    AddVictoryView()
        .environmentObject(AppViewModel())
}

