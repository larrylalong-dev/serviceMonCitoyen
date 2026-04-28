// RegisterView.swift
// Page de création de compte moderne

import SwiftUI
import SwiftData

struct RegisterView: View {

    @Environment(AuthViewModel.self) var authVM
    @Environment(\.dismiss) var dismiss

    @State private var prenom: String = ""
    @State private var nom: String = ""
    @State private var courriel: String = ""
    @State private var telephone: String = ""
    @State private var adresse: String = ""
    @State private var motDePasse: String = ""
    @State private var confirmation: String = ""
    @State private var messageLocal = ""

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(spacing: 24) {
                    AuthHeader(
                        title: "Créer un compte",
                        subtitle: "Un profil citoyen permet de créer et suivre vos signalements.",
                        icon: "person.crop.circle.badge.plus"
                    )

                    AuthCard {
                        AuthTextField(title: "Prénom", icon: "person.fill", text: $prenom)
                        AuthTextField(title: "Nom", icon: "person.text.rectangle.fill", text: $nom)
                        AuthTextField(title: "Courriel", icon: "envelope.fill", text: $courriel, keyboard: .emailAddress)
                        AuthTextField(title: "Téléphone", icon: "phone.fill", text: $telephone, keyboard: .phonePad)
                        AuthTextField(title: "Adresse", icon: "house.fill", text: $adresse)
                        AuthTextField(title: "Mot de passe", icon: "lock.fill", text: $motDePasse, isSecure: true)
                        AuthTextField(title: "Confirmer le mot de passe", icon: "checkmark.shield.fill", text: $confirmation, isSecure: true)

                        AuthErrorView(message: messageLocal.isEmpty ? authVM.messageErreur : messageLocal)

                        AuthPrimaryButton(
                            title: "Créer mon compte",
                            icon: "checkmark.circle.fill",
                            isLoading: authVM.estEnChargement
                        ) {
                            creerCompte()
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Inscription")
        .navigationBarTitleDisplayMode(.inline)
    }

    func creerCompte() {
        guard motDePasse == confirmation else {
            messageLocal = "Les mots de passe ne correspondent pas."
            return
        }
        messageLocal = ""
        authVM.inscription(
            prenom: prenom,
            nom: nom,
            courriel: courriel,
            telephone: telephone,
            adresse: adresse,
            motDePasse: motDePasse
        )
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
