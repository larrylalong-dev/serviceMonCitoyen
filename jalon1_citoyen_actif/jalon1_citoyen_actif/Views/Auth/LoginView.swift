// LoginView.swift
// Page de connexion moderne de l'application

import SwiftUI
import SwiftData

struct LoginView: View {

    @Environment(AuthViewModel.self) var authVM

    @State private var courriel: String = ""
    @State private var motDePasse: String = ""
    @State private var allerInscription: Bool = false
    @State private var allerMotDePasse: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                AuthBackground()

                ScrollView {
                    VStack(spacing: 28) {
                        AuthHeader(
                            title: "Citoyen Actif",
                            subtitle: "Signalez, suivez et améliorez votre quartier en quelques gestes.",
                            icon: "building.2.crop.circle.fill"
                        )

                        AuthCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bon retour")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Connectez-vous pour suivre vos rapports.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            AuthTextField(title: "Courriel", icon: "envelope.fill", text: $courriel, keyboard: .emailAddress)
                            AuthTextField(title: "Mot de passe", icon: "lock.fill", text: $motDePasse, isSecure: true)

                            AuthErrorView(message: authVM.messageErreur)

                            AuthPrimaryButton(
                                title: "Se connecter",
                                icon: "arrow.right.circle.fill",
                                isLoading: authVM.estEnChargement
                            ) {
                                authVM.connexion(courriel: courriel, motDePasse: motDePasse)
                            }

                            Button("Mot de passe oublié ?") {
                                allerMotDePasse = true
                            }
                            .font(.footnote)
                            .fontWeight(.semibold)
                        }

                        HStack(spacing: 4) {
                            Text("Pas encore de compte ?")
                                .foregroundColor(.secondary)
                            Button("Créer un compte") {
                                allerInscription = true
                            }
                            .fontWeight(.bold)
                        }
                        .font(.footnote)
                        .padding(.bottom, 18)
                    }
                }
            }
            .navigationDestination(isPresented: $allerInscription) {
                RegisterView()
            }
            .navigationDestination(isPresented: $allerMotDePasse) {
                ForgotPasswordView()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Report.self, configurations: config)
    let authVM = AuthViewModel(modelContext: container.mainContext)

    LoginView()
        .environment(authVM)
        .modelContainer(container)
}
