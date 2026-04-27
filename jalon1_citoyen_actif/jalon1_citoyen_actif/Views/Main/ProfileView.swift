// ProfileView.swift
// Affiche les informations du profil de l'utilisateur connecté

import SwiftUI
import SwiftData

struct ProfileView: View {

    @Environment(AuthViewModel.self) var authVM
    @Environment(ReportViewModel.self) var reportVM

    var body: some View {
        NavigationStack {
            if let user = authVM.utilisateurConnecte {

                List {
                    // En-tête avec avatar et nom
                    Section {
                        HStack(spacing: 16) {
                            // Avatar avec initiales
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 60, height: 60)
                                Text("\(user.prenom.prefix(1))\(user.nom.prefix(1))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(user.prenom) \(user.nom)")
                                    .font(.headline)
                                Text(user.courriel)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                // Badge de rôle
                                Text(labelRole(user.role))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(couleurRole(user.role).opacity(0.15))
                                    .foregroundColor(couleurRole(user.role))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    // Infos personnelles
                    Section(header: Text("Mes informations")) {
                        InfoLigneView(label: "Téléphone", valeur: user.telephone)
                        // L'adresse s'affiche seulement pour les citoyens
                        if user.role == .citoyen {
                            InfoLigneView(label: "Adresse", valeur: user.adresse)
                        }
                        if let numAgent = user.numeroAgent {
                            InfoLigneView(label: "No. agent", valeur: numAgent)
                        }
                    }

                    // Section différente selon le rôle
                    if user.role == .citoyen {
                        // Le citoyen voit ses propres rapports
                        Section(header: Text("Mes rapports")) {
                            let mesRapports = reportVM.rapportsDuCitoyen(id: user.id)
                            InfoLigneView(label: "Total envoyés",
                                          valeur: "\(mesRapports.count)")
                            InfoLigneView(label: "En attente",
                                          valeur: "\(mesRapports.filter { $0.etat == .enAttente }.count)")
                            InfoLigneView(label: "En cours",
                                          valeur: "\(mesRapports.filter { $0.etat == .enCours }.count)")
                            InfoLigneView(label: "Réparés",
                                          valeur: "\(mesRapports.filter { $0.etat == .repare }.count)")
                        }
                    } else {
                        // L'employé/agent voit les statistiques globales de la ville
                        Section(header: Text("Statistiques globales")) {
                            let tous = reportVM.tousLesRapports
                            InfoLigneView(label: "Total des rapports",
                                          valeur: "\(tous.count)")
                            InfoLigneView(label: "En attente",
                                          valeur: "\(tous.filter { $0.etat == .enAttente }.count)")
                            InfoLigneView(label: "En cours",
                                          valeur: "\(tous.filter { $0.etat == .enCours }.count)")
                            InfoLigneView(label: "Réparés",
                                          valeur: "\(tous.filter { $0.etat == .repare }.count)")
                            InfoLigneView(label: "Ignorés",
                                          valeur: "\(tous.filter { $0.etat == .ignore }.count)")
                        }
                    }

                    // Bouton de déconnexion
                    Section {
                        Button(role: .destructive, action: {
                            authVM.deconnexion()
                        }) {
                            HStack {
                                Spacer()
                                Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("Mon profil")

            } else {
                Text("Aucun utilisateur connecté.")
                    .foregroundColor(.gray)
            }
        }
    }

    // Texte du rôle en français
    func labelRole(_ role: UserRole) -> String {
        switch role {
        case .citoyen: return "Citoyen"
        case .employe: return "Employé municipal"
        case .agent:   return "Agent municipal"
        }
    }

    // Couleur selon le rôle
    func couleurRole(_ role: UserRole) -> Color {
        switch role {
        case .citoyen: return .blue
        case .employe: return .orange
        case .agent:   return .purple
        }
    }
}

// Vue réutilisable pour une ligne label : valeur
struct InfoLigneView: View {
    var label: String
    var valeur: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(valeur)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Report.self, configurations: config)
    let authVM = AuthViewModel(modelContext: container.mainContext)
    let reportVM = ReportViewModel(modelContext: container.mainContext)
    
    ProfileView()
        .environment(authVM)
        .environment(reportVM)
        .modelContainer(container)
}
