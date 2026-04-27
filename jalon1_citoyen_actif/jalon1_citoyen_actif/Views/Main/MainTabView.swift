// MainTabView.swift
// Vue principale avec les 3 onglets : Liste, Carte, Profil

import SwiftUI
import SwiftData

struct MainTabView: View {

    // On récupère les ViewModels pour les passer aux vues enfants
    @Environment(AuthViewModel.self) var authVM
    @Environment(ReportViewModel.self) var reportVM

    var body: some View {
        TabView {

            // Onglet 1 : Liste des rapports
            // Le titre et les actions dans cet onglet changent selon le rôle
            ReportListView()
                .environment(authVM)
                .environment(reportVM)
                .tabItem {
                    Label("Rapports", systemImage: "list.bullet")
                }

            // Onglet 2 : Carte des rapports
            MapView()
                .environment(authVM)
                .environment(reportVM)
                .tabItem {
                    Label("Carte", systemImage: "map")
                }

            // Onglet 3 : Profil de l'utilisateur
            ProfileView()
                .environment(authVM)
                .environment(reportVM)
                .tabItem {
                    Label("Profil", systemImage: "person.circle")
                }
        }
        // Badge de rôle affiché en haut si c'est un employé ou agent
        .overlay(alignment: .top) {
            if let user = authVM.utilisateurConnecte, user.role != .citoyen {
                HStack {
                    Image(systemName: user.role == .agent ? "shield.fill" : "wrench.fill")
                    Text(user.role == .agent ? "Mode Agent municipal" : "Mode Employé municipal")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(user.role == .agent ? Color.purple : Color.orange)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Report.self, configurations: config)
    let authVM = AuthViewModel(modelContext: container.mainContext)
    let reportVM = ReportViewModel(modelContext: container.mainContext)
    
    MainTabView()
        .environment(authVM)
        .environment(reportVM)
        .modelContainer(container)
}
