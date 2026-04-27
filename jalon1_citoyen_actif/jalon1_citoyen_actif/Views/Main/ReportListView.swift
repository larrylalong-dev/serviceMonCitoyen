// ReportListView.swift
// Liste des rapports avec filtre "mes rapports" / "tous les rapports"

import SwiftUI
import SwiftData

struct ReportListView: View {

    @Environment(AuthViewModel.self) var authVM
    @Environment(ReportViewModel.self) var reportVM

    // 0 = tous les rapports, 1 = mes rapports
    @State private var filtreSelection: Int = 0

    // Contrôle l'affichage du sheet d'ajout
    @State private var afficherAjout: Bool = false

    // Les rapports à afficher selon le filtre choisi
    var rapportsAffiches: [ReportDTO] {
        if filtreSelection == 1, let user = authVM.utilisateurConnecte {
            return reportVM.rapportsDuCitoyen(id: user.id)
        }
        return reportVM.tousLesRapports
    }

    // Vrai si l'utilisateur est un citoyen (peut ajouter des rapports)
    var estCitoyen: Bool {
        authVM.utilisateurConnecte?.role == .citoyen
    }

    // Vrai si l'utilisateur est un employé ou un agent (peut changer les états)
    var estPersonnelMunicipal: Bool {
        authVM.utilisateurConnecte?.role == .employe ||
        authVM.utilisateurConnecte?.role == .agent
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Picker segmenté : Tous / Mes rapports
                Picker("Filtre", selection: $filtreSelection) {
                    Text("Tous les rapports").tag(0)
                    // Le citoyen peut voir "Mes rapports", le personnel voit "Assignés"
                    if estCitoyen {
                        Text("Mes rapports").tag(1)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Si aucun rapport, on affiche un message
                if rapportsAffiches.isEmpty {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Aucun rapport à afficher")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    Spacer()
                } else {
                    // La liste des rapports
                    List(rapportsAffiches) { rapport in
                        // Envelopper chaque ligne dans un NavigationLink
                        NavigationLink(destination: ReportDetailView(rapport: rapport)) {
                            // Le citoyen voit la carte normale
                            // L'employé/agent voit la carte avec les boutons d'action
                            if estPersonnelMunicipal {
                                ReportRowEmployeView(rapport: rapport)
                                    .environment(reportVM)
                            } else {
                                ReportRowView(rapport: rapport)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Rapports de bris")
            .toolbar {
                // Seul le citoyen peut ajouter un nouveau rapport
                if estCitoyen {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            afficherAjout = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }
            // Le sheet s'ouvre par-dessus la liste
            .sheet(isPresented: $afficherAjout) {
                AddReportView(estPresente: $afficherAjout)
                    .environment(authVM)
                    .environment(reportVM)
            }
        }
    }
}

// Carte d'un rapport pour le CITOYEN (lecture seulement)
struct ReportRowView: View {
    var rapport: ReportDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack(alignment: .top, spacing: 10) {
                // Icône de catégorie
                Image(systemName: iconeCategorie(rapport.categorie))
                    .foregroundColor(.white)
                    .padding(7)
                    .background(couleurEtat(rapport.etat))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(rapport.titre)
                        .font(.headline)
                    Text(rapport.categorie.label)
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()

                // Badge état
                Text(rapport.etat.label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(couleurEtat(rapport.etat).opacity(0.15))
                    .foregroundColor(couleurEtat(rapport.etat))
                    .clipShape(Capsule())
                
                // Miniature image si disponible
                if let imageData = rapport.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .cornerRadius(6)
                        .clipped()
                }
            }

            // Adresse
            Label(rapport.adresse, systemImage: "mappin")
                .font(.caption)
                .foregroundColor(.secondary)

            // Date + nom du citoyen
            HStack {
                Text(rapport.date)
                Spacer()
                Text("par \(rapport.citoyenNom)")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    func iconeCategorie(_ cat: ReportCategorie) -> String {
        switch cat {
        case .eclairage:     return "lightbulb.fill"
        case .voirie:        return "road.lanes"
        case .mobilier:      return "chair.lounge.fill"
        case .espacesVerts:  return "leaf.fill"
        case .signalisation: return "exclamationmark.triangle.fill"
        }
    }

    func couleurEtat(_ etat: ReportEtat) -> Color {
        switch etat {
        case .enAttente: return .orange
        case .enCours:   return .blue
        case .repare:    return .green
        case .ignore:    return .gray
        }
    }
}

// Carte d'un rapport pour l'EMPLOYÉ/AGENT avec boutons d'action
struct ReportRowEmployeView: View {
    var rapport: ReportDTO

    @Environment(ReportViewModel.self) var reportVM

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconeCategorie(rapport.categorie))
                    .foregroundColor(.white)
                    .padding(7)
                    .background(couleurEtat(rapport.etat))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(rapport.titre)
                        .font(.headline)
                    Text(rapport.categorie.label)
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(rapport.etat.label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(couleurEtat(rapport.etat).opacity(0.15))
                    .foregroundColor(couleurEtat(rapport.etat))
                    .clipShape(Capsule())
                
                // Miniature image si disponible
                if let imageData = rapport.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .cornerRadius(6)
                        .clipped()
                }
            }

            Label(rapport.adresse, systemImage: "mappin")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text(rapport.date)
                Spacer()
                Text("par \(rapport.citoyenNom)")
            }
            .font(.caption2)
            .foregroundColor(.secondary)

            // Boutons d'action réservés au personnel municipal
            // On n'affiche que les actions pertinentes selon l'état actuel
            if rapport.etat == .enAttente {
                HStack(spacing: 8) {
                    // Prendre en charge
                    Button(action: {
                        reportVM.changerEtat(rapportId: rapport.id, nouvelEtat: .enCours)
                    }) {
                        Label("Prendre en charge", systemImage: "wrench.fill")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    // Ignorer (faux signalement)
                    Button(action: {
                        reportVM.changerEtat(rapportId: rapport.id, nouvelEtat: .ignore)
                    }) {
                        Label("Ignorer", systemImage: "xmark.circle")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.gray)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            } else if rapport.etat == .enCours {
                // Marquer comme réparé
                Button(action: {
                    reportVM.changerEtat(rapportId: rapport.id, nouvelEtat: .repare)
                }) {
                    Label("Marquer comme réparé", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    func iconeCategorie(_ cat: ReportCategorie) -> String {
        switch cat {
        case .eclairage:     return "lightbulb.fill"
        case .voirie:        return "road.lanes"
        case .mobilier:      return "chair.lounge.fill"
        case .espacesVerts:  return "leaf.fill"
        case .signalisation: return "exclamationmark.triangle.fill"
        }
    }

    func couleurEtat(_ etat: ReportEtat) -> Color {
        switch etat {
        case .enAttente: return .orange
        case .enCours:   return .blue
        case .repare:    return .green
        case .ignore:    return .gray
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Report.self, configurations: config)
    let authVM = AuthViewModel(modelContext: container.mainContext)
    let reportVM = ReportViewModel(modelContext: container.mainContext)
    
    ReportListView()
        .environment(authVM)
        .environment(reportVM)
        .modelContainer(container)
}
