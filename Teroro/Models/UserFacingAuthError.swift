import Foundation
import FirebaseAuth

/// A user-friendly representation of Firebase Auth errors.
///
/// This type is intended for UI (alerts/toasts) and uses `NSLocalizedString` for easy localization.
/// Add new cases as your UX grows; the mapping is centralized in `init(from:)`.
enum UserFacingAuthError: LocalizedError, Equatable {
    // MARK: - Common Auth Errors

    /// Maps: `.invalidEmail`
    case invalidEmail

    /// Maps: `.wrongPassword`
    case wrongPassword

    /// Maps: `.userNotFound`
    case userNotFound

    /// Maps: `.emailAlreadyInUse`
    case emailAlreadyInUse

    /// Maps: `.weakPassword`
    case weakPassword

    /// Maps: `.userDisabled`
    case userDisabled

    /// Maps: `.networkError`
    case networkError

    /// Maps: `.tooManyRequests`
    case tooManyRequests

    /// Maps: `.operationNotAllowed`
    case operationNotAllowed

    /// Maps: `.requiresRecentLogin`
    case requiresRecentLogin

    /// Maps: `.invalidCredential`
    case invalidCredentials

    // MARK: - Phone/Verification Related

    /// Maps: `.invalidVerificationCode`, `.missingVerificationCode`
    case verificationCodeInvalidOrMissing

    /// Maps: `.sessionExpired`
    case verificationExpired

    // MARK: - Credential/Provider Related

    /// Maps: `.accountExistsWithDifferentCredential`
    case accountExistsWithDifferentCredential

    /// Maps: `.credentialAlreadyInUse`
    case credentialAlreadyInUse

    /// Maps: `.providerAlreadyLinked`
    case providerAlreadyLinked

    // MARK: - Flow Related

    /// Maps: `.userTokenExpired`, `.invalidUserToken`
    case sessionInvalid

    /// Used when the user cancels an external sign-in flow (e.g. Google Sign-In sheet).
    /// Note: not always an `AuthErrorCode`; may come from provider SDKs.
    case cancelled

    /// Fallback for any technical error we don't want to expose directly.
    case generic

    // MARK: - Init / Mapping

    init(from error: Error) {
        // Avoid double-wrapping when errors are already user-facing.
        if let existing = error as? UserFacingAuthError {
            self = existing
            return
        }

        // Prefer Firebase Auth mapping when possible.
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain || nsError.domain == "FIRAuthErrorDomain" {
            // Depending on FirebaseAuth version, bridging can fail; keep a robust fallback.
            if let authError = AuthErrorCode(_bridgedNSError: nsError) {
                switch authError.code {
            case .invalidEmail:
                self = .invalidEmail
            case .wrongPassword:
                self = .wrongPassword
            case .userNotFound:
                self = .userNotFound
            case .emailAlreadyInUse:
                self = .emailAlreadyInUse
            case .weakPassword:
                self = .weakPassword
            case .userDisabled:
                self = .userDisabled
            case .networkError:
                self = .networkError
            case .tooManyRequests:
                self = .tooManyRequests
            case .operationNotAllowed:
                self = .operationNotAllowed
            case .requiresRecentLogin:
                self = .requiresRecentLogin
            case .invalidCredential:
                self = .invalidCredentials

            case .invalidVerificationCode, .missingVerificationCode:
                self = .verificationCodeInvalidOrMissing
            case .sessionExpired:
                self = .verificationExpired

            case .accountExistsWithDifferentCredential:
                self = .accountExistsWithDifferentCredential
            case .credentialAlreadyInUse:
                self = .credentialAlreadyInUse
            case .providerAlreadyLinked:
                self = .providerAlreadyLinked

            case .userTokenExpired, .invalidUserToken:
                self = .sessionInvalid

            default:
                self = .generic
            }
            return
            } else if let fallback = Self.fallbackFromFirebaseCode(nsError.code) {
                self = fallback
                return
            } else {
                self = .generic
                return
            }
        }

        // Best-effort mapping for non-Firebase provider cancellations.
        if nsError.domain == NSCocoaErrorDomain, nsError.code == NSUserCancelledError {
            self = .cancelled
            return
        }

        self = .generic
    }

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return Self.l(
                "auth.error.invalid_email",
                defaultValue: "Перевірте адресу електронної пошти та спробуйте ще раз.",
                comment: "Shown when user enters an invalid email address."
            )
        case .wrongPassword:
            return Self.l(
                "auth.error.wrong_password",
                defaultValue: "Невірний пароль. Спробуйте ще раз або відновіть пароль.",
                comment: "Shown when password is incorrect."
            )
        case .userNotFound:
            return Self.l(
                "auth.error.user_not_found",
                defaultValue: "Ми не знайшли акаунт з цією електронною поштою.",
                comment: "Shown when no user exists for given email."
            )
        case .emailAlreadyInUse:
            return Self.l(
                "auth.error.email_in_use",
                defaultValue: "Ця електронна пошта вже використовується. Увійдіть або відновіть пароль.",
                comment: "Shown when trying to sign up with an email that already exists."
            )
        case .weakPassword:
            return Self.l(
                "auth.error.weak_password",
                defaultValue: "Пароль занадто простий. Спробуйте зробити його складнішим.",
                comment: "Shown when password doesn't meet Firebase minimum strength."
            )
        case .userDisabled:
            return Self.l(
                "auth.error.user_disabled",
                defaultValue: "Цей акаунт вимкнено. Зверніться до підтримки.",
                comment: "Shown when user account is disabled."
            )
        case .networkError:
            return Self.l(
                "auth.error.network",
                defaultValue: "Немає зʼєднання з інтернетом. Перевірте мережу та спробуйте ще раз.",
                comment: "Shown on network connectivity errors."
            )
        case .tooManyRequests:
            return Self.l(
                "auth.error.too_many_requests",
                defaultValue: "Забагато спроб. Зачекайте трохи та повторіть.",
                comment: "Shown when Firebase throttles requests due to too many attempts."
            )
        case .operationNotAllowed:
            return Self.l(
                "auth.error.operation_not_allowed",
                defaultValue: "Цей спосіб входу наразі недоступний. Спробуйте інший метод.",
                comment: "Shown when sign-in method is not enabled in Firebase console."
            )
        case .requiresRecentLogin:
            return Self.l(
                "auth.error.requires_recent_login",
                defaultValue: "Для цієї дії потрібно повторно увійти в акаунт.",
                comment: "Shown when Firebase requires a recent login for sensitive actions."
            )
        case .invalidCredentials:
            return Self.l(
                "auth.error.invalid_credentials",
                defaultValue: "Невірні дані для входу. Перевірте email та пароль.",
                comment: "Shown on invalid credentials (email/password or provider credential)."
            )
        case .verificationCodeInvalidOrMissing:
            return Self.l(
                "auth.error.verification_code_invalid",
                defaultValue: "Невірний код підтвердження. Спробуйте ще раз.",
                comment: "Shown when verification code is invalid or missing."
            )
        case .verificationExpired:
            return Self.l(
                "auth.error.verification_expired",
                defaultValue: "Код підтвердження прострочений. Запросіть новий код.",
                comment: "Shown when verification session/code is expired."
            )
        case .accountExistsWithDifferentCredential:
            return Self.l(
                "auth.error.account_exists_different_credential",
                defaultValue: "Ця електронна пошта вже привʼязана до іншого способу входу. Спробуйте увійти іншим методом.",
                comment: "Shown when account exists with different provider credential."
            )
        case .credentialAlreadyInUse:
            return Self.l(
                "auth.error.credential_already_in_use",
                defaultValue: "Ці дані входу вже використовуються іншим акаунтом.",
                comment: "Shown when a credential is already linked to another user."
            )
        case .providerAlreadyLinked:
            return Self.l(
                "auth.error.provider_already_linked",
                defaultValue: "Цей спосіб входу вже привʼязаний до вашого акаунта.",
                comment: "Shown when provider is already linked."
            )
        case .sessionInvalid:
            return Self.l(
                "auth.error.session_invalid",
                defaultValue: "Сесію завершено. Увійдіть знову.",
                comment: "Shown when user token is invalid/expired."
            )
        case .cancelled:
            return Self.l(
                "auth.error.cancelled",
                defaultValue: "Дію скасовано.",
                comment: "Shown when user cancels the sign-in flow."
            )
        case .generic:
            return Self.l(
                "auth.error.generic",
                defaultValue: "Не вдалося виконати дію. Спробуйте ще раз пізніше.",
                comment: "Fallback for unknown/technical errors."
            )
        }
    }

    // MARK: - Helpers

    private static func l(_ key: String, defaultValue: String, comment: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .main, value: defaultValue, comment: comment)
    }

    /// Fallback mapping using Firebase Auth numeric error codes (stable across SDK versions).
    /// This exists because `AuthErrorCode(_bridgedNSError:)` can return `nil` in some setups.
    private static func fallbackFromFirebaseCode(_ code: Int) -> UserFacingAuthError? {
        // Values are Firebase Auth error codes (e.g. 17007 = emailAlreadyInUse).
        // Keep this list minimal and focused on user-facing flows.
        switch code {
        case 17008: return .invalidEmail
        case 17009: return .wrongPassword
        case 17011: return .userNotFound
        case 17007: return .emailAlreadyInUse
        case 17026: return .weakPassword
        case 17005: return .userDisabled
        case 17020: return .networkError
        case 17010: return .tooManyRequests
        case 17006: return .operationNotAllowed
        case 17014: return .requiresRecentLogin
        case 17004: return .invalidCredentials
        case 17012: return .accountExistsWithDifferentCredential
        case 17025: return .credentialAlreadyInUse
        case 17015: return .providerAlreadyLinked
        case 17021, 17017: return .sessionInvalid // userTokenExpired / invalidUserToken (seen across versions)
        default:
            return nil
        }
    }
}
