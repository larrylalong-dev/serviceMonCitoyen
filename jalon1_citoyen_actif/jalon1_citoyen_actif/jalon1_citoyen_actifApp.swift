//
//  jalon1_citoyen_actifApp.swift
//  jalon1_citoyen_actif
//

import SwiftUI
import SwiftData

@main
struct jalon1_citoyen_actifApp: App {

    // Crée un ModelContainer partagé pour SwiftData
    let modelContainer: ModelContainer

    // ViewModels peuvent recevoir le ModelContext si nécessaire
    @State var authVM: AuthViewModel
    @State var reportVM: ReportViewModel

    init() {
        // Crée le container pour les modèles User et Report
        do {
            modelContainer = try ModelContainer(for: User.self, Report.self)
        } catch {
            fatalError("Impossible de créer ModelContainer: \(error)")
        }

        // Fournir un modelContext aux ViewModels
        let context = modelContainer.mainContext
        _authVM = State(wrappedValue: AuthViewModel(modelContext: context))
        _reportVM = State(wrappedValue: ReportViewModel(modelContext: context))

        // Seed initiale : si la base est vide, on charge depuis reports.json
        seedIfNeeded(context: context)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authVM)
                .environment(reportVM)
                .modelContainer(modelContainer)
        }
    }

    // Routine de seed : lit reports.json et insère les rapports si aucun n'existe
    func seedIfNeeded(context: ModelContext) {
        // On vérifie s'il y a déjà des rapports
        do {
            let existing = try context.fetch(FetchDescriptor<Report>())
            if !existing.isEmpty { return }
        } catch {
            // Si la vérification échoue, on continue et on essaie d'insérer
        }

        guard let url = Bundle.main.url(forResource: "reports", withExtension: "json") else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            // On utilise une structure temporaire compatible avec l'ancien JSON
            struct ReportCodable: Codable {
                var id: String
                var titre: String
                var description: String
                var categorie: String
                var etat: String
                var date: String
                var adresse: String
                var latitude: Double
                var longitude: Double
                var citoyenId: String
                var citoyenNom: String
            }
            let anciens = try decoder.decode([ReportCodable].self, from: data)
            for ancien in anciens {
                // Convertit les chaînes en enums en tenant compte des valeurs
                let categorie = ReportCategorie(rawValue: ancien.categorie) ?? .voirie
                let etat = ReportEtat(rawValue: ancien.etat) ?? .enAttente
                let r = Report(id: ancien.id,
                               titre: ancien.titre,
                               details: ancien.description,
                               categorie: categorie,
                               etat: etat,
                               date: ancien.date,
                               adresse: ancien.adresse,
                               latitude: ancien.latitude,
                               longitude: ancien.longitude,
                               citoyenId: ancien.citoyenId,
                               citoyenNom: ancien.citoyenNom)
                context.insert(r)
            }
            try context.save()
        } catch {
            // En cas d'erreur on ne bloque pas l'app, mais on affiche un log
            print("Seed SwiftData failed: \(error)")
        }
    }
}
