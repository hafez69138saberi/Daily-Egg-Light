import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var isPresentingAdd = false

    private func victoriesCount(for category: Category) -> Int {
        appViewModel.victories.filter { $0.categoryId == category.id }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if appViewModel.categories.isEmpty {
                    Text("No categories")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(Theme.textSecondary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.cardBackground)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .padding(.vertical, 4)
                } else {
                    ForEach(appViewModel.categories, id: \.id) { category in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 12, height: 12)
                            Text(category.title)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(victoriesCount(for: category))")
                                .foregroundColor(Theme.success)
                            Button(action: { deleteCategory(category.id) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.cardBackground)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .padding(.vertical, 4)
                    }
                }

                Button(action: { isPresentingAdd = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add category")
                    }
                    .foregroundColor(Theme.accent)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.cardBackground)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.primaryBackground.ignoresSafeArea())
        .foregroundColor(Theme.textPrimary)
        .navigationTitle("Categories")
        .sheet(isPresented: $isPresentingAdd) {
            AddCategorySheet(isPresented: $isPresentingAdd)
                .environmentObject(appViewModel)
        }
    }

    private func deleteCategory(_ id: UUID) {
        appViewModel.removeCategory(id: id)
    }
}

private struct AddCategorySheet: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Binding var isPresented: Bool

    @State private var title: String = ""
    @State private var selectedHex: String = "#FF6B6B"

    private let presets: [String] = [
        "#FF6B6B",
        "#F7B267",
        "#FFD166",
        "#06D6A0",
        "#4ECDC4",
        "#118AB2",
        "#7C4DFF",
        "#BDBDBD"
    ]

    private var isSaveDisabled: Bool { title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        TextField("Category name", text: $title)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.cardBackground)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                            ForEach(presets, id: \.self) { hex in
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 36, height: 36)
                                    if hex == selectedHex {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                    }
                                }
                                .onTapGesture { selectedHex = hex }
                                .accessibilityLabel(Text(hex))
                            }
                        }
                        .padding(.vertical, 4)
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
            .navigationBarTitle("New Category", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Save") {
                    let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard name.isEmpty == false else { return }
                    _ = appViewModel.addCategory(title: name, colorHex: selectedHex)
                    isPresented = false
                }.disabled(isSaveDisabled)
            )
        }
    }
}

#Preview {
    NavigationView {
        CategoriesView()
            .environmentObject(AppViewModel())
    }
}


