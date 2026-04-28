import Foundation
import Observation

@MainActor
@Observable
class UserViewModel {

    var utilisateurs: [UserDTO] = []
    var estEnChargement = false
    var messageErreur = ""

    private let api = APIService.shared

    func chargerUtilisateurs() {
        messageErreur = ""
        estEnChargement = true

        Task {
            defer { estEnChargement = false }
            do {
                utilisateurs = try await api.listerUtilisateurs()
            } catch let error as APIError {
                messageErreur = error.localizedDescription
            } catch {
                messageErreur = "Erreur réseau: \(error.localizedDescription)"
            }
        }
    }

    @discardableResult
    func modifierUtilisateur(_ user: UserDTO, prenom: String, nom: String,
                             telephone: String, adresse: String,
                             role: UserRole, numeroAgent: String?) async -> Bool {
        do {
            let updated = try await api.modifierUtilisateur(
                userId: user.id,
                prenom: prenom.trimmingCharacters(in: .whitespacesAndNewlines),
                nom: nom.trimmingCharacters(in: .whitespacesAndNewlines),
                telephone: telephone.trimmingCharacters(in: .whitespacesAndNewlines),
                adresse: adresse.trimmingCharacters(in: .whitespacesAndNewlines),
                role: role,
                numeroAgent: numeroAgent?.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            if let index = utilisateurs.firstIndex(where: { $0.id == user.id }) {
                utilisateurs[index] = updated
            }
            messageErreur = ""
            return true
        } catch let error as APIError {
            messageErreur = error.localizedDescription
        } catch {
            messageErreur = "Erreur réseau: \(error.localizedDescription)"
        }
        return false
    }

    @discardableResult
    func supprimerUtilisateur(_ user: UserDTO) async -> Bool {
        do {
            try await api.supprimerUtilisateur(userId: user.id)
            utilisateurs.removeAll { $0.id == user.id }
            messageErreur = ""
            return true
        } catch let error as APIError {
            messageErreur = error.localizedDescription
        } catch {
            messageErreur = "Erreur réseau: \(error.localizedDescription)"
        }
        return false
    }
}
