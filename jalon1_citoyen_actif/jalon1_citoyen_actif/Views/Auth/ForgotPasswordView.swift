// ForgotPasswordView.swift
// Page de récupération de mot de passe

import SwiftUI

struct ForgotPasswordView: View {

    @State private var courriel: String = ""
    @State private var messageSent: Bool = false

    var body: some View {
        VStack(spacing: 24) {

            Text("Réinitialiser le mot de passe")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 30)

            Text("Entrez votre courriel et nous vous enverrons un lien pour réinitialiser votre mot de passe.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Courriel", text: $courriel)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Si on a "envoyé" le courriel, on affiche un message de confirmation
            if messageSent {
                Text("Un courriel de réinitialisation a été envoyé.")
                    .foregroundColor(.green)
                    .font(.callout)
            }

            Button(action: {
                // Simule l'envoi d'un courriel
                if !courriel.isEmpty {
                    messageSent = true
                }
            }) {
                Text("Envoyer le lien")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Mot de passe oublié")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
