// MapView.swift
// Vue Carte - affiche les rapports sur une carte

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {

    @Environment(AuthViewModel.self) var authVM
    @Environment(ReportViewModel.self) var reportVM

    // 0 = tous les rapports, 1 = mes rapports
    @State private var filtreSelection: Int = 0

    // Contrôle l'affichage du sheet d'ajout
    @State private var afficherAjout: Bool = false
    
    // Rapport sélectionné pour navigation vers détail
    @State private var rapportSelectionne: ReportDTO? = nil

    // Région centrée sur Trois-Rivières
    let regionInitiale = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.3432, longitude: -72.5424),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    // Les rapports à afficher selon le filtre
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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Picker segmenté en haut
                Picker("Filtre", selection: $filtreSelection) {
                    Text("Tous les rapports").tag(0)
                    // "Mes rapports" seulement pour les citoyens
                    if estCitoyen {
                        Text("Mes rapports").tag(1)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // La carte avec les épingles cliquables
                Map(initialPosition: regionInitiale) {
                    ForEach(rapportsAffiches) { rapport in
                        Annotation(rapport.titre,
                                   coordinate: CLLocationCoordinate2D(
                                    latitude: rapport.latitude,
                                    longitude: rapport.longitude)) {
                            // Épingle colorée selon l'état
                            Button(action: {
                                rapportSelectionne = rapport
                            }) {
                                Image(systemName: iconeCategorie(rapport.categorie))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(couleurEtat(rapport.etat))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                        }
                    }
                }
                .navigationDestination(item: $rapportSelectionne) { rapport in
                    ReportDetailView(rapport: rapport)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("Carte des bris")
            .toolbar {
                // Seul le citoyen peut ajouter un rapport depuis la carte
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
            .sheet(isPresented: $afficherAjout) {
                AddReportView(estPresente: $afficherAjout)
                    .environment(authVM)
                    .environment(reportVM)
            }
        }
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
    
    MapView()
        .environment(authVM)
        .environment(reportVM)
        .modelContainer(container)
}
