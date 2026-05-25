import SwiftUI

struct UserAvatarView: View {
    let avatarURL: String?
    var size: CGFloat = 72

    @ObservedObject private var cache = UserAvatarCache.shared

    var body: some View {
        Group {
            if let image = cache.image(for: avatarURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .padding(size * 0.08)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background(Circle().fill(Color.secondary.opacity(0.12)))
        .overlay(Circle().strokeBorder(Color.secondary.opacity(0.18), lineWidth: 1))
        .task(id: avatarURL) {
            cache.loadImageIfNeeded(for: avatarURL)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        UserAvatarView(avatarURL: "ava0")
        UserAvatarView(avatarURL: nil, size: 44)
    }
    .padding()
}
