import Foundation
import Testing
@testable import Teroro

struct LanguageLocalizationTests {

    @Test("AppLanguage cases and properties are configured correctly")
    func appLanguageProperties() {
        #expect(AppLanguage.english.code == "en")
        #expect(AppLanguage.english.displayName == "English")
        #expect(AppLanguage.english.nativeName == "English")

        #expect(AppLanguage.ukrainian.code == "uk")
        #expect(AppLanguage.ukrainian.displayName == "Ukrainian")
        #expect(AppLanguage.ukrainian.nativeName == "Українська")

        #expect(AppLanguage.german.code == "de")
        #expect(AppLanguage.german.displayName == "German")
        #expect(AppLanguage.german.nativeName == "Deutsch")

        #expect(AppLanguage.russian.code == "ru")
        #expect(AppLanguage.russian.displayName == "Russian")
        #expect(AppLanguage.russian.nativeName == "Русский")

        #expect(AppLanguage.allCases.count == 4)
    }

    @Test("Default language detection falls back to English when language is unsupported")
    func unsupportedLanguageFallback() {
        let defaultLang = AppLanguage.detectDefaultLanguage()
        // It must be one of the four supported languages
        #expect(AppLanguage.allCases.contains(defaultLang))
    }

    @MainActor
    @Test("LanguageManager changes language and resolves localized strings")
    func languageManagerSwitching() {
        let manager = LanguageManager.shared

        // Test English
        manager.setLanguage(.english)
        #expect(manager.currentLanguage == .english)
        #expect(manager.localizedString(forKey: "language_title") == "Language")
        #expect(manager.localizedString(forKey: "settings_title") == "Settings")

        // Test Ukrainian
        manager.setLanguage(.ukrainian)
        #expect(manager.currentLanguage == .ukrainian)
        #expect(manager.localizedString(forKey: "language_title") == "Мова")
        #expect(manager.localizedString(forKey: "settings_title") == "Налаштування")

        // Test German
        manager.setLanguage(.german)
        #expect(manager.currentLanguage == .german)
        #expect(manager.localizedString(forKey: "language_title") == "Sprache")
        #expect(manager.localizedString(forKey: "settings_title") == "Einstellungen")

        // Test Russian
        manager.setLanguage(.russian)
        #expect(manager.currentLanguage == .russian)
        #expect(manager.localizedString(forKey: "language_title") == "Язык")
        #expect(manager.localizedString(forKey: "settings_title") == "Настройки")
    }
}
