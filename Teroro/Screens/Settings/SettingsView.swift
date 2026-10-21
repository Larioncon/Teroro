import PhotosUI
import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsVM
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isCameraShowing = false
    @State private var isPhotoPickerShowing = false
    @FocusState private var isNameFieldFocused: Bool
    let onShowPaywall: () -> Void
    let onShowAppearance: () -> Void
    let onShowPrivacyAndSecurity: () -> Void
    let onShowLanguages: () -> Void
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Menu {
                        Button {
                            isCameraShowing = true
                        } label: {
                            Label(languageManager.localizedString(forKey: "settings_take_photo"), systemImage: "camera.fill")
                        }
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                        Button {
                            isPhotoPickerShowing = true
                        } label: {
                            Label(languageManager.localizedString(forKey: "settings_choose_gallery"), systemImage: "photo.on.rectangle.angled")
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
                        if viewModel.isEditingName {
                            HStack(spacing: 6) {
                                TextField(languageManager.localizedString(forKey: "settings_name_placeholder"), text: $viewModel.editedName)
                                    .font(.headline)
                                    .textFieldStyle(.plain)
                                    .frame(height: 22)
                                    .padding(.horizontal, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(uiColor: .tertiarySystemFill))
                                    )
                                    .focused($isNameFieldFocused)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        viewModel.saveEditedName()
                                    }
                                    .disabled(viewModel.isNameUpdating)

                                if viewModel.isNameUpdating {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Button {
                                        viewModel.saveEditedName()
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(viewModel.editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                    Button {
                                        viewModel.cancelEditingName()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 22)
                        } else {
                            Menu {
                                Button {
                                    viewModel.startEditingName()
                                } label: {
                                    Label(languageManager.localizedString(forKey: "settings_edit"), systemImage: "pencil")
                                }
                            } label: {
                                AutoScrollText(
                                    text: viewModel.currentUser?.name ?? languageManager.localizedString(forKey: "settings_profile"),
                                    font: .preferredFont(forTextStyle: .headline),
                                    textColor: .label
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    viewModel.startEditingName()
                                } label: {
                                    Label(languageManager.localizedString(forKey: "settings_edit"), systemImage: "pencil")
                                }
                            }
                        }

                        if let email = viewModel.currentUser?.email, !email.isEmpty {
                            AutoScrollText(
                                text: email,
                                font: .preferredFont(forTextStyle: .subheadline),
                                textColor: .secondaryLabel
                            )
                        }

                        PremiumStatusPill(isPremium: viewModel.isPremium)
                    }
                }
                .padding(.vertical, 6)
            }

            if !viewModel.isPremium {
                Section {
                    Button {
                        onShowPaywall()
                    } label: {
                        HStack {
                            Label("Timexo Premium", systemImage: "star.fill")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .font(.footnote.bold())
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            Section {
                Button {
                    viewModel.openSystemSettings()
                } label: {
                    HStack {
                        Label(languageManager.localizedString(forKey: "settings_notifications"), systemImage: "bell.fill")
                        Spacer()
                        NotificationPermissionStatusIcon(
                            showingEnabled: viewModel.isNotificationStatusIconShowingEnabled,
                            rotation: viewModel.statusFlipRotation
                        )
                    }
                }

                Button {
                    onShowLanguages()
                } label: {
                    HStack {
                        Label(languageManager.localizedString(forKey: "settings_language"), systemImage: "globe")
                        Spacer()
                        Text(languageManager.currentLanguage.nativeName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.forward")
                            .font(.footnote.bold())
                            .foregroundColor(.gray)
                    }
                }

                Button {
                    onShowAppearance()
                } label: {
                    HStack {
                        Label(languageManager.localizedString(forKey: "settings_appearance"), systemImage: "circle.lefthalf.filled")
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .font(.footnote.bold())
                            .foregroundColor(.gray)
                    }
                }

                Button {
                    onShowPrivacyAndSecurity()
                } label: {
                    HStack {
                        Label(languageManager.localizedString(forKey: "settings_privacy_and_security"), systemImage: "lock.shield.fill")
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .font(.footnote.bold())
                            .foregroundColor(.gray)
                    }
                }
            }

            Section {
                Button {
                    viewModel.openFeedback()
                } label: {
                    Label(languageManager.localizedString(forKey: "settings_feedback"), systemImage: "envelope.fill")
                }

                if let appStoreURL = viewModel.appStoreURL {
                    ShareLink(item: appStoreURL) {
                        Label(languageManager.localizedString(forKey: "settings_share"), systemImage: "square.and.arrow.up")
                    }
                } else {
                    Label(languageManager.localizedString(forKey: "settings_share"), systemImage: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }

                Button {
                    viewModel.openTermsOfUse()
                } label: {
                    Label(languageManager.localizedString(forKey: "settings_terms_of_use"), systemImage: "doc.text")
                }
                .disabled(viewModel.termsURL == nil)

                Button {
                    viewModel.openPrivacyPolicy()
                } label: {
                    Label(languageManager.localizedString(forKey: "settings_privacy_policy"), systemImage: "hand.raised.fill")
                }
                .disabled(viewModel.privacyURL == nil)
            }

            Section {
                HStack {
                    Spacer(minLength: 0)
                    Button {
                        viewModel.signOut()
                    } label: {
                        Text(languageManager.localizedString(forKey: "settings_sign_out"))
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
        .navigationTitle(languageManager.localizedString(forKey: "settings_title"))
        .background {
            MinimalBackButtonConfigurator()
                .frame(width: 0, height: 0)
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: scenePhase) { newPhase in
            viewModel.onScenePhaseChanged(newPhase)
        }
        .onChange(of: selectedPhotoItem) { item in
            viewModel.loadSelectedPhoto(item)
        }
        .onChange(of: viewModel.isEditingName) { isEditing in
            isNameFieldFocused = isEditing
        }
        .photosPicker(isPresented: $isPhotoPickerShowing, selection: $selectedPhotoItem, matching: .images)
        .sheet(isPresented: $isCameraShowing) {
            CameraPicker { image in
                viewModel.updateAvatar(with: image)
            }
            .ignoresSafeArea()
        }
        .alert(languageManager.localizedString(forKey: "common_error"), isPresented: Binding(get: {
            viewModel.signOutErrorMessage != nil
        }, set: { newValue in
            if !newValue { viewModel.signOutErrorMessage = nil }
        }), actions: {
            Button(languageManager.localizedString(forKey: "common_ok")) { viewModel.signOutErrorMessage = nil }
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
