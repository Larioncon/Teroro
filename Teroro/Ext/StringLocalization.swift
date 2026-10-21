import Foundation

extension String {
    @MainActor
    var localized: String {
        LanguageManager.shared.localizedString(forKey: self)
    }
}
