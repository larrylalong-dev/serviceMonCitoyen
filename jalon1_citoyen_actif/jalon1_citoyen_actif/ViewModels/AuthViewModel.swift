// AuthViewModel.swift
// Gère la connexion, l'inscription et la réinitialisation de mot de passe

import Foundation
import Observation
import SwiftData

// @Observable remplace ObservableObject en Swift moderne
@MainActor
@Observable
class AuthViewModel {

    // Le contexte SwiftData injecté
    var modelContext: ModelContext

    // L'utilisateur connecté (DTO). Si nil, personne n'est connecté
    var utilisateurConnecte: UserDTO? = nil

    // Message d'erreur à afficher dans les vues
    var messageErreur: String = ""
    var estEnChargement: Bool = false

    private let api = APIService.shared

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

    // Connexion via le backend Railway
    func connexion(courriel: String, motDePasse: String) {
        let courrielNettoye = courriel.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let motDePasseNettoye = motDePasse.trimmingCharacters(in: .whitespacesAndNewlines)

        guard courrielNettoye.contains("@"), courrielNettoye.contains(".") else {
            messageErreur = "Veuillez entrer un courriel valide."
            return
        }
        guard !motDePasseNettoye.isEmpty else {
            messageErreur = "Veuillez entrer votre mot de passe."
            return
        }

        messageErreur = ""
        estEnChargement = true

        Task {
            defer { estEnChargement = false }
            do {
                let (user, token) = try await api.connexion(courriel: courrielNettoye, motDePasse: motDePasseNettoye)
                api.setToken(token)
                utilisateurConnecte = user
            } catch let error as APIError {
                messageErreur = error.localizedDescription
            } catch {
                messageErreur = "Erreur réseau: \(error.localizedDescription)"
            }
        }
    }

    // Inscription via le backend Railway
    func inscription(prenom: String, nom: String, courriel: String,
                     telephone: String, adresse: String, motDePasse: String) {
        let prenomNettoye = prenom.trimmingCharacters(in: .whitespacesAndNewlines)
        let nomNettoye = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        let courrielNettoye = courriel.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let telephoneNettoye = telephone.trimmingCharacters(in: .whitespacesAndNewlines)
        let adresseNettoyee = adresse.trimmingCharacters(in: .whitespacesAndNewlines)
        let motDePasseNettoye = motDePasse.trimmingCharacters(in: .whitespacesAndNewlines)

        if prenomNettoye.isEmpty || nomNettoye.isEmpty || courrielNettoye.isEmpty ||
            telephoneNettoye.isEmpty || adresseNettoyee.isEmpty || motDePasseNettoye.isEmpty {
            messageErreur = "Veuillez remplir tous les champs."
            return
        }
        if !courrielNettoye.contains("@") || !courrielNettoye.contains(".") {
            messageErreur = "Veuillez entrer un courriel valide."
            return
        }
        if telephoneNettoye.filter({ $0.isNumber }).count < 10 {
            messageErreur = "Le téléphone doit contenir au moins 10 chiffres."
            return
        }
        if adresseNettoyee.count < 5 {
            messageErreur = "L’adresse doit contenir au moins 5 caractères."
            return
        }
        if motDePasseNettoye.count < 4 {
            messageErreur = "Le mot de passe doit contenir au moins 4 caractères."
            return
        }

        messageErreur = ""
        estEnChargement = true

        Task {
            defer { estEnChargement = false }
            do {
                let (user, token) = try await api.inscription(
                    prenom: prenomNettoye,
                    nom: nomNettoye,
                    courriel: courrielNettoye,
                    telephone: telephoneNettoye,
                    adresse: adresseNettoyee,
                    motDePasse: motDePasseNettoye
                )
                api.setToken(token)
                utilisateurConnecte = user
            } catch let error as APIError {
                messageErreur = error.localizedDescription
            } catch {
                messageErreur = "Erreur réseau: \(error.localizedDescription)"
            }
        }
    }

    // Déconnexion
    func deconnexion() {
        api.setToken(nil)
        utilisateurConnecte = nil
    }

    @discardableResult
    func modifierProfil(prenom: String, nom: String, telephone: String,
                        adresse: String, motDePasse: String?) async -> Bool {
        guard let utilisateurConnecte else {
            messageErreur = "Aucun utilisateur connecté."
            return false
        }

        let prenomNettoye = prenom.trimmingCharacters(in: .whitespacesAndNewlines)
        let nomNettoye = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        let telephoneNettoye = telephone.trimmingCharacters(in: .whitespacesAndNewlines)
        let adresseNettoyee = adresse.trimmingCharacters(in: .whitespacesAndNewlines)
        let motDePasseNettoye = motDePasse?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !prenomNettoye.isEmpty, !nomNettoye.isEmpty, !telephoneNettoye.isEmpty else {
            messageErreur = "Veuillez remplir le prénom, le nom et le téléphone."
            return false
        }
        guard telephoneNettoye.filter({ $0.isNumber }).count >= 10 else {
            messageErreur = "Le téléphone doit contenir au moins 10 chiffres."
            return false
        }
        guard utilisateurConnecte.role != .citoyen || adresseNettoyee.count >= 5 else {
            messageErreur = "L’adresse doit contenir au moins 5 caractères."
            return false
        }
        guard adresseNettoyee.isEmpty || adresseNettoyee.count >= 5 else {
            messageErreur = "L’adresse doit contenir au moins 5 caractères."
            return false
        }
        guard motDePasseNettoye.isEmpty || motDePasseNettoye.count >= 4 else {
            messageErreur = "Le mot de passe doit contenir au moins 4 caractères."
            return false
        }

        messageErreur = ""
        estEnChargement = true
        defer { estEnChargement = false }

        do {
            let user = try await api.modifierProfil(
                userId: utilisateurConnecte.id,
                prenom: prenomNettoye,
                nom: nomNettoye,
                telephone: telephoneNettoye,
                adresse: adresseNettoyee,
                motDePasse: motDePasseNettoye.isEmpty ? nil : motDePasseNettoye
            )
            self.utilisateurConnecte = user
            return true
        } catch let error as APIError {
            messageErreur = error.localizedDescription
        } catch {
            messageErreur = "Erreur réseau: \(error.localizedDescription)"
        }
        return false
    }
}
