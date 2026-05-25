import PhotosUI
import SwiftUI
import UIKit

struct SetupAuthScreen: View {
    @StateObject var viewModel: SetupAuthVM
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isCameraShowing = false
    @State private var isPhotoPickerShowing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Menu {
                            photoPickerMenuItems
                        } label: {
                            avatarPreview
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 6) {
                            Text("Давай завершимо сетап акаунта")
                                .font(.title2.weight(.bold))
                                .multilineTextAlignment(.center)

                            Text("Введіть ім'я та оберіть фото профілю.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ім'я")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        AuthTextField(
                            title: "Ваше ім'я",
                            text: $viewModel.name,
                            contentType: .name,
                            textInputAutocapitalization: .words,
                            submitLabel: .done,
                            onSubmit: viewModel.saveProfile
                        )
                    }

                    VStack(spacing: 16) {
                        Text("Налаштувати фото профіля")
                            .font(.headline)

                        HStack(spacing: 22) {
                            Menu {
                                photoPickerMenuItems
                            } label: {
                                ProfilePhotoActionButton(systemImage: "photo.badge.arrow.down.fill")
                            }
                            .buttonStyle(.plain)

                            Button {
                                viewModel.selectDefaultAvatar()
                            } label: {
                                ProfilePhotoActionButton(systemImage: "person.circle")
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    PrimaryButton(
                        title: viewModel.isLoading ? "Зберігаємо..." : "Завершити",
                        style: .primaryWhiteText,
                        action: viewModel.saveProfile
                    )
                    .disabled(!viewModel.canSave)
                    .opacity(viewModel.canSave ? 1 : 0.55)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 36)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
        }
        .interactiveDismissDisabled()
        .onChange(of: selectedPhotoItem) { item in
            loadSelectedPhoto(item)
        }
        .photosPicker(isPresented: $isPhotoPickerShowing, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                viewModel.signOutIfIncomplete()
            }
        }
        .sheet(isPresented: $isCameraShowing) {
            CameraPicker { image in
                viewModel.selectImage(image)
            }
            .ignoresSafeArea()
        }
        .alert("Помилка", isPresented: Binding(get: {
            viewModel.alertMessage != nil
        }, set: { newValue in
            if !newValue { viewModel.alertMessage = nil }
        }), actions: {
            Button("OK") { viewModel.alertMessage = nil }
        }, message: {
            Text(viewModel.alertMessage ?? "")
        })
    }

    @ViewBuilder
    private var photoPickerMenuItems: some View {
        Button {
            isCameraShowing = true
        } label: {
            Label("Сфотографувати", systemImage: "camera.fill")
        }
        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

        Button {
            isPhotoPickerShowing = true
        } label: {
            Label("Обрати в галереї", systemImage: "photo.on.rectangle.angled")
        }
    }

    private var avatarPreview: some View {
        Group {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .padding(12)
            }
        }
        .frame(width: 112, height: 112)
        .clipShape(Circle())
        .background(Circle().fill(.thinMaterial))
        .overlay(Circle().strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1))
        .contentShape(Circle())
        .accessibilityLabel("Змінити фото профілю")
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            do {
                guard
                    let data = try await item.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else {
                    viewModel.alertMessage = "Не вдалося прочитати фото."
                    return
                }
                viewModel.selectImage(image)
            } catch {
                viewModel.alertMessage = error.localizedDescription
            }
        }
    }
}

private struct ProfilePhotoActionButton: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 68, height: 68)
            .background(.thinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(Color.secondary.opacity(0.18), lineWidth: 1))
    }
}

#Preview {
    SetupAuthScreen(viewModel: SetupAuthVM())
}
