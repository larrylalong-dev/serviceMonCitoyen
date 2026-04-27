//
//  ContentView.swift
//  jalon1_citoyen_actif
//
//  Created by Larry Lalong on 2026-03-01.
//

import SwiftUI
import SwiftData

// Point d'entrée de la navigation :
// Si personne n'est connecté → on affiche la page de connexion
// Si un utilisateur est connecté → on affiche les onglets principaux
struct ContentView: View {

    // On observe le ViewModel d'authentification pour savoir si un utilisateur est connecté
    @Environment(AuthViewModel.self) var authVM

    var body: some View {
        if authVM.utilisateurConnecte != nil {
            // L'utilisateur est connecté, on affiche les onglets
            MainTabView()
        } else {
            // Personne n'est connecté, on affiche la connexion
            LoginView()
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Report.self, configurations: config)
    let authVM = AuthViewModel(modelContext: container.mainContext)
    let reportVM = ReportViewModel(modelContext: container.mainContext)
    
    ContentView()
        .environment(authVM)
        .environment(reportVM)
        .modelContainer(container)
}
