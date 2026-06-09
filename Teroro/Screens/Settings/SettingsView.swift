import PhotosUI
import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsVM
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isCameraShowing = false
    @State private var isPhotoPickerShowing = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Menu {
                        Button {
                            isCameraShowing = true
                        } label: {
                            Label("Сфотографировать", systemImage: "camera.fill")
                        }
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                        Button {
                            isPhotoPickerShowing = true
                        } label: {
                            Label("Выбрать в галерее", systemImage: "photo.on.rectangle.angled")
                        }
                    } label: {
                        ZStack {
                            UserAvatarView(avatarURL: viewModel.currentUser?.avatarURL, size: 64)
                                .opacity(viewModel.isAvatarUpdating ? 0.45 : 1)

                            if viewModel.isAvatarUpdating {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.currentUser?.name ?? "Профіль")
                            .font(.headline)
                            .lineLimit(1)

                        Text(viewModel.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        PremiumStatusPill(isPremium: subscriptionService.isPremium)
                    }
                }
                .padding(.vertical, 6)
            }

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

            }

            Section {
                Button {
                    viewModel.openFeedback()
                } label: {
                    Label("Написати фідбек", systemImage: "envelope.fill")
                }

                if let appStoreURL = viewModel.appStoreURL {
                    ShareLink(item: appStoreURL) {
                        Label("Поділитися застосунком", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Label("Поділитися застосунком", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }

                Button {
                    viewModel.openTermsOfUse()
                } label: {
                    Label("Умови використання", systemImage: "doc.text")
                }
                .disabled(viewModel.termsURL == nil)

                Button {
                    viewModel.openPrivacyPolicy()
                } label: {
                    Label("Політика конфіденційності", systemImage: "hand.raised.fill")
                }
                .disabled(viewModel.privacyURL == nil)
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
        .onChange(of: selectedPhotoItem) { item in
            loadSelectedPhoto(item)
        }
        .photosPicker(isPresented: $isPhotoPickerShowing, selection: $selectedPhotoItem, matching: .images)
        .sheet(isPresented: $isCameraShowing) {
            CameraPicker { image in
                viewModel.updateAvatar(with: image)
            }
            .ignoresSafeArea()
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

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            do {
                guard
                    let data = try await item.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else {
                    viewModel.signOutErrorMessage = "Не вдалося прочитати фото."
                    return
                }
                viewModel.updateAvatar(with: image)
            } catch {
                viewModel.signOutErrorMessage = error.localizedDescription
            }
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

private struct PremiumStatusPill: View {
    let isPremium: Bool

    var body: some View {
        Text(isPremium ? "Pro Mode" : "Non Pro")
            .font(.caption.weight(.semibold))
            .foregroundStyle(isPremium ? .green : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isPremium ? Color.green.opacity(0.14) : Color.secondary.opacity(0.12), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(isPremium ? Color.green.opacity(0.35) : Color.secondary.opacity(0.2), lineWidth: 1)
            }
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsVM())
    }
}
