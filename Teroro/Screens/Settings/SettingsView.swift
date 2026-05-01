import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsVM
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List {
            Section {
                Toggle(isOn: $viewModel.isDarkMode) {
                    Label("Темна тема", systemImage: "moon.fill")
                }
            }

            Section {
                Button {
                    viewModel.openSystemSettings()
                } label: {
                    HStack {
                        Label("Сповіщення", systemImage: "bell.fill")
                        Spacer()
                        NotificationPermissionStatusIcon(
                            showingEnabled: viewModel.isNotificationStatusIconShowingEnabled,
                            rotation: viewModel.statusFlipRotation
                        )
                    }
                }

                Link(destination: viewModel.contactURL) {
                    Label("Контакти", systemImage: "person.crop.circle")
                }
            }
        }
        .navigationTitle("Налаштування")
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: scenePhase) { newPhase in
            viewModel.onScenePhaseChanged(newPhase)
        }
    }
}

private struct NotificationPermissionStatusIcon: View {
    let showingEnabled: Bool
    let rotation: Double

    var body: some View {
        ZStack {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .opacity(showingEnabled ? 1 : 0)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))

            Image(systemName: "xmark.seal.fill")
                .font(.title3)
                .foregroundStyle(.red)
                .opacity(showingEnabled ? 0 : 1)
                .rotation3DEffect(.degrees(rotation + 180), axis: (x: 0, y: 1, z: 0))
        }
        .animation(.easeInOut(duration: 0.35), value: rotation)
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsVM())
    }
}
