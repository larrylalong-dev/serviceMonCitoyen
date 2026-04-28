// ReportViewModel.swift
// Gère la liste des rapports : chargement, ajout, filtrage

import Foundation
import Observation
import SwiftData

// @Observable remplace ObservableObject en Swift moderne
@MainActor
@Observable
class ReportViewModel {

    // Le contexte SwiftData injecté
    var modelContext: ModelContext

    // La liste complète des rapports (DTO) - ce que les vues reçoivent
    var tousLesRapports: [ReportDTO] = []
    var messageErreur: String = ""
    var estEnChargement: Bool = false

    private let api = APIService.shared

    // Initialisation avec un ModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        chargerRapports()
    }

    // Charge les rapports depuis le backend Railway
    func chargerRapports() {
        messageErreur = ""
        estEnChargement = true

        Task {
            defer { estEnChargement = false }
            do {
                tousLesRapports = try await api.listerRapports()
            } catch let error as APIError {
                messageErreur = error.localizedDescription
                tousLesRapports = []
            } catch {
                messageErreur = "Erreur réseau: \(error.localizedDescription)"
                tousLesRapports = []
            }
        }
    }

    // Retourne seulement les rapports d'un utilisateur spécifique
    func rapportsDuCitoyen(id: String) -> [ReportDTO] {
        return tousLesRapports.filter { $0.citoyenId == id }
    }

    // Change l'état d'un rapport via le backend
    @discardableResult
    func changerEtat(rapportId: String, nouvelEtat: ReportEtat,
                     description: String, imageData: Data?) async -> Bool {
        messageErreur = ""

        do {
            let updated = try await api.changerEtat(
                rapportId: rapportId,
                nouvelEtat: nouvelEtat,
                description: description,
                imageData: imageData
            )
            if let index = tousLesRapports.firstIndex(where: { $0.id == rapportId }) {
                tousLesRapports[index] = updated
            } else {
                tousLesRapports.insert(updated, at: 0)
            }
            return true
        } catch let error as APIError {
            messageErreur = error.localizedDescription
        } catch {
            messageErreur = "Erreur réseau: \(error.localizedDescription)"
        }
        return false
    }

    func changerEtat(rapportId: String, nouvelEtat: ReportEtat) {
        Task {
            await changerEtat(
                rapportId: rapportId,
                nouvelEtat: nouvelEtat,
                description: "Mise à jour de l’état depuis l’application mobile.",
                imageData: nil
            )
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

    // Ajoute un nouveau rapport avec image via le backend
    func ajouterRapportAvecImageEtCoordonnees(titre: String, details: String,
                                               categorie: ReportCategorie, adresse: String,
                                               latitude: Double, longitude: Double,
                                               citoyenId: String, citoyenNom: String,
                                               imageData: Data?) {
        messageErreur = ""

        Task {
            do {
                let report = try await api.creerRapport(
                    titre: titre,
                    details: details,
                    categorie: categorie,
                    adresse: adresse,
                    latitude: latitude,
                    longitude: longitude,
                    imageData: imageData
                )
                tousLesRapports.insert(report, at: 0)
            } catch let error as APIError {
                messageErreur = error.localizedDescription
            } catch {
                messageErreur = "Erreur réseau: \(error.localizedDescription)"
            }
        }
    }
}
