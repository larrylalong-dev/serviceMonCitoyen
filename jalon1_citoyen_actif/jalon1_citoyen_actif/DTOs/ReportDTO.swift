// ReportDTO.swift
// DTO pour Report - Utilisé pour le transfert de données entre les vues et les ViewModels
// Séparé du modèle SwiftData pour une meilleure architecture

import Foundation

// DTO Report - lightweight, Codable, sans dépendances SwiftData
struct ReportDTO: Identifiable, Codable, Hashable {
    let id: String
    let titre: String
    let details: String
    let categorie: ReportCategorie
    let etat: ReportEtat
    let date: String
    let adresse: String
    let latitude: Double
    let longitude: Double
    let citoyenId: String
    let citoyenNom: String
    let imageData: Data?
    
    // Conformité Hashable - on utilise uniquement l'id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ReportDTO, rhs: ReportDTO) -> Bool {
        lhs.id == rhs.id
    }
    
    // Propriétés calculées pour les vues
    var adresseAbregee: String {
        let parts = adresse.split(separator: ",")
        return parts.count > 1 ? String(parts[0]) : adresse
    }
    
    var villeSeulement: String {
        let parts = adresse.split(separator: ",")
        return parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
    }
    
    var jours: Int {
        let formatter = ISO8601DateFormatter()
        let dateObj = formatter.date(from: date) ?? Date()
        return Calendar.current.dateComponents([.day], from: dateObj, to: Date()).day ?? 0
    }
}

// Extensions de conversion entre Report (SwiftData) et ReportDTO
extension Report {
    /// Convertir une entité SwiftData Report en ReportDTO
    func toDTO() -> ReportDTO {
        ReportDTO(
            id: self.id,
            titre: self.titre,
            details: self.details,
            categorie: self.categorie,
            etat: self.etat,
            date: self.date,
            adresse: self.adresse,
            latitude: self.latitude,
            longitude: self.longitude,
            citoyenId: self.citoyenId,
            citoyenNom: self.citoyenNom,
            imageData: self.imageData
        )
    }
}

extension ReportDTO {
    /// Convertir un ReportDTO en entité SwiftData Report
    func toModel() -> Report {
        Report(
            id: self.id,
            titre: self.titre,
            details: self.details,
            categorie: self.categorie,
            etat: self.etat,
            date: self.date,
            adresse: self.adresse,
            latitude: self.latitude,
            longitude: self.longitude,
            citoyenId: self.citoyenId,
            citoyenNom: self.citoyenNom,
            imageData: self.imageData
        )
    }
}
