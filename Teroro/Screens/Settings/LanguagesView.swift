import SwiftUI

struct LanguagesView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var loadingLanguage: AppLanguage? = nil

    var body: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        selectLanguage(language)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(language.displayName)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text(language.nativeName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if loadingLanguage == language {
                                ProgressView()
                                    .tint(Color.primaryColor)
                            } else if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(Color.primaryColor)
                            }
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(loadingLanguage != nil)
                }
            } header: {
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localizedString(forKey: "language.header.description"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .textCase(.none)
                        .padding(.top, 4)

                    Text(languageManager.localizedString(forKey: "language.section.interface"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(languageManager.localizedString(forKey: "language.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func selectLanguage(_ language: AppLanguage) {
        guard language != languageManager.currentLanguage, loadingLanguage == nil else { return }

        loadingLanguage = language
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    languageManager.setLanguage(language)
                    loadingLanguage = nil
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LanguagesView()
    }
}
