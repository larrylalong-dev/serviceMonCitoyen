// UserDTO.swift
// DTO pour User - Utilisé pour le transfert de données entre les vues et les ViewModels
// Séparé du modèle SwiftData pour une meilleure architecture

import Foundation

// DTO User - lightweight, Codable, sans SwiftData
struct UserDTO: Identifiable, Codable, Hashable {
    let id: String
    let prenom: String
    let nom: String
    let courriel: String
    let telephone: String
    let adresse: String
    let role: UserRole
    let numeroAgent: String?
    
    // Conformité Hashable - on utilise uniquement l'id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UserDTO, rhs: UserDTO) -> Bool {
        lhs.id == rhs.id
    }
    
    // Propriétés calculées
    var nomComplet: String {
        "\(prenom) \(nom)"
    }
    
    var initiales: String {
        "\(prenom.prefix(1))\(nom.prefix(1))".uppercased()
    }
}

// Extensions de conversion entre User (SwiftData) et UserDTO
extension User {
    /// Convertir une entité SwiftData User en UserDTO
    func toDTO() -> UserDTO {
        UserDTO(
            id: self.id,
            prenom: self.prenom,
            nom: self.nom,
            courriel: self.courriel,
            telephone: self.telephone,
            adresse: self.adresse,
            role: self.role,
            numeroAgent: self.numeroAgent
        )
    }
}

extension UserDTO {
    /// Convertir un UserDTO en entité SwiftData User
    func toModel() -> User {
        User(
            id: self.id,
            prenom: self.prenom,
            nom: self.nom,
            courriel: self.courriel,
            telephone: self.telephone,
            adresse: self.adresse,
            role: self.role,
            numeroAgent: self.numeroAgent
        )
    }
}
