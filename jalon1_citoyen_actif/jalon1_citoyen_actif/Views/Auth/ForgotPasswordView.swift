// ForgotPasswordView.swift
// Page de récupération de mot de passe moderne

import SwiftUI

struct ForgotPasswordView: View {

    @State private var courriel: String = ""
    @State private var messageSent: Bool = false

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(spacing: 28) {
                    AuthHeader(
                        title: "Mot de passe oublié",
                        subtitle: "Entrez votre courriel pour recevoir les instructions de récupération.",
                        icon: "key.fill"
                    )

                    AuthCard {
                        AuthTextField(title: "Courriel", icon: "envelope.fill", text: $courriel, keyboard: .emailAddress)

                        if messageSent {
                            Label("Un courriel de réinitialisation a été envoyé.", systemImage: "checkmark.circle.fill")
                                .font(.callout)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.green.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        AuthPrimaryButton(title: "Envoyer le lien", icon: "paperplane.fill", isLoading: false) {
                            if !courriel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                messageSent = true
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Récupération")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
