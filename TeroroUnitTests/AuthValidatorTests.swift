//
//  AuthValidatorTests.swift
//  TeroroUnitTests
//
//  Created by Chmil Oleksandr on 21.09.26.
//

import Testing
@testable import Teroro

struct AuthValidatorTests {

    // MARK: - Email Validation

    @Test("Valid email formats pass validation and whitespace is trimmed")
    func validEmails() {
        let validCases: [(input: String, expected: String)] = [
            ("test@example.com", "test@example.com"),
            ("  user.name+tag@sub.domain.org  \n", "user.name+tag@sub.domain.org"),
            ("first.last@company.co.uk", "first.last@company.co.uk"),
            ("123456@numbers.net", "123456@numbers.net"),
            ("simple_email@mail.ua", "simple_email@mail.ua")
        ]

        for testCase in validCases {
            let result = AuthValidator.validateEmail(testCase.input)
            #expect(result == .success(testCase.expected))
        }
    }

    @Test("Empty email or whitespace-only string returns emptyEmail error")
    func emptyEmail() {
        #expect(AuthValidator.validateEmail("") == .failure(.emptyEmail))
        #expect(AuthValidator.validateEmail("   \n\t  ") == .failure(.emptyEmail))
    }

    @Test("Invalid email formats return invalidEmailFormat error")
    func invalidEmailFormats() {
        let invalidEmails = [
            "plainaddress",
            "#@%^%#$@#$@#.com",
            "@example.com",
            "Joe Smith <email@example.com>",
            "email.example.com",
            "email@example@example.com",
            ".email@example.com",
            "email.@example.com",
            "email..email@example.com",
            "email@example..com",
            "email@example",
            "email@example.c"
        ]

        for email in invalidEmails {
            let result = AuthValidator.validateEmail(email)
            #expect(result == .failure(.invalidEmailFormat), "Failed for email: \(email)")
        }
    }

    // MARK: - Sign In Validation

    @Test("Sign in validation succeeds with valid credentials")
    func signInSuccess() {
        let result = AuthValidator.validateSignIn(email: "  user@test.com ", password: "password123")
        switch result {
        case .success(let credentials):
            #expect(credentials.email == "user@test.com")
            #expect(credentials.password == "password123")
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("Sign in validation fails with invalid email format")
    func signInInvalidEmail() {
        let result = AuthValidator.validateSignIn(email: "invalid-email", password: "password123")
        switch result {
        case .success:
            Issue.record("Expected invalidEmailFormat error but validation passed")
        case .failure(let error):
            #expect(error == .invalidEmailFormat)
        }
    }

    @Test("Sign in validation fails when password is empty")
    func signInEmptyPassword() {
        let result = AuthValidator.validateSignIn(email: "valid@test.com", password: "")
        switch result {
        case .success:
            Issue.record("Expected emptyPassword error but validation passed")
        case .failure(let error):
            #expect(error == .emptyPassword)
        }
    }

    @Test("Sign in validation fails when password is shorter than 6 characters")
    func signInPasswordTooShort() {
        let result = AuthValidator.validateSignIn(email: "valid@test.com", password: "12345")
        switch result {
        case .success:
            Issue.record("Expected passwordTooShort error but validation passed")
        case .failure(let error):
            #expect(error == .passwordTooShort(min: AuthValidator.minSignInPasswordLength))
        }
    }

    // MARK: - New Password Requirements

    @Test("Valid new passwords pass all security requirements")
    func validNewPassword() {
        let validPasswords = [
            "StrongPass1",
            "Secure#Password2026",
            "Aa1bb2cc3!"
        ]

        for password in validPasswords {
            #expect(AuthValidator.validateNewPassword(password) == .success(password))
        }
    }

    @Test("New password fails when empty or shorter than 8 characters")
    func newPasswordTooShort() {
        #expect(AuthValidator.validateNewPassword("") == .failure(.emptyPassword))
        #expect(AuthValidator.validateNewPassword("Ab1") == .failure(.passwordTooShort(min: AuthValidator.minPasswordLength)))
        #expect(AuthValidator.validateNewPassword("Abcdef1") == .failure(.passwordTooShort(min: AuthValidator.minPasswordLength)))
    }

    @Test("New password fails when it contains no uppercase letter")
    func newPasswordMissingUppercase() {
        let result = AuthValidator.validateNewPassword("password123")
        #expect(result == .failure(.passwordMissingUppercase))
    }

    @Test("New password fails when it contains no lowercase letter")
    func newPasswordMissingLowercase() {
        let result = AuthValidator.validateNewPassword("PASSWORD123")
        #expect(result == .failure(.passwordMissingLowercase))
    }

    @Test("New password fails when it contains no digit")
    func newPasswordMissingDigit() {
        let result = AuthValidator.validateNewPassword("PasswordNoDigits")
        #expect(result == .failure(.passwordMissingDigit))
    }

    // MARK: - Sign Up Validation

    @Test("Sign up validation succeeds with valid credentials and matching passwords")
    func signUpSuccess() {
        let result = AuthValidator.validateSignUp(
            email: "newuser@test.com",
            password: "SecurePassword1",
            confirmPassword: "SecurePassword1"
        )

        switch result {
        case .success(let credentials):
            #expect(credentials.email == "newuser@test.com")
            #expect(credentials.password == "SecurePassword1")
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("Sign up validation fails when confirm password is empty")
    func signUpEmptyConfirmPassword() {
        let result = AuthValidator.validateSignUp(
            email: "newuser@test.com",
            password: "SecurePassword1",
            confirmPassword: ""
        )
        switch result {
        case .success:
            Issue.record("Expected emptyConfirmPassword error but validation passed")
        case .failure(let error):
            #expect(error == .emptyConfirmPassword)
        }
    }

    @Test("Sign up validation fails when passwords do not match")
    func signUpPasswordsDoNotMatch() {
        let result = AuthValidator.validateSignUp(
            email: "newuser@test.com",
            password: "SecurePassword1",
            confirmPassword: "DifferentPassword1"
        )
        switch result {
        case .success:
            Issue.record("Expected passwordsDoNotMatch error but validation passed")
        case .failure(let error):
            #expect(error == .passwordsDoNotMatch)
        }
    }

    // MARK: - Password Change Validation

    @Test("Password change succeeds when all fields are valid and current password is required")
    func passwordChangeSuccess() {
        let result = AuthValidator.validatePasswordChange(
            currentPassword: "OldPassword1",
            newPassword: "NewSecurePassword1",
            confirmPassword: "NewSecurePassword1",
            requiresCurrentPassword: true
        )
        switch result {
        case .success:
            break
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("Password change fails when current password is empty")
    func passwordChangeEmptyCurrentPassword() {
        let result = AuthValidator.validatePasswordChange(
            currentPassword: "",
            newPassword: "NewSecurePassword1",
            confirmPassword: "NewSecurePassword1",
            requiresCurrentPassword: true
        )
        switch result {
        case .success:
            Issue.record("Expected emptyCurrentPassword error but validation passed")
        case .failure(let error):
            #expect(error == .emptyCurrentPassword)
        }
    }

    @Test("Password change succeeds without current password when it is not required")
    func passwordChangeWithoutCurrentPasswordRequirement() {
        let result = AuthValidator.validatePasswordChange(
            currentPassword: nil,
            newPassword: "NewSecurePassword1",
            confirmPassword: "NewSecurePassword1",
            requiresCurrentPassword: false
        )
        switch result {
        case .success:
            break
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("Password change fails when new passwords do not match")
    func passwordChangeMismatch() {
        let result = AuthValidator.validatePasswordChange(
            currentPassword: "OldPassword1",
            newPassword: "NewSecurePassword1",
            confirmPassword: "MismatchPassword1",
            requiresCurrentPassword: true
        )
        switch result {
        case .success:
            Issue.record("Expected passwordsDoNotMatch error but validation passed")
        case .failure(let error):
            #expect(error == .passwordsDoNotMatch)
        }
    }

    // MARK: - Reset Password Validation

    @Test("Reset password validation passes for valid email and fails for empty email")
    func resetPassword() {
        #expect(AuthValidator.validateResetPassword(email: "valid@email.com") == .success("valid@email.com"))
        #expect(AuthValidator.validateResetPassword(email: "") == .failure(.emptyEmail))
    }
}
