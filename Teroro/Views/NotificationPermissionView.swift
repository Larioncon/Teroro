//
//  NotificationPermissionView.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/11/26.
//

import SwiftUI

struct NotificationPermissionView: View {
    let onClose: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Text("Потрібен дозвіл")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(8)
                        }
                    }
                }

                Text("Без дозволу на сповіщення ви не отримаєте нагадування про термін.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: onOpenSettings) {
                    Text("Відкрити налаштування")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentColor)
                        )
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.secondary.opacity(0.12))
            )
            .padding(24)
        }
    }
}

#Preview {
    NotificationPermissionView(onClose: {}, onOpenSettings: {})
}
