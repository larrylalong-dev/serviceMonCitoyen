// ReportDetailView.swift
// Page moderne de détail complet d'un rapport de bris

import SwiftUI
import SwiftData
import UIKit

struct ReportDetailView: View {

    let rapport: ReportDTO

    @Environment(AuthViewModel.self) var authVM
    @Environment(ReportViewModel.self) var reportVM
    @Environment(\.dismiss) var dismiss

    @State private var nouvelEtat: ReportEtat
    @State private var noteEtat = ""
    @State private var photoEtat: UIImage? = nil
    @State private var afficherImagePicker = false
    @State private var miseAJourEnCours = false
    @State private var messageLocal = ""

    init(rapport: ReportDTO) {
        self.rapport = rapport
        _nouvelEtat = State(initialValue: rapport.etat)
    }

    var estAgent: Bool {
        authVM.utilisateurConnecte?.role == .agent
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ReportHeroImage(rapport: rapport)

                    VStack(alignment: .leading, spacing: 16) {
                        headerSection
                        descriptionSection
                        locationSection
                        reporterSection
                        informationSection

                        if rapport.etatDescription != nil || rapport.etatImageUrl != nil {
                            statusEvidenceSection
                        }

                        if estAgent {
                            agentUpdateSection
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $afficherImagePicker) {
            ImagePicker(selectedImage: $photoEtat, sourceType: .camera)
        }
    }

    var headerSection: some View {
        ReportDetailCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconeCategorie(rapport.categorie))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(couleurEtat(rapport.etat))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(rapport.titre)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(rapport.categorie.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(couleurEtat(rapport.etat))
                }

                Spacer()

                ReportStatusBadge(etat: rapport.etat, color: couleurEtat(rapport.etat))
            }
        }
    }

    var descriptionSection: some View {
        ReportDetailCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Description", systemImage: "doc.text.fill")
                    .font(.headline)
                Text(rapport.details.isEmpty ? "Aucune description fournie." : rapport.details)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }

    var locationSection: some View {
        ReportDetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Localisation", systemImage: "mappin.circle.fill")
                    .font(.headline)
                    .foregroundColor(.red)

                Button(action: ouvrirDansPlans) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "map.fill")
                            .foregroundColor(.red)
                        Text(rapport.adresse)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 16) {
                    coordinateView(label: "Latitude", value: rapport.latitude)
                    Divider()
                    coordinateView(label: "Longitude", value: rapport.longitude)
                }
                .padding(.top, 4)
            }
        }
    }

    var reporterSection: some View {
        ReportDetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Signalé par", systemImage: "person.circle.fill")
                    .font(.headline)
                    .foregroundColor(.blue)

                HStack(spacing: 12) {
                    Text(String(rapport.citoyenNom.prefix(2)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(rapport.citoyenNom)
                            .fontWeight(.semibold)
                        Text("ID: \(rapport.citoyenId)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
    }

    var informationSection: some View {
        ReportDetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Informations", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundColor(.orange)

                infoLine(icon: "calendar", title: "Date du signalement", value: rapport.date, color: .orange)
                Divider()
                infoLine(icon: "checkmark.circle", title: "État actuel", value: rapport.etat.label, color: couleurEtat(rapport.etat))
            }
        }
    }

    var statusEvidenceSection: some View {
        ReportDetailCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Dernière mise à jour", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundColor(.green)

                if let agent = rapport.etatModifieParNom {
                    Text("Par \(agent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let date = rapport.etatModifieLe {
                    Text(date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let description = rapport.etatDescription {
                    Text(description)
                        .foregroundColor(.primary)
                }

                if let imageURL = rapport.etatImageURLComplete {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .clipped()
                }
            }
        }
    }

    var agentUpdateSection: some View {
        ReportDetailCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Action agent", systemImage: "shield.lefthalf.filled")
                    .font(.headline)
                    .foregroundColor(.purple)

                Picker("Nouvel état", selection: $nouvelEtat) {
                    ForEach(ReportEtat.allCases, id: \.self) { etat in
                        Text(etat.label).tag(etat)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Note de mise à jour")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $noteEtat)
                        .frame(minHeight: 96)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if let photoEtat {
                    Image(uiImage: photoEtat)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 170)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .clipped()
                }

                HStack {
                    Button {
                        afficherImagePicker = true
                    } label: {
                        Label(photoEtat == nil ? "Ajouter une photo" : "Changer la photo", systemImage: "camera.fill")
                    }
                    .buttonStyle(.bordered)

                    if photoEtat != nil {
                        Button(role: .destructive) {
                            photoEtat = nil
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if !messageLocal.isEmpty || !reportVM.messageErreur.isEmpty {
                    Text(messageLocal.isEmpty ? reportVM.messageErreur : messageLocal)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Button(action: soumettreMiseAJour) {
                    HStack {
                        if miseAJourEnCours {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Enregistrer la mise à jour")
                        }
                    }
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(miseAJourEnCours)
            }
        }
    }

    func coordinateView(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.4f", value))
                .font(.caption)
                .fontWeight(.bold)
                .monospaced()
        }
    }

    func infoLine(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }

    func ouvrirDansPlans() {
        let query = rapport.adresse.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Rapport"
        if let url = URL(string: "http://maps.apple.com/?ll=\(rapport.latitude),\(rapport.longitude)&q=\(query)") {
            UIApplication.shared.open(url)
        }
    }

    func soumettreMiseAJour() {
        let note = noteEtat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard note.count >= 5 else {
            messageLocal = "Ajoute une note d’au moins 5 caractères pour expliquer l’action."
            return
        }

        messageLocal = ""
        miseAJourEnCours = true

        Task {
            let imageData = photoEtat?.jpegData(compressionQuality: 0.8)
            let success = await reportVM.changerEtat(
                rapportId: rapport.id,
                nouvelEtat: nouvelEtat,
                description: note,
                imageData: imageData
            )
            await MainActor.run {
                miseAJourEnCours = false
                if success {
                    dismiss()
                }
            }
        }
    }

    func iconeCategorie(_ cat: ReportCategorie) -> String {
        switch cat {
        case .eclairage: return "lightbulb.fill"
        case .voirie: return "road.lanes"
        case .mobilier: return "chair.lounge.fill"
        case .espacesVerts: return "leaf.fill"
        case .signalisation: return "exclamationmark.triangle.fill"
        }
    }

    func couleurEtat(_ etat: ReportEtat) -> Color {
        switch etat {
        case .enAttente: return .orange
        case .enCours: return .blue
        case .repare: return .green
        case .ignore: return .gray
        }
    }
}

struct ReportHeroImage: View {
    let rapport: ReportDTO

    var body: some View {
        Group {
            if let imageURL = rapport.imageURLComplete {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .background(Color(.systemGray5))
                }
            } else if let imageData = rapport.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Aucune photo disponible")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .background(Color(.systemGray5))
            }
        }
        .frame(height: 250)
        .clipped()
        .overlay(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.32), Color.clear]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            alignment: .topLeading
        )
    }
}

struct ReportDetailCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
            .padding(.horizontal)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Report.self, configurations: config)
    let authVM = AuthViewModel(modelContext: container.mainContext)
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

    NavigationStack {
        ReportDetailView(rapport: rapport)
            .environment(authVM)
            .environment(reportVM)
            .modelContainer(container)
    }
}
