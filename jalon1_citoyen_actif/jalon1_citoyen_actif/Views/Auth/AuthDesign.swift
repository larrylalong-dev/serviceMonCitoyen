import SwiftUI
import UIKit

struct AuthBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.95), Color.cyan.opacity(0.55), Color(.systemBackground)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct AuthHeader: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 82, height: 82)
                .background(.white.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 6) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.88))
            }
        }
        .padding(.top, 38)
    }
}

struct AuthCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 16) {
            content
        }
        .padding(22)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 22, x: 0, y: 12)
        .padding(.horizontal, 20)
    }
}

struct AuthTextField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 22)

            if isSecure {
                SecureField(title, text: $text)
                    .textContentType(.password)
            } else {
                TextField(title, text: $text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
                    .autocorrectionDisabled(keyboard == .emailAddress)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct AuthPrimaryButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                    Text(title)
                }
            }
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isLoading)
    }
}

struct AuthErrorView: View {
    let message: String

    var body: some View {
        if !message.isEmpty {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.red.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
