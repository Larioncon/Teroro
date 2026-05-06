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

            Section {
                HStack {
                    Spacer(minLength: 0)
                    Button {
                        viewModel.signOut()
                    } label: {
                        Text("Вийти")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(.thinMaterial, in: Capsule(style: .continuous))
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.red.opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 0)
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Налаштування")
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: scenePhase) { newPhase in
            viewModel.onScenePhaseChanged(newPhase)
        }
        .alert("Помилка", isPresented: Binding(get: {
            viewModel.signOutErrorMessage != nil
        }, set: { newValue in
            if !newValue { viewModel.signOutErrorMessage = nil }
        }), actions: {
            Button("OK") { viewModel.signOutErrorMessage = nil }
        }, message: {
            Text(viewModel.signOutErrorMessage ?? "")
        })
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
