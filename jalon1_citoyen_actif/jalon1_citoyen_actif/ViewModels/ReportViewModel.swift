// ReportViewModel.swift
// Gère la liste des rapports : chargement, ajout, filtrage

import Foundation
import Observation
import SwiftData

// @Observable remplace ObservableObject en Swift moderne
@Observable
class ReportViewModel {

    // Le contexte SwiftData injecté
    var modelContext: ModelContext

    // La liste complète des rapports (DTO) - ce que les vues reçoivent
    var tousLesRapports: [ReportDTO] = []

    // Initialisation avec un ModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        chargerRapports()
    }

    // Charge les rapports depuis SwiftData et les convertit en DTO
    func chargerRapports() {
        do {
            let descriptor = FetchDescriptor<Report>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let reports = try modelContext.fetch(descriptor)
            // Convertir tous les Report en ReportDTO
            tousLesRapports = reports.map { $0.toDTO() }
        } catch {
            print("Erreur lors du chargement des rapports: \(error)")
            tousLesRapports = []
        }
    }

    // Retourne seulement les rapports d'un utilisateur spécifique
    func rapportsDuCitoyen(id: String) -> [ReportDTO] {
        return tousLesRapports.filter { $0.citoyenId == id }
    }

    // Change l'état d'un rapport (utilisé par les employés et agents)
    func changerEtat(rapportId: String, nouvelEtat: ReportEtat) {
        // Chercher le rapport dans SwiftData
        let predicate = #Predicate<Report> { $0.id == rapportId }
        do {
            let descriptor = FetchDescriptor<Report>(predicate: predicate)
            let results = try modelContext.fetch(descriptor)
            if let report = results.first {
                report.etat = nouvelEtat
                try modelContext.save()
                // Recharger pour s'assurer que tout est synchronisé
                chargerRapports()
            }
        } catch {
            print("Erreur lors de la sauvegarde: \(error)")
        }
    }

    // Ajoute un nouveau rapport à SwiftData (depuis DTO)
    func ajouterRapportDTO(_ reportDTO: ReportDTO) {
        // Convertir le DTO en modèle SwiftData et sauvegarder
        let rapport = reportDTO.toModel()
        modelContext.insert(rapport)
        do {
            try modelContext.save()
            chargerRapports()
        } catch {
            print("Erreur lors de l'ajout du rapport: \(error)")
        }
    }

    // Ajoute un nouveau rapport avec image à SwiftData
    func ajouterRapportAvecImageEtCoordonnees(titre: String, details: String,
                                               categorie: ReportCategorie, adresse: String,
                                               latitude: Double, longitude: Double,
                                               citoyenId: String, citoyenNom: String,
                                               imageData: Data?) {
        // Créer le DTO
        let reportDTO = ReportDTO(
            id: UUID().uuidString,
            titre: titre,
            details: details,
            categorie: categorie,
            etat: .enAttente,
            date: ISO8601DateFormatter().string(from: Date()),
            adresse: adresse,
            latitude: latitude,
            longitude: longitude,
            citoyenId: citoyenId,
            citoyenNom: citoyenNom,
            imageData: imageData
        )
        // Convertir en modèle SwiftData et sauvegarder
        let rapport = reportDTO.toModel()
        modelContext.insert(rapport)
        do {
            try modelContext.save()
            chargerRapports()
        } catch {
            print("Erreur lors de l'ajout du rapport: \(error)")
        }
    }
}
