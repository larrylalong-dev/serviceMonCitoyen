// LoginView.swift
// Page de connexion de l'application

import SwiftUI
import SwiftData

struct LoginView: View {

    // On accède au ViewModel partagé
    @Environment(AuthViewModel.self) var authVM

    // Les textes entrés par l'utilisateur
    @State private var courriel: String = ""
    @State private var motDePasse: String = ""

    // Pour naviguer vers les autres pages
    @State private var allerInscription: Bool = false
    @State private var allerMotDePasse: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                // Titre de l'application
                Text("Citoyen Actif")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                Text("Signaler un bris près de chez vous")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                // Champ courriel
                TextField("Courriel", text: $courriel)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // Champ mot de passe
                SecureField("Mot de passe", text: $motDePasse)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // Message d'erreur si connexion échoue
                if !authVM.messageErreur.isEmpty {
                    Text(authVM.messageErreur)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                // Bouton de connexion
                Button(action: {
                    authVM.connexion(courriel: courriel, motDePasse: motDePasse)
                }) {
                    Text("Se connecter")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // Lien vers mot de passe oublié
                Button("Mot de passe oublié ?") {
                    allerMotDePasse = true
                }
                .font(.caption)

                Spacer()

                // Lien vers la page d'inscription
                HStack {
                    Text("Pas encore de compte ?")
                        .font(.footnote)
                    Button("S'inscrire") {
                        allerInscription = true
                    }
                    .font(.footnote)
                }
                .padding(.bottom, 20)

            }
            .navigationDestination(isPresented: $allerInscription) {
                RegisterView()
            }
            .navigationDestination(isPresented: $allerMotDePasse) {
                ForgotPasswordView()
            }
            // Petit texte d'aide pour les tests
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Text("Test : courriel marie@test.com / mot de passe 1234")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
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
