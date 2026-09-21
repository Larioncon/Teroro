//
//  UserFacingAuthErrorTests.swift
//  TeroroUnitTests
//
//  Created by Chmil Oleksandr on 21.09.26.
//

import Foundation
import Testing
import FirebaseAuth
import AuthenticationServices
@testable import Teroro

struct UserFacingAuthErrorTests {

    @Test("Wrapping an existing UserFacingAuthError does not change it")
    func existingUserFacingError() {
        let original = UserFacingAuthError.invalidEmail
        let mapped = UserFacingAuthError(from: original)
        #expect(mapped == .invalidEmail)
    }

    @Test("Firebase Auth error codes map to the correct UserFacingAuthError cases")
    func firebaseAuthErrorCodeMapping() {
        let testCases: [(code: Int, expected: UserFacingAuthError)] = [
            (AuthErrorCode.invalidEmail.rawValue, .invalidEmail),
            (AuthErrorCode.wrongPassword.rawValue, .wrongPassword),
            (AuthErrorCode.userNotFound.rawValue, .userNotFound),
            (AuthErrorCode.emailAlreadyInUse.rawValue, .emailAlreadyInUse),
            (AuthErrorCode.weakPassword.rawValue, .weakPassword),
            (AuthErrorCode.userDisabled.rawValue, .userDisabled),
            (AuthErrorCode.networkError.rawValue, .networkError),
            (AuthErrorCode.tooManyRequests.rawValue, .tooManyRequests),
            (AuthErrorCode.operationNotAllowed.rawValue, .operationNotAllowed),
            (AuthErrorCode.requiresRecentLogin.rawValue, .requiresRecentLogin),
            (AuthErrorCode.invalidCredential.rawValue, .invalidCredentials),
            (AuthErrorCode.accountExistsWithDifferentCredential.rawValue, .accountExistsWithDifferentCredential),
            (AuthErrorCode.credentialAlreadyInUse.rawValue, .credentialAlreadyInUse),
            (AuthErrorCode.providerAlreadyLinked.rawValue, .providerAlreadyLinked),
            (AuthErrorCode.userTokenExpired.rawValue, .sessionInvalid),
            (AuthErrorCode.invalidUserToken.rawValue, .sessionInvalid)
        ]

        for testCase in testCases {
            let nsError = NSError(domain: AuthErrorDomain, code: testCase.code, userInfo: nil)
            let result = UserFacingAuthError(from: nsError)
            #expect(result == testCase.expected, "Failed for error code: \(testCase.code)")
        }
    }

    @Test("Numeric Firebase Auth error codes map correctly via the fallback path")
    func firebaseNumericFallbackCodes() {
        let testCases: [(code: Int, expected: UserFacingAuthError)] = [
            (17008, .invalidEmail),
            (17009, .wrongPassword),
            (17011, .userNotFound),
            (17007, .emailAlreadyInUse),
            (17026, .weakPassword),
            (17005, .userDisabled),
            (17020, .networkError),
            (17010, .tooManyRequests),
            (17006, .operationNotAllowed),
            (17014, .requiresRecentLogin),
            (17004, .invalidCredentials),
            (17012, .accountExistsWithDifferentCredential),
            (17025, .credentialAlreadyInUse),
            (17015, .providerAlreadyLinked),
            (17021, .sessionInvalid),
            (17017, .sessionInvalid),
            (17043, .verificationCodeInvalidOrMissing),  // invalidVerificationCode
            (17044, .verificationCodeInvalidOrMissing),  // missingVerificationCode
            (17051, .verificationExpired)                 // sessionExpired
        ]

        for testCase in testCases {
            let nsError = NSError(domain: "FIRAuthErrorDomain", code: testCase.code, userInfo: nil)
            let result = UserFacingAuthError(from: nsError)
            #expect(result == testCase.expected, "Failed fallback for code: \(testCase.code)")
        }
    }

    @Test("Apple Sign-In cancellation maps to .cancelled")
    func appleSignInCancelled() {
        let error = ASAuthorizationError(.canceled)
        let result = UserFacingAuthError(from: error)
        #expect(result == .cancelled)
    }

    @Test("Cocoa user-cancelled error maps to .cancelled")
    func cocoaUserCancelled() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        let result = UserFacingAuthError(from: error)
        #expect(result == .cancelled)
    }

    @Test("Unknown errors fall back to .generic")
    func unknownErrorFallback() {
        struct CustomTestError: Error {}
        let result = UserFacingAuthError(from: CustomTestError())
        #expect(result == .generic)
    }

    @Test("All UserFacingAuthError cases have a non-empty error description")
    func allErrorsHaveDescriptions() {
        let allErrors: [UserFacingAuthError] = [
            .invalidEmail,
            .wrongPassword,
            .userNotFound,
            .emailAlreadyInUse,
            .weakPassword,
            .userDisabled,
            .networkError,
            .tooManyRequests,
            .operationNotAllowed,
            .requiresRecentLogin,
            .invalidCredentials,
            .verificationCodeInvalidOrMissing,
            .verificationExpired,
            .accountExistsWithDifferentCredential,
            .credentialAlreadyInUse,
            .providerAlreadyLinked,
            .sessionInvalid,
            .cancelled,
            .generic
        ]

        for error in allErrors {
            let description = error.errorDescription
            #expect(description != nil)
            #expect(description?.isEmpty == false)
        }
    }
}
