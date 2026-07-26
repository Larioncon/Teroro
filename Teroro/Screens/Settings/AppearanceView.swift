import SwiftUI
import UIKit

struct AppearanceView: View {
    @ObservedObject var viewModel: SettingsVM
    @State private var selectedAppIconName: String?
    @State private var supportsAlternateIcons = false
    @State private var appIconErrorMessage: String?
    @State private var isChangingAppIcon = false

    private let appIcons = AppIconOption.allCases

    var body: some View {
        List {
            Section {
                Picker("Режим", selection: Binding(get: {
                    viewModel.appearance
                }, set: { newValue in
                    viewModel.appearance = newValue
                })) {
                    ForEach(AppAppearance.allCases) { mode in
                        Label(mode.title, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                ForEach(appIcons) { icon in
                    Button {
                        setAppIcon(icon)
                    } label: {
                        HStack(spacing: 12) {
                            AppIconPreview(icon: icon)

                            Text(icon.title)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedAppIconName == icon.iconName {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.primaryColor)
                            }
                        }
                    }
                    .disabled(!supportsAlternateIcons || isChangingAppIcon || selectedAppIconName == icon.iconName)
                }
            } header: {
                Text("Іконка застосунку")
            } footer: {
                if !supportsAlternateIcons {
                    Text("Зміна іконки недоступна на цьому пристрої.")
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("Вид")
        .onAppear {
            selectedAppIconName = UIApplication.shared.alternateIconName
            supportsAlternateIcons = UIApplication.shared.supportsAlternateIcons
        }
        .alert("Не вдалося змінити іконку", isPresented: Binding(get: {
            appIconErrorMessage != nil
        }, set: { newValue in
            if !newValue { appIconErrorMessage = nil }
        }), actions: {
            Button("OK") { appIconErrorMessage = nil }
        }, message: {
            Text(appIconErrorMessage ?? "")
        })
    }

    private func setAppIcon(_ icon: AppIconOption) {
        guard supportsAlternateIcons else {
            appIconErrorMessage = "Пристрій не підтримує alternate app icons."
            return
        }

        guard selectedAppIconName != icon.iconName else { return }

        isChangingAppIcon = true
        UIApplication.shared.setAlternateIconName(icon.iconName) { error in
            DispatchQueue.main.async {
                isChangingAppIcon = false

                if let error {
                    appIconErrorMessage = error.localizedDescription
                } else {
                    selectedAppIconName = UIApplication.shared.alternateIconName
                }
            }
        }
    }
}

private enum AppIconOption: CaseIterable, Identifiable {
    case primary
    case green
    case purple

    var id: String { iconName ?? "primary" }

    var title: String {
        switch self {
        case .primary: return "Default"
        case .green: return "Logo G"
        case .purple: return "Logo P"
        }
    }

    var iconName: String? {
        switch self {
        case .primary: return nil
        case .green: return "logoG"
        case .purple: return "logoP"
        }
    }

    var previewImageName: String? {
        switch self {
        case .primary: return nil
        case .green: return "logoG"
        case .purple: return "logoP"
        }
    }
}

private struct AppIconPreview: View {
    let icon: AppIconOption

    var body: some View {
        Group {
            if let previewImageName = icon.previewImageName,
               let image = UIImage(named: previewImageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "app.fill")
                    .font(.title2)
                    .foregroundStyle(Color.primaryColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.primaryColor.opacity(0.14))
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
