import Foundation

/// Опис помилок валідації полів авторизації з локалізованими повідомленнями для користувача.
enum ValidationError: LocalizedError, Equatable {
    case emptyEmail
    case invalidEmailFormat
    case emptyPassword
    case passwordTooShort(min: Int)
    case passwordMissingUppercase
    case passwordMissingLowercase
    case passwordMissingDigit
    case emptyConfirmPassword
    case passwordsDoNotMatch
    case emptyCurrentPassword
    case custom(String)

    var errorDescription: String? {
        if Thread.isMainThread {
            return MainActor.assumeIsolated { localizedDescriptionOnMainActor }
        } else {
            return fallbackDescription
        }
    }

    @MainActor
    private var localizedDescriptionOnMainActor: String {
        switch self {
        case .emptyEmail:
            return LanguageManager.shared.localizedString(forKey: "validation_empty_email")
        case .invalidEmailFormat:
            return LanguageManager.shared.localizedString(forKey: "validation_invalid_email_format")
        case .emptyPassword:
            return LanguageManager.shared.localizedString(forKey: "validation_empty_password")
        case .passwordTooShort(let min):
            let format = LanguageManager.shared.localizedString(forKey: "validation_password_too_short")
            return String(format: format, min)
        case .passwordMissingUppercase:
            return LanguageManager.shared.localizedString(forKey: "validation_password_missing_uppercase")
        case .passwordMissingLowercase:
            return LanguageManager.shared.localizedString(forKey: "validation_password_missing_lowercase")
        case .passwordMissingDigit:
            return LanguageManager.shared.localizedString(forKey: "validation_password_missing_digit")
        case .emptyConfirmPassword:
            return LanguageManager.shared.localizedString(forKey: "validation_empty_confirm_password")
        case .passwordsDoNotMatch:
            return LanguageManager.shared.localizedString(forKey: "validation_passwords_do_not_match")
        case .emptyCurrentPassword:
            return LanguageManager.shared.localizedString(forKey: "validation_empty_current_password")
        case .custom(let message):
            return message
        }
    }

    private var fallbackDescription: String {
        switch self {
        case .emptyEmail:
            return LanguageManager.resolveString(forKey: "validation_empty_email", languageCode: LanguageManager.storedLanguageCode)
        case .invalidEmailFormat:
            return LanguageManager.resolveString(forKey: "validation_invalid_email_format", languageCode: LanguageManager.storedLanguageCode)
        case .emptyPassword:
            return LanguageManager.resolveString(forKey: "validation_empty_password", languageCode: LanguageManager.storedLanguageCode)
        case .passwordTooShort(let min):
            let format = LanguageManager.resolveString(forKey: "validation_password_too_short", languageCode: LanguageManager.storedLanguageCode)
            return String(format: format, min)
        case .passwordMissingUppercase:
            return LanguageManager.resolveString(forKey: "validation_password_missing_uppercase", languageCode: LanguageManager.storedLanguageCode)
        case .passwordMissingLowercase:
            return LanguageManager.resolveString(forKey: "validation_password_missing_lowercase", languageCode: LanguageManager.storedLanguageCode)
        case .passwordMissingDigit:
            return LanguageManager.resolveString(forKey: "validation_password_missing_digit", languageCode: LanguageManager.storedLanguageCode)
        case .emptyConfirmPassword:
            return LanguageManager.resolveString(forKey: "validation_empty_confirm_password", languageCode: LanguageManager.storedLanguageCode)
        case .passwordsDoNotMatch:
            return LanguageManager.resolveString(forKey: "validation_passwords_do_not_match", languageCode: LanguageManager.storedLanguageCode)
        case .emptyCurrentPassword:
            return LanguageManager.resolveString(forKey: "validation_empty_current_password", languageCode: LanguageManager.storedLanguageCode)
        case .custom(let message):
            return message
        }
    }
}

/// Сервіс для валідації полів входу, реєстрації та зміни пароля/пошти.
enum AuthValidator {
    static let minPasswordLength = 8
    static let minSignInPasswordLength = 6

    /// Валідує адресу електронної пошти.
    /// Повертає очищений від зайвих пробілів email або помилку валідації.
    static func validateEmail(_ email: String) -> Result<String, ValidationError> {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyEmail) }
        guard trimmed.count <= 254 else { return .failure(.invalidEmailFormat) }

        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        guard NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: trimmed) else {
            return .failure(.invalidEmailFormat)
        }

        // Розбиваємо на localPart і domainPart для детальної перевірки
        let parts = trimmed.components(separatedBy: "@")
        guard parts.count == 2 else { return .failure(.invalidEmailFormat) }
        let localPart = parts[0]
        let domainPart = parts[1]

        // localPart: не може починатись або закінчуватись крапкою, не може містити ".."
        guard !localPart.hasPrefix("."),
              !localPart.hasSuffix("."),
              !localPart.contains("..") else {
            return .failure(.invalidEmailFormat)
        }

        // domainPart: не може починатись або закінчуватись крапкою чи дефісом, не може містити ".."
        guard !domainPart.hasPrefix("."),
              !domainPart.hasPrefix("-"),
              !domainPart.hasSuffix("."),
              !domainPart.hasSuffix("-"),
              !domainPart.contains("..") else {
            return .failure(.invalidEmailFormat)
        }

        return .success(trimmed)
    }

    /// Валідує поля для форми входу (Sign In).
    static func validateSignIn(email: String, password: String) -> Result<(email: String, password: String), ValidationError> {
        let emailResult = validateEmail(email)
        switch emailResult {
        case .failure(let error):
            return .failure(error)
        case .success(let validEmail):
            guard !password.isEmpty else {
                return .failure(.emptyPassword)
            }
            guard password.count >= minSignInPasswordLength else {
                return .failure(.passwordTooShort(min: minSignInPasswordLength))
            }
            return .success((email: validEmail, password: password))
        }
    }

    /// Валідує новий пароль відповідно до сучасних вимог безпеки (довжина, великі/малі літери, цифри).
    static func validateNewPassword(_ password: String) -> Result<String, ValidationError> {
        guard !password.isEmpty else {
            return .failure(.emptyPassword)
        }
        guard password.count >= minPasswordLength else {
            return .failure(.passwordTooShort(min: minPasswordLength))
        }
        guard password.range(of: "[A-Z]", options: .regularExpression) != nil else {
            return .failure(.passwordMissingUppercase)
        }
        guard password.range(of: "[a-z]", options: .regularExpression) != nil else {
            return .failure(.passwordMissingLowercase)
        }
        guard password.range(of: "[0-9]", options: .regularExpression) != nil else {
            return .failure(.passwordMissingDigit)
        }
        return .success(password)
    }

    /// Валідує поля форми реєстрації (Sign Up).
    static func validateSignUp(
        email: String,
        password: String,
        confirmPassword: String
    ) -> Result<(email: String, password: String), ValidationError> {
        let emailResult = validateEmail(email)
        switch emailResult {
        case .failure(let error):
            return .failure(error)
        case .success(let validEmail):
            let passwordResult = validateNewPassword(password)
            switch passwordResult {
            case .failure(let error):
                return .failure(error)
            case .success(let validPassword):
                guard !confirmPassword.isEmpty else {
                    return .failure(.emptyConfirmPassword)
                }
                guard validPassword == confirmPassword else {
                    return .failure(.passwordsDoNotMatch)
                }
                return .success((email: validEmail, password: validPassword))
            }
        }
    }

    /// Валідує запит на скидання паролю.
    static func validateResetPassword(email: String) -> Result<String, ValidationError> {
        validateEmail(email)
    }

    /// Валідує поля для зміни пароля.
    static func validatePasswordChange(
        currentPassword: String?,
        newPassword: String,
        confirmPassword: String,
        requiresCurrentPassword: Bool = true
    ) -> Result<Void, ValidationError> {
        if requiresCurrentPassword {
            guard let current = currentPassword, !current.isEmpty else {
                return .failure(.emptyCurrentPassword)
            }
        }

        let passwordResult = validateNewPassword(newPassword)
        switch passwordResult {
        case .failure(let error):
            return .failure(error)
        case .success(let validNewPassword):
            guard !confirmPassword.isEmpty else {
                return .failure(.emptyConfirmPassword)
            }
            guard validNewPassword == confirmPassword else {
                return .failure(.passwordsDoNotMatch)
            }
            return .success(())
        }
    }
}
