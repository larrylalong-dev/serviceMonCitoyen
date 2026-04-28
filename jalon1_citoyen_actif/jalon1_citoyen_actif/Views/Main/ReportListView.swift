// ReportListView.swift
// Liste moderne des rapports avec filtres et notifications de mises à jour

import SwiftUI
import SwiftData

struct ReportListView: View {

    @Environment(AuthViewModel.self) var authVM
    @Environment(ReportViewModel.self) var reportVM

    @State private var filtreSelection: Int = 0
    @State private var filtreEtat: ReportEtat? = nil
    @State private var afficherAjout: Bool = false
    @State private var afficherNotifications = false
    @State private var rapportSelectionne: ReportDTO? = nil
    @State private var notificationsLues: Set<String> = []

    var rapportsDeBase: [ReportDTO] {
        if filtreSelection == 1, let user = authVM.utilisateurConnecte {
            return reportVM.rapportsDuCitoyen(id: user.id)
        }
        return reportVM.tousLesRapports
    }

    var rapportsAffiches: [ReportDTO] {
        guard let filtreEtat else { return rapportsDeBase }
        return rapportsDeBase.filter { $0.etat == filtreEtat }
    }

    var rapportsNotifiables: [ReportDTO] {
        if let user = authVM.utilisateurConnecte, user.role == .citoyen {
            return reportVM.rapportsDuCitoyen(id: user.id)
        }
        return reportVM.tousLesRapports
    }

    var rapportsNotifies: [ReportDTO] {
        rapportsNotifiables.filter { rapport in
            guard let key = rapport.notificationKey else { return false }
            return !notificationsLues.contains(key)
        }
    }

    var estCitoyen: Bool {
        authVM.utilisateurConnecte?.role == .citoyen
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Picker("Filtre", selection: $filtreSelection) {
                            Text("Tous les rapports").tag(0)
                            if estCitoyen {
                                Text("Mes rapports").tag(1)
                            }
                        }
                        .pickerStyle(.segmented)

                        ReportStatusFilterBar(
                            selection: $filtreEtat,
                            rapports: rapportsDeBase
                        )

                        if !reportVM.messageErreur.isEmpty {
                            Label(reportVM.messageErreur, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.red.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGroupedBackground))

                    if rapportsAffiches.isEmpty {
                        Spacer()
                        ContentUnavailableView("Aucun rapport", systemImage: "tray", description: Text("Aucun bris ne correspond au filtre sélectionné."))
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(rapportsAffiches) { rapport in
                                    Button {
                                        ouvrirRapport(rapport)
                                    } label: {
                                        ReportSummaryCard(
                                            rapport: rapport,
                                            showAgentHint: authVM.utilisateurConnecte?.role == .agent,
                                            hasUnreadUpdate: estNonLu(rapport)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                        .refreshable {
                            reportVM.chargerRapports()
                        }
                    }
                }
            }
            .navigationTitle("Rapports de bris")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { afficherNotifications = true }) {
                        NotificationBellButton(count: rapportsNotifies.count)
                    }

                    if estCitoyen {
                        Button(action: { afficherAjout = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }
            .navigationDestination(item: $rapportSelectionne) { rapport in
                ReportDetailView(rapport: rapport)
                    .environment(reportVM)
                    .environment(authVM)
            }
            .sheet(isPresented: $afficherAjout) {
                AddReportView(estPresente: $afficherAjout)
                    .environment(authVM)
                    .environment(reportVM)
            }
            .sheet(isPresented: $afficherNotifications) {
                ReportNotificationsView(rapports: rapportsNotifies) { rapport in
                    afficherNotifications = false
                    ouvrirRapport(rapport)
                }
            }
            .onAppear {
                reportVM.chargerRapports()
                chargerNotificationsLues()
            }
            .onChange(of: authVM.utilisateurConnecte?.id) { _, _ in
                chargerNotificationsLues()
            }
        }
    }

    func estNonLu(_ rapport: ReportDTO) -> Bool {
        guard let key = rapport.notificationKey else { return false }
        return !notificationsLues.contains(key)
    }

    func ouvrirRapport(_ rapport: ReportDTO) {
        marquerCommeLu(rapport)
        rapportSelectionne = rapport
    }

    func userDefaultsKey() -> String {
        "rapport_notifications_lues_\(authVM.utilisateurConnecte?.id ?? "invite")"
    }

    func chargerNotificationsLues() {
        let values = UserDefaults.standard.stringArray(forKey: userDefaultsKey()) ?? []
        notificationsLues = Set(values)
    }

    func marquerCommeLu(_ rapport: ReportDTO) {
        guard let key = rapport.notificationKey else { return }
        notificationsLues.insert(key)
        UserDefaults.standard.set(Array(notificationsLues), forKey: userDefaultsKey())
    }
}

struct NotificationBellButton: View {
    let count: Int

    var body: some View {
        Image(systemName: count == 0 ? "bell" : "bell.fill")
            .font(.title3)
            .frame(width: 34, height: 34)
            .contentShape(Rectangle())
            .overlay(alignment: .topTrailing) {
                if count > 0 {
                    Text(count > 9 ? "9+" : "\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: count > 9 ? 20 : 16, height: 16)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 2, y: -2)
                }
            }
            .accessibilityLabel(Text(count == 0 ? "Aucune notification" : "\(count) notification\(count > 1 ? "s" : "")"))
    }
}

struct ReportStatusFilterBar: View {
    @Binding var selection: ReportEtat?
    let rapports: [ReportDTO]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Filtrer par statut", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.headline)
                Spacer()
                if selection != nil {
                    Button("Réinitialiser") { selection = nil }
                        .font(.caption)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    statusButton(title: "Tous", count: rapports.count, color: .blue, isSelected: selection == nil) {
                        selection = nil
                    }

                    ForEach(ReportEtat.allCases, id: \.self) { etat in
                        statusButton(
                            title: etat.label,
                            count: rapports.filter { $0.etat == etat }.count,
                            color: couleurEtat(etat),
                            isSelected: selection == etat
                        ) {
                            selection = etat
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }

    func statusButton(title: String, count: Int, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isSelected ? Color.white.opacity(0.25) : color.opacity(0.12))
                    .clipShape(Capsule())
            }
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : color)
            .clipShape(Capsule())
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

struct ReportSummaryCard: View {
    let rapport: ReportDTO
    let showAgentHint: Bool
    let hasUnreadUpdate: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconeCategorie(rapport.categorie))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(couleurEtat(rapport.etat))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(rapport.categorie.label)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(couleurEtat(rapport.etat))

                        if hasUnreadUpdate {
                            Label("Mis à jour", systemImage: "bell.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }

                    Text(rapport.titre)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    ReportStatusBadge(etat: rapport.etat, color: couleurEtat(rapport.etat))
                    ReportThumbnail(rapport: rapport)
                }
            }

            Text(rapport.details.isEmpty ? "Aucune description fournie." : rapport.details)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(alignment: .center, spacing: 10) {
                Label(rapport.adresseAbregee, systemImage: "mappin")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Text(rapport.citoyenNom)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if showAgentHint {
                Label("Ouvrir le détail pour gérer l’état", systemImage: "square.and.pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else if rapport.etatDescription != nil {
                Label("Une mise à jour est disponible", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(hasUnreadUpdate ? Color.red.opacity(0.35) : Color(.separator).opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
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

struct ReportThumbnail: View {
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.tertiarySystemGroupedBackground))
                }
            } else if let imageData = rapport.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.tertiarySystemGroupedBackground))
            }
        }
        .frame(width: 68, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ReportStatusBadge: View {
    let etat: ReportEtat
    let color: Color

    var body: some View {
        Text(etat.label)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct ReportNotificationsView: View {
    let rapports: [ReportDTO]
    let onOpen: (ReportDTO) -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if rapports.isEmpty {
                    ContentUnavailableView("Aucune mise à jour", systemImage: "bell", description: Text("Les rapports déjà consultés disparaissent de cette zone."))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(rapports) { rapport in
                                Button {
                                    onOpen(rapport)
                                } label: {
                                    ReportNotificationCard(rapport: rapport)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Mises à jour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

struct ReportNotificationCard: View {
    let rapport: ReportDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(rapport.etat.label, systemImage: "bell.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(rapport.titre)
                .font(.headline)
                .foregroundColor(.primary)

            if let description = rapport.etatDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
