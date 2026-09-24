import Combine
import LocalAuthentication
import PhotosUI
import SwiftUI
import UserNotifications
import UIKit

@MainActor
final class SettingsVM: ObservableObject {
    @AppStorage("appAppearance") private var appearanceRawValue: Int = AppAppearance.system.rawValue
    @AppStorage("isFaceIDEnabled") var isFaceIDEnabled: Bool = false
    @AppStorage("isPasscodeEnabled") var isPasscodeEnabled: Bool = false
    @AppStorage("userPasscode") var userPasscode: String = ""
    @AppStorage("passcodeAutoLockInterval") var passcodeAutoLockInterval: Double = PasscodeAutoLockOption.oneMinute.rawValue

    var appearance: AppAppearance {
        get { AppAppearance(rawValue: appearanceRawValue) ?? .system }
        set { appearanceRawValue = newValue.rawValue }
    }

    private let authService: FirebaseAuthService
    private let profileService: UserProfileService
    private let avatarCache: UserAvatarCache
    private let appState: AppState

    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var statusFlipRotation: Double = 0
    @Published private(set) var currentUser: UserData?
    @Published private(set) var linkedProviderIDs: [String] = []
    @Published private(set) var isAvatarUpdating = false
    @Published private(set) var isNameUpdating = false
    @Published var isEditingName = false
    @Published var editedName = ""
    @Published private(set) var isPremium = false
    @Published var signOutErrorMessage: String?

    @Published var isChangePasswordSheetPresented = false
    @Published var isAddEmailPasswordSheetPresented = false
    @Published var isChangeEmailSheetPresented = false
    @Published var isPasscodeSheetPresented = false
    @Published var isDeleteAccountSheetPresented = false
    @Published var isPasscodeDisableRequiredAlertPresented = false
    @Published var securityAlertMessage: String?
    @Published var securitySuccessMessage: String?
    @Published var isSecurityProcessing = false

    private var cancellables: Set<AnyCancellable> = []

    var isNotificationsEnabled: Bool {
        notificationStatus == .authorized || notificationStatus == .provisional
    }

    init(
        authService: FirebaseAuthService? = nil,
        profileService: UserProfileService = .shared,
        avatarCache: UserAvatarCache? = nil,
        appState: AppState = .shared
    ) {
        let authService = authService ?? FirebaseAuthService.shared
        self.authService = authService
        self.profileService = profileService
        self.avatarCache = avatarCache ?? .shared
        self.appState = appState
        self.currentUser = authService.currentUser
        self.linkedProviderIDs = authService.linkedProviderIDs
        self.isPremium = SubscriptionService.shared.isPremium
        migrateLegacyThemeIfNeeded()

        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)

        authService.$linkedProviderIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                self?.linkedProviderIDs = ids
            }
            .store(in: &cancellables)

        SubscriptionService.shared.$isPremium
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium in
                self?.isPremium = isPremium
            }
            .store(in: &cancellables)
    }

    // MARK: - View Events

    func onAppear() {
        Task { await refreshNotificationStatus(animated: false) }
    }

    func onScenePhaseChanged(_ newPhase: ScenePhase) {
        guard newPhase == .active else { return }
        Task { await refreshNotificationStatus(animated: true) }
    }

    // MARK: - UI State

    var isNotificationStatusIconShowingEnabled: Bool {
        // When the icon flips, keep the "front" face consistent through the rotation.
        let angle = statusFlipRotation.truncatingRemainder(dividingBy: 360)
        return (angle < 90) || (angle > 270)
    }

    var contactURL: URL {
        URL(string: AppConstants.contactUsLink) ?? URL(string: "https://sites.google.com/view/0047coslw")!
    }

    var termsURL: URL? {
        URL(string: AppConstants.termsOfUseLink)
    }

    var privacyURL: URL? {
        URL(string: AppConstants.privacyPolicyLink)
    }

    var appStoreURL: URL? {
        URL(string: AppConstants.appStoreLink)
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func openTermsOfUse() {
        guard let url = termsURL else { return }
        UIApplication.shared.open(url)
    }

    func openPrivacyPolicy() {
        guard let url = privacyURL else { return }
        UIApplication.shared.open(url)
    }

    func openFeedback() {
        // Prefer email, fallback to contact page.
        let email = AppConstants.contactUsEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !email.isEmpty,
           let url = URL(string: "mailto:\(email)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }

        UIApplication.shared.open(contactURL)
    }

    func signOut() {
        signOutErrorMessage = nil
        isFaceIDEnabled = false
        isPasscodeEnabled = false
        userPasscode = ""
        WidgetDataWriter.clear()
        appState.pendingDeepLink = nil
        do {
            try authService.signOut()
        } catch {
            signOutErrorMessage = error.localizedDescription
        }
    }

//    func showPaywall() {
//        appState.presentPaywall()
//    }

    func updateAvatar(with image: UIImage) {
        signOutErrorMessage = nil
        isAvatarUpdating = true

        Task {
            do {
                let user = try await profileService.updateAvatar(.image(image))
                avatarCache.store(image, for: user.avatarURL)
                currentUser = user
            } catch {
                signOutErrorMessage = error.localizedDescription
            }
            isAvatarUpdating = false
        }
    }

    func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            do {
                guard
                    let data = try await item.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else {
                    signOutErrorMessage = "Не вдалося прочитати фото."
                    return
                }
                updateAvatar(with: image)
            } catch {
                signOutErrorMessage = error.localizedDescription
            }
        }
    }

    func startEditingName() {
        editedName = currentUser?.name ?? ""
        isEditingName = true
    }

    func cancelEditingName() {
        isEditingName = false
        editedName = ""
    }

    func saveEditedName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            let success = await updateName(trimmed)
            if success {
                isEditingName = false
                editedName = ""
            }
        }
    }

    @discardableResult
    func updateName(_ newName: String) async -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        signOutErrorMessage = nil
        isNameUpdating = true
        defer { isNameUpdating = false }

        do {
            let user = try await profileService.updateName(trimmed)
            currentUser = user
            return true
        } catch {
            signOutErrorMessage = error.localizedDescription
            return false
        }
    }

    func refreshNotificationStatus(animated: Bool) async {
        let status = await UNUserNotificationCenter.current()
            .notificationSettings()
            .authorizationStatus

        let targetRotation = (status == .authorized || status == .provisional) ? 0.0 : 180.0

        if animated {
            withAnimation(.easeInOut(duration: 0.35)) {
                notificationStatus = status
                statusFlipRotation = targetRotation
            }
        } else {
            notificationStatus = status
            statusFlipRotation = targetRotation
        }
    }

    // MARK: - Privacy & Security

    var authProvider: AuthProvider {
        authService.getUserAuthProvider()
    }

    var hasPassword: Bool {
        linkedProviderIDs.contains("password")
    }

    var isAppleLinked: Bool {
        linkedProviderIDs.contains("apple.com")
    }

    var isGoogleLinked: Bool {
        linkedProviderIDs.contains("google.com")
    }

    var passcodeAutoLockOption: PasscodeAutoLockOption {
        get { PasscodeAutoLockOption(rawValue: passcodeAutoLockInterval) ?? .oneMinute }
        set { passcodeAutoLockInterval = newValue.rawValue }
    }

    func toggleFaceID(enabled: Bool) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = enabled ? "Підтвердіть Face ID для увімкнення" : "Підтвердіть Face ID для вимкнення"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                Task { @MainActor in
                    if success {
                        self.isFaceIDEnabled = enabled
                    } else {
                        self.isFaceIDEnabled = !enabled
                        if let authError = authError {
                            self.securityAlertMessage = authError.localizedDescription
                        }
                    }
                }
            }
        } else {
            isFaceIDEnabled = false
            securityAlertMessage = error?.localizedDescription ?? "Face ID не підтримується на цьому пристрої."
        }
    }

    func changePassword(newPassword: String, confirmPassword: String, currentPassword: String? = nil) async -> Bool {
        securityAlertMessage = nil
        securitySuccessMessage = nil

        let validation = AuthValidator.validatePasswordChange(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
            requiresCurrentPassword: hasPassword
        )

        switch validation {
        case .failure(let error):
            securityAlertMessage = error.errorDescription
            return false
        case .success:
            break
        }

        isSecurityProcessing = true
        defer { isSecurityProcessing = false }

        do {
            let hadPassword = hasPassword
            try await authService.changeUserPassword(
                newPassword: newPassword,
                currentPassword: currentPassword,
                emailForLinking: currentUser?.email
            )
            refreshLinkedProviders()
            securitySuccessMessage = hadPassword ? "Пароль успішно змінено." : "Пароль успішно створено."
            return true
        } catch {
            securityAlertMessage = UserFacingAuthError(from: error).errorDescription ?? error.localizedDescription
            return false
        }
    }

    func addEmailAndPassword(email: String, password: String, confirmPassword: String) async -> Bool {
        securityAlertMessage = nil
        securitySuccessMessage = nil

        let validation = AuthValidator.validateSignUp(
            email: email,
            password: password,
            confirmPassword: confirmPassword
        )

        let validEmail: String
        let validPassword: String

        switch validation {
        case .failure(let error):
            securityAlertMessage = error.errorDescription
            return false
        case .success(let valid):
            validEmail = valid.email
            validPassword = valid.password
        }

        isSecurityProcessing = true
        defer { isSecurityProcessing = false }

        do {
            try await authService.linkEmailPasswordToCurrentUser(email: validEmail, password: validPassword)
            refreshLinkedProviders()
            securitySuccessMessage = "Email та пароль успішно підключено."
            return true
        } catch {
            securityAlertMessage = UserFacingAuthError(from: error).errorDescription ?? error.localizedDescription
            return false
        }
    }

    func changeEmail(newEmail: String, currentPassword: String? = nil) async -> Bool {
        securityAlertMessage = nil
        securitySuccessMessage = nil

        let validation = AuthValidator.validateEmail(newEmail)
        let validEmail: String

        switch validation {
        case .failure(let error):
            securityAlertMessage = error.errorDescription
            return false
        case .success(let email):
            validEmail = email
        }

        isSecurityProcessing = true
        defer { isSecurityProcessing = false }

        do {
            try await authService.changeUserEmail(newEmail: validEmail, currentPassword: currentPassword)
            securitySuccessMessage = "Код підтвердження надіслано на новий email."
            return true
        } catch {
            securityAlertMessage = UserFacingAuthError(from: error).errorDescription ?? error.localizedDescription
            return false
        }
    }

    func confirmEmailChange(actionCode: String, expectedEmail: String) async -> Bool {
        securityAlertMessage = nil
        securitySuccessMessage = nil

        let trimmedCode = actionCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            securityAlertMessage = "Введіть код підтвердження."
            return false
        }

        isSecurityProcessing = true
        defer { isSecurityProcessing = false }

        do {
            try await authService.confirmUserEmailChange(actionCode: trimmedCode, expectedEmail: expectedEmail)
            securitySuccessMessage = "Email успішно змінено."
            return true
        } catch {
            securityAlertMessage = UserFacingAuthError(from: error).errorDescription ?? error.localizedDescription
            return false
        }
    }

    func linkAppleProvider() async -> Bool {
        securityAlertMessage = nil
        securitySuccessMessage = nil
        isSecurityProcessing = true
        defer { isSecurityProcessing = false }

        do {
            try await authService.linkAppleToCurrentUser()
            refreshLinkedProviders()
            securitySuccessMessage = "Apple Sign in підключено."
            return true
        } catch {
            securityAlertMessage = UserFacingAuthError(from: error).errorDescription ?? error.localizedDescription
            return false
        }
    }

    func linkGoogleProvider() async -> Bool {
        securityAlertMessage = nil
        securitySuccessMessage = nil
        isSecurityProcessing = true
        defer { isSecurityProcessing = false }

        do {
            try await authService.linkGoogleToCurrentUser()
            refreshLinkedProviders()
            securitySuccessMessage = "Google Sign in підключено."
            return true
        } catch {
            securityAlertMessage = UserFacingAuthError(from: error).errorDescription ?? error.localizedDescription
            return false
        }
    }

    func savePasscode(_ passcode: String) {
        securityAlertMessage = nil
        securitySuccessMessage = nil

        userPasscode = passcode
        isPasscodeEnabled = !passcode.isEmpty
        if passcode.isEmpty {
            isFaceIDEnabled = false
        }
        securitySuccessMessage = passcode.isEmpty ? "Код-пароль вимкнено." : "Код-пароль успішно збережено."
    }

    // MARK: - Account Deletion

    func initiateDeleteAccount() {
        securityAlertMessage = nil
        securitySuccessMessage = nil

        if isPasscodeEnabled || isFaceIDEnabled || !userPasscode.isEmpty {
            isPasscodeDisableRequiredAlertPresented = true
        } else {
            isDeleteAccountSheetPresented = true
        }
    }

    func deleteAccountWithPassword(password: String) async -> Bool {
        securityAlertMessage = nil
        securitySuccessMessage = nil

        guard !password.isEmpty else {
            securityAlertMessage = "Введіть пароль для підтвердження видалення."
            return false
        }

        isSecurityProcessing = true
        defer { isSecurityProcessing = false }

        do {
            try await authService.deleteAccountWithPassword(password: password)
            isFaceIDEnabled = false
            isPasscodeEnabled = false
            userPasscode = ""
            return true
        } catch {
            securityAlertMessage = UserFacingAuthError(from: error).errorDescription ?? error.localizedDescription
            return false
        }
    }

    func deleteAccountWithGoogle() async -> Bool {
        securityAlertMessage = nil
        securitySuccessMessage = nil

        isSecurityProcessing = true
        defer { isSecurityProcessing = false }

        do {
            try await authService.deleteAccountWithGoogle()
            isFaceIDEnabled = false
            isPasscodeEnabled = false
            userPasscode = ""
            return true
        } catch {
            securityAlertMessage = UserFacingAuthError(from: error).errorDescription ?? error.localizedDescription
            return false
        }
    }

    func deleteAccountWithApple() async -> Bool {
        securityAlertMessage = nil
        securitySuccessMessage = nil

        isSecurityProcessing = true
        defer { isSecurityProcessing = false }

        do {
            try await authService.deleteAccountWithApple()
            isFaceIDEnabled = false
            isPasscodeEnabled = false
            userPasscode = ""
            return true
        } catch {
            securityAlertMessage = UserFacingAuthError(from: error).errorDescription ?? error.localizedDescription
            return false
        }
    }

    // MARK: - Private

    private func migrateLegacyThemeIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "appAppearance") == nil else { return }
        guard defaults.object(forKey: "isDarkMode") != nil else { return }

        let wasDark = defaults.bool(forKey: "isDarkMode")
        appearanceRawValue = (wasDark ? AppAppearance.dark : AppAppearance.light).rawValue
    }

    private func refreshLinkedProviders() {
        linkedProviderIDs = authService.linkedProviderIDs
    }
}
