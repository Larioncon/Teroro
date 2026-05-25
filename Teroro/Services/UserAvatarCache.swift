import CryptoKit
import Foundation
import SwiftUI
import UIKit

@MainActor
final class UserAvatarCache: ObservableObject {
    static let shared = UserAvatarCache()

    @Published private var version = UUID()

    private let cache = NSCache<NSString, UIImage>()
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    private let fileManager = FileManager.default

    private init() {}

    func image(for avatarURL: String?) -> UIImage? {
        _ = version
        guard let key = cacheKey(for: avatarURL) else { return nil }

        if let image = cache.object(forKey: key as NSString) {
            return image
        }

        guard let image = diskImage(forKey: key) else { return nil }
        cache.setObject(image, forKey: key as NSString)
        return image
    }

    func loadImageIfNeeded(for avatarURL: String?) {
        guard let key = cacheKey(for: avatarURL), cache.object(forKey: key as NSString) == nil else { return }
        if let image = diskImage(forKey: key) {
            cache.setObject(image, forKey: key as NSString)
            version = UUID()
            return
        }

        guard loadingTasks[key] == nil else { return }
        guard let url = URL(string: key) else { return }

        loadingTasks[key] = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                await MainActor.run {
                    self?.cache.setObject(image, forKey: key as NSString)
                    self?.storeData(data, forKey: key)
                    self?.loadingTasks[key] = nil
                    self?.version = UUID()
                }
                return image
            } catch {
                await MainActor.run {
                    self?.loadingTasks[key] = nil
                }
                return nil
            }
        }
    }

    func store(_ image: UIImage, for avatarURL: String?) {
        guard let key = cacheKey(for: avatarURL) else { return }
        cache.setObject(image, forKey: key as NSString)
        if let data = image.jpegData(compressionQuality: 0.86) {
            storeData(data, forKey: key)
        }
        version = UUID()
    }

    private func cacheKey(for avatarURL: String?) -> String? {
        let value = avatarURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty, value != "ava0" else { return nil }
        return value
    }

    private func diskImage(forKey key: String) -> UIImage? {
        let fileURL = fileURL(forKey: key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    private func storeData(_ data: Data, forKey key: String) {
        let directoryURL = cacheDirectoryURL()
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try data.write(to: fileURL(forKey: key), options: [.atomic])
        } catch {
            assertionFailure("Failed to cache avatar image: \(error.localizedDescription)")
        }
    }

    private func fileURL(forKey key: String) -> URL {
        cacheDirectoryURL().appendingPathComponent("\(fileName(forKey: key)).jpg")
    }

    private func cacheDirectoryURL() -> URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("UserAvatars", isDirectory: true)
    }

    private func fileName(forKey key: String) -> String {
        SHA256.hash(data: Data(key.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
