// RegisterView.swift
// Page de création de compte

import SwiftUI
import SwiftData

struct RegisterView: View {

    @Environment(AuthViewModel.self) var authVM
    @Environment(\.dismiss) var dismiss
    // Ensemble de state pour les champs du formulaire d'inscription
    @State private var prenom: String = ""
    @State private var nom: String = ""
    @State private var courriel: String = ""
    @State private var telephone: String = ""
    @State private var adresse: String = ""
    @State private var motDePasse: String = ""
    @State private var confirmation: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                Text("Créer un compte")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)

                Group {
                    TextField("Prénom", text: $prenom)
                    TextField("Nom", text: $nom)
                    TextField("Courriel", text: $courriel)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Téléphone", text: $telephone)
                        .keyboardType(.phonePad)
                    TextField("Adresse", text: $adresse)
                    SecureField("Mot de passe", text: $motDePasse)
                    SecureField("Confirmer le mot de passe", text: $confirmation)
                }
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

                // Affiche l'erreur si quelque chose ne va pas
                if !authVM.messageErreur.isEmpty {
                    Text(authVM.messageErreur)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    // Vérifie que les mots de passe correspondent
                    if motDePasse != confirmation {
                        authVM.messageErreur = "Les mots de passe ne correspondent pas."
                        return
                    }
                    authVM.inscription(prenom: prenom, nom: nom,
                                       courriel: courriel, telephone: telephone,
                                       adresse: adresse, motDePasse: motDePasse)
                }) {
                    Text("Créer mon compte")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Inscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Report.self, configurations: config)
    let authVM = AuthViewModel(modelContext: container.mainContext)
    
    NavigationStack {
        RegisterView()
            .environment(authVM)
            .modelContainer(container)
    }
}
