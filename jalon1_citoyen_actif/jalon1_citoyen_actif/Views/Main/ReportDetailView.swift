// ReportDetailView.swift
// Page de détail complet d'un rapport de bris

import SwiftUI
import SwiftData

struct ReportDetailView: View {
    
    var rapport: ReportDTO
    @Environment(ReportViewModel.self) var reportVM
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond dégradé
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color.white]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // Image principale en haut
                        if let imageData = rapport.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 250)
                                .clipped()
                                .overlay(
                                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), Color.clear]),
                                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                                    alignment: .topLeading
                                )
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("Aucune photo disponible")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .background(Color(.systemGray5))
                        }
                        
                        // Contenu principal
                        VStack(alignment: .leading, spacing: 16) {
                            
                            // En-tête avec titre et état
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: iconeCategorie(rapport.categorie))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(couleurEtat(rapport.etat))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(rapport.titre)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text(rapport.categorie.label)
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(rapport.etat.label)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(couleurEtat(rapport.etat).opacity(0.2))
                                        .foregroundColor(couleurEtat(rapport.etat))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Description", systemImage: "doc.text")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(rapport.details)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(2)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Localisation
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Localisation", systemImage: "mappin.circle.fill")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                
                                Text(rapport.adresse)
                                    .font(.body)
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Latitude")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.4f", rapport.latitude))
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .monospaced()
                                    }
                                    
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Longitude")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.4f", rapport.longitude))
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .monospaced()
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Signalant
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Signalé par", systemImage: "person.circle.fill")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.5)]),
                                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                            )
                                        Text(rapport.citoyenNom.prefix(2).uppercased())
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 44, height: 44)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(rapport.citoyenNom)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                        Text("ID: \(rapport.citoyenId)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Informations temporelles
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Informations", systemImage: "info.circle.fill")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.orange)
                                        .frame(width: 24)
                                    Text("Date du signalement")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(rapport.date)
                                        .fontWeight(.semibold)
                                }
                                
                                Divider()
                                    .padding(.vertical, 4)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(couleurEtat(rapport.etat))
                                        .frame(width: 24)
                                    Text("État actuel")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(rapport.etat.label)
                                        .fontWeight(.semibold)
                                        .foregroundColor(couleurEtat(rapport.etat))
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
    let reportVM = ReportViewModel(modelContext: container.mainContext)
    
    let rapport = ReportDTO(
        id: "r1",
        titre: "Lampadaire éteint",
        details: "Le lampadaire au coin est éteint depuis 3 jours et crée un risque de sécurité.",
        categorie: .eclairage,
        etat: .enAttente,
        date: "2026-03-01",
        adresse: "123 Rue des Forges, Trois-Rivières",
        latitude: 46.3432,
        longitude: -72.5424,
        citoyenId: "u1",
        citoyenNom: "Marie Tremblay",
        imageData: nil
    )
    
    ReportDetailView(rapport: rapport)
        .environment(reportVM)
        .modelContainer(container)
}
