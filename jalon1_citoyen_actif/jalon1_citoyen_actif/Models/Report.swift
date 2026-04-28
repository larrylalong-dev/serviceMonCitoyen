// Report.swift
// Modèle pour représenter un rapport de bris

import Foundation
import SwiftData

// Les catégories possibles pour un bris
enum ReportCategorie: String, Codable, CaseIterable {
    case eclairage      = "eclairage"
    case voirie         = "voirie"
    case mobilier       = "mobilier"
    case espacesVerts   = "espacesVerts"
    case signalisation  = "signalisation"

    // Texte lisible affiché dans l'interface
    var label: String {
        switch self {
        case .eclairage:    return "Éclairage"
        case .voirie:       return "Voirie"
        case .mobilier:     return "Mobilier urbain"
        case .espacesVerts: return "Espaces verts"
        case .signalisation: return "Signalisation"
        }
    }
}

// L'état d'un rapport
enum ReportEtat: String, Codable, CaseIterable {
    case enAttente  = "enAttente"
    case enCours    = "enCours"
    case repare     = "repare"
    case ignore     = "ignore"

    // Texte lisible affiché dans l'interface
    var label: String {
        switch self {
        case .enAttente: return "En attente"
        case .enCours:   return "En cours"
        case .repare:    return "Réparé"
        case .ignore:    return "Ignoré"
        }
    }
}

// Remplacement de la struct par une entité SwiftData (@Model)
@Model
class Report: Identifiable {
    @Attribute(.unique) var id: String
    var titre: String
    var details: String    // Renommé de 'description' (réservé par @Model)
    var categorie: ReportCategorie
    var etat: ReportEtat
    var date: String        // Date en texte pour simplifier
    var adresse: String
    var latitude: Double
    var longitude: Double
    var citoyenId: String   // L'id de l'utilisateur qui a créé le rapport
    var citoyenNom: String  // Le nom affiché dans la liste
    var imageData: Data?    // Image stockée en format binaire

    init(id: String = UUID().uuidString,
         titre: String,
         details: String,
         categorie: ReportCategorie,
         etat: ReportEtat = .enAttente,
         date: String = "",
         adresse: String = "",
         latitude: Double = 0,
         longitude: Double = 0,
         citoyenId: String,
         citoyenNom: String,
         imageData: Data? = nil) {
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
    }
}
