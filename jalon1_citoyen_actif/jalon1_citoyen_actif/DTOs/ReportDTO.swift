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
    let imageUrl: String?
    let etatDescription: String?
    let etatImageUrl: String?
    let etatModifiePar: String?
    let etatModifieParNom: String?
    let etatModifieLe: String?

    enum CodingKeys: String, CodingKey {
        case id, titre, details, categorie, etat, date, adresse, latitude, longitude
        case citoyenId, citoyenNom, imageData, imageUrl
        case etatDescription, etatImageUrl, etatModifiePar, etatModifieParNom, etatModifieLe
    }

    init(id: String, titre: String, details: String, categorie: ReportCategorie,
         etat: ReportEtat, date: String, adresse: String, latitude: Double,
         longitude: Double, citoyenId: String, citoyenNom: String,
         imageData: Data? = nil, imageUrl: String? = nil,
         etatDescription: String? = nil, etatImageUrl: String? = nil,
         etatModifiePar: String? = nil, etatModifieParNom: String? = nil,
         etatModifieLe: String? = nil) {
        self.id = id
        self.titre = titre
        self.details = details
        self.categorie = categorie
        self.etat = etat
        self.date = date
        self.adresse = adresse
        self.latitude = latitude
        self.longitude = longitude
        self.citoyenId = citoyenId
        self.citoyenNom = citoyenNom
        self.imageData = imageData
        self.imageUrl = imageUrl
        self.etatDescription = etatDescription
        self.etatImageUrl = etatImageUrl
        self.etatModifiePar = etatModifiePar
        self.etatModifieParNom = etatModifieParNom
        self.etatModifieLe = etatModifieLe
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.titre = try container.decode(String.self, forKey: .titre)
        self.details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
        self.categorie = try container.decode(ReportCategorie.self, forKey: .categorie)
        self.etat = try container.decode(ReportEtat.self, forKey: .etat)
        self.date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        self.adresse = try container.decodeIfPresent(String.self, forKey: .adresse) ?? ""
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0
        self.citoyenId = try container.decodeIfPresent(String.self, forKey: .citoyenId) ?? ""
        self.citoyenNom = try container.decodeIfPresent(String.self, forKey: .citoyenNom) ?? ""
        self.imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.etatDescription = try container.decodeIfPresent(String.self, forKey: .etatDescription)
        self.etatImageUrl = try container.decodeIfPresent(String.self, forKey: .etatImageUrl)
        self.etatModifiePar = try container.decodeIfPresent(String.self, forKey: .etatModifiePar)
        self.etatModifieParNom = try container.decodeIfPresent(String.self, forKey: .etatModifieParNom)
        self.etatModifieLe = try container.decodeIfPresent(String.self, forKey: .etatModifieLe)
    }
    
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

    var imageURLComplete: URL? {
        guard let imageUrl else { return nil }
        if imageUrl.hasPrefix("http") {
            return URL(string: imageUrl)
        }
        return URL(string: APIService.shared.baseURL + imageUrl)
    }

    var etatImageURLComplete: URL? {
        guard let etatImageUrl else { return nil }
        if etatImageUrl.hasPrefix("http") {
            return URL(string: etatImageUrl)
        }
        return URL(string: APIService.shared.baseURL + etatImageUrl)
    }

    var notificationKey: String? {
        guard let etatModifieLe else { return nil }
        return "\(id)-\(etatModifieLe)"
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
