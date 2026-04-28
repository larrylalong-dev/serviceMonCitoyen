import SwiftUI
import SwiftData

struct UsersAdminView: View {

    @Environment(UserViewModel.self) var userVM
    @Environment(AuthViewModel.self) var authVM

    @State private var utilisateurEdite: UserDTO? = nil
    @State private var utilisateurASupprimer: UserDTO? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if userVM.estEnChargement && userVM.utilisateurs.isEmpty {
                    ProgressView("Chargement des utilisateurs...")
                } else if userVM.utilisateurs.isEmpty {
                    ContentUnavailableView("Aucun utilisateur", systemImage: "person.3")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if !userVM.messageErreur.isEmpty {
                                Text(userVM.messageErreur)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.red.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }

                            ForEach(userVM.utilisateurs) { user in
                                UserAdminCard(
                                    user: user,
                                    isCurrentUser: user.id == authVM.utilisateurConnecte?.id,
                                    onEdit: { utilisateurEdite = user },
                                    onDelete: { utilisateurASupprimer = user }
                                )
                            }
                        }
                        .padding(16)
                    }
                    .refreshable {
                        userVM.chargerUtilisateurs()
                    }
                }
            }
            .navigationTitle("Utilisateurs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { userVM.chargerUtilisateurs() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(item: $utilisateurEdite) { user in
                UserEditSheet(user: user)
                    .environment(userVM)
            }
            .confirmationDialog(
                "Supprimer cet utilisateur ?",
                isPresented: Binding(
                    get: { utilisateurASupprimer != nil },
                    set: { if !$0 { utilisateurASupprimer = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let user = utilisateurASupprimer {
                    Button("Supprimer \(user.nomComplet)", role: .destructive) {
                        Task {
                            await userVM.supprimerUtilisateur(user)
                            utilisateurASupprimer = nil
                        }
                    }
                }
                Button("Annuler", role: .cancel) {
                    utilisateurASupprimer = nil
                }
            }
            .onAppear {
                if userVM.utilisateurs.isEmpty {
                    userVM.chargerUtilisateurs()
                }
            }
        }
    }
}

struct UserAdminCard: View {
    let user: UserDTO
    let isCurrentUser: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(user.initiales)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(roleColor(user.role))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(user.nomComplet)
                            .font(.headline)
                            .foregroundColor(.primary)
                        if isCurrentUser {
                            Text("Vous")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.12))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }

                    Text(user.courriel)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(user.role.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(roleColor(user.role))
                }

                Spacer()
            }

            HStack {
                Label(user.telephone.isEmpty ? "Téléphone manquant" : user.telephone, systemImage: "phone")
                Spacer()
                if let numero = user.numeroAgent, !numero.isEmpty {
                    Label(numero, systemImage: "number")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button(action: onEdit) {
                    Label("Modifier", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive, action: onDelete) {
                    Label("Supprimer", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isCurrentUser)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }

    func roleColor(_ role: UserRole) -> Color {
        switch role {
        case .citoyen: return .blue
        case .employe: return .orange
        case .agent: return .purple
        }
    }
}

struct UserEditSheet: View {
    let user: UserDTO

    @Environment(UserViewModel.self) var userVM
    @Environment(\.dismiss) var dismiss

    @State private var prenom: String
    @State private var nom: String
    @State private var telephone: String
    @State private var adresse: String
    @State private var role: UserRole
    @State private var numeroAgent: String
    @State private var enregistrement = false

    init(user: UserDTO) {
        self.user = user
        _prenom = State(initialValue: user.prenom)
        _nom = State(initialValue: user.nom)
        _telephone = State(initialValue: user.telephone)
        _adresse = State(initialValue: user.adresse)
        _role = State(initialValue: user.role)
        _numeroAgent = State(initialValue: user.numeroAgent ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identité") {
                    TextField("Prénom", text: $prenom)
                    TextField("Nom", text: $nom)
                    Text(user.courriel)
                        .foregroundColor(.secondary)
                }

                Section("Coordonnées") {
                    TextField("Téléphone", text: $telephone)
                        .keyboardType(.phonePad)
                    TextField("Adresse", text: $adresse)
                }

                Section("Rôle") {
                    Picker("Rôle", selection: $role) {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            Text(role.label).tag(role)
                        }
                    }

                    if role != .citoyen {
                        TextField("Numéro agent/employé", text: $numeroAgent)
                    }
                }

                if !userVM.messageErreur.isEmpty {
                    Section {
                        Text(userVM.messageErreur)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: enregistrer) {
                        if enregistrement {
                            ProgressView()
                        } else {
                            Text("Enregistrer")
                        }
                    }
                    .disabled(enregistrement)
                }
            }
        }
    }

    func enregistrer() {
        enregistrement = true
        Task {
            let success = await userVM.modifierUtilisateur(
                user,
                prenom: prenom,
                nom: nom,
                telephone: telephone,
                adresse: adresse,
                role: role,
                numeroAgent: role == .citoyen ? nil : numeroAgent
            )
            await MainActor.run {
                enregistrement = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    UsersAdminView()
        .environment(UserViewModel())
        .environment(AuthViewModel(modelContext: try! ModelContainer(for: User.self, Report.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext))
}
