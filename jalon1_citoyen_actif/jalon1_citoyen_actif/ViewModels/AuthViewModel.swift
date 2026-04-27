// AuthViewModel.swift
// Gère la connexion, l'inscription et la réinitialisation de mot de passe

import Foundation
import Observation
import SwiftData

// @Observable remplace ObservableObject en Swift moderne
@Observable
class AuthViewModel {

    // Le contexte SwiftData injecté
    var modelContext: ModelContext

    // L'utilisateur connecté (DTO). Si nil, personne n'est connecté
    var utilisateurConnecte: UserDTO? = nil

    // Message d'erreur à afficher dans les vues
    var messageErreur: String = ""

    // Initialisation avec un ModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedUsersIfNeeded()
    }

    // Seed d'utilisateurs fictifs dans SwiftData si aucun n'existe
    func seedUsersIfNeeded() {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<User>())
            if !existing.isEmpty { return }
        } catch {
            // ignore
        }

        let users = [
            User(id: "u1", prenom: "Marie", nom: "Tremblay", courriel: "marie@test.com", telephone: "819-000-0001", adresse: "123 Rue des Forges", role: .citoyen, numeroAgent: nil),
            User(id: "u2", prenom: "Jean", nom: "Côté", courriel: "jean@test.com", telephone: "819-000-0002", adresse: "450 Boul. des Récollets", role: .citoyen, numeroAgent: nil),
            User(id: "emp1", prenom: "Pierre", nom: "Roy", courriel: "pierre@ville.com", telephone: "819-000-0010", adresse: "", role: .employe, numeroAgent: "EMP-001"),
            User(id: "agt1", prenom: "Sophie", nom: "Lavoie", courriel: "sophie@ville.com", telephone: "819-000-0020", adresse: "", role: .agent, numeroAgent: "AGT-001")
        ]
        for u in users { modelContext.insert(u) }
        do { try modelContext.save() } catch { print("Erreur seed users: \(error)") }
    }

    // Simule la connexion avec courriel + mot de passe en s'appuyant sur SwiftData
    func connexion(courriel: String, motDePasse: String) {
        // Cherche dans SwiftData
        let predicate = #Predicate<User> { $0.courriel == courriel }
        do {
            let descriptor = FetchDescriptor<User>(predicate: predicate)
            let results = try modelContext.fetch(descriptor)
            if let user = results.first {
                // En vrai on vérifierait le mot de passe ici
                if motDePasse == "1234" {
                    // Convertir User (SwiftData) en UserDTO
                    utilisateurConnecte = user.toDTO()
                    messageErreur = ""
                } else {
                    messageErreur = "Mot de passe incorrect"
                }
            } else {
                messageErreur = "Aucun compte trouvé avec ce courriel"
            }
        } catch {
            messageErreur = "Erreur interne: \(error)"
        }
    }

    // Simule la création d'un compte et l'enregistre dans SwiftData
    func inscription(prenom: String, nom: String, courriel: String,
                     telephone: String, adresse: String, motDePasse: String) {
        // Vérifie que les champs ne sont pas vides
        if prenom.isEmpty || nom.isEmpty || courriel.isEmpty || motDePasse.isEmpty {
            messageErreur = "Veuillez remplir tous les champs."
            return
        }
        // Crée un nouvel utilisateur et le sauvegarde
        let nouvelUser = User(id: UUID().uuidString, prenom: prenom, nom: nom,
                              courriel: courriel, telephone: telephone,
                              adresse: adresse, role: .citoyen, numeroAgent: nil)
        modelContext.insert(nouvelUser)
        do {
            try modelContext.save()
            // Convertir en DTO pour le ViewModel
            utilisateurConnecte = nouvelUser.toDTO()
            messageErreur = ""
        } catch {
            messageErreur = "Erreur lors de la création du compte: \(error)"
        }
    }

    // Simule la déconnexion
    func deconnexion() {
        utilisateurConnecte = nil
    }
}
