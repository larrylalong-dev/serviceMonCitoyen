// User.swift
// Modèle pour représenter un utilisateur de l'application

import Foundation
import SwiftData

// Les différents types d'utilisateurs
enum UserRole: String, Codable, CaseIterable {
    case citoyen = "citoyen"
    case employe = "employe"
    case agent  = "agent"

    var label: String {
        switch self {
        case .citoyen: return "Citoyen"
        case .employe: return "Employé municipal"
        case .agent: return "Agent municipal"
        }
    }
}

// Remplacement de la struct par une entité SwiftData (@Model)
@Model
class User: Identifiable {
    // Identifiant unique
    @Attribute(.unique) var id: String

    var prenom: String
    var nom: String
    var courriel: String
    var telephone: String
    var adresse: String
    var role: UserRole
    var numeroAgent: String? // Seulement pour employés et agents

    // Init explicite pour faciliter la création depuis le code (seed, tests...)
    init(id: String = UUID().uuidString,
         prenom: String,
         nom: String,
         courriel: String,
         telephone: String = "",
         adresse: String = "",
         role: UserRole = .citoyen,
         numeroAgent: String? = nil) {
        self.id = id
        self.prenom = prenom
        self.nom = nom
        self.courriel = courriel
        self.telephone = telephone
        self.adresse = adresse
        self.role = role
        self.numeroAgent = numeroAgent
    }
}
