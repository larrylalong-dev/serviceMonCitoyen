// APIService.swift
// Couche réseau pour communiquer avec le backend Railway CitoyenActif

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case serverError(String)
    case decodingError(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide."
        case .serverError(let message):
            return message
        case .decodingError(let error):
            return "Erreur de décodage: \(error.localizedDescription)"
        case .unauthorized:
            return "Session expirée. Veuillez vous reconnecter."
        }
    }
}

private struct APIErrorResponse: Decodable {
    let erreur: String?
}

private struct ConnexionResponse: Decodable {
    let utilisateur: UserDTO
    let token: String
}

final class APIService {
    static let shared = APIService()

    let baseURL = "https://servicemoncitoyen-production.up.railway.app"

    private var token: String? {
        get { UserDefaults.standard.string(forKey: "jwt_token") }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: "jwt_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "jwt_token")
            }
        }
    }

    private init() {}

    func setToken(_ token: String?) {
        self.token = token
    }

    private func makeRequest(_ path: String, method: String = "GET", body: [String: Any]? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return request
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Réponse invalide du serveur.")
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(APIErrorResponse.self, from: data))?.erreur
            throw APIError.serverError(message ?? "Erreur serveur \(httpResponse.statusCode).")
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func validateNoContent(_ data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Réponse invalide du serveur.")
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(APIErrorResponse.self, from: data))?.erreur
            throw APIError.serverError(message ?? "Erreur serveur \(httpResponse.statusCode).")
        }
    }

    // MARK: - Auth

    func connexion(courriel: String, motDePasse: String) async throws -> (UserDTO, String) {
        let request = try makeRequest(
            "/api/auth/connexion",
            method: "POST",
            body: ["courriel": courriel, "motDePasse": motDePasse]
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        let result = try decode(ConnexionResponse.self, from: data, response: response)
        return (result.utilisateur, result.token)
    }

    func inscription(prenom: String, nom: String, courriel: String,
                     telephone: String, adresse: String, motDePasse: String) async throws -> (UserDTO, String) {
        let request = try makeRequest(
            "/api/auth/inscription",
            method: "POST",
            body: [
                "prenom": prenom,
                "nom": nom,
                "courriel": courriel,
                "telephone": telephone,
                "adresse": adresse,
                "motDePasse": motDePasse
            ]
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        let result = try decode(ConnexionResponse.self, from: data, response: response)
        return (result.utilisateur, result.token)
    }

    // MARK: - Rapports

    func listerRapports() async throws -> [ReportDTO] {
        let request = try makeRequest("/api/rapports")
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode([ReportDTO].self, from: data, response: response)
    }

    func creerRapport(titre: String, details: String, categorie: ReportCategorie,
                      adresse: String, latitude: Double, longitude: Double,
                      imageData: Data?) async throws -> ReportDTO {
        var body: [String: Any] = [
            "titre": titre,
            "details": details,
            "categorie": categorie.rawValue,
            "adresse": adresse,
            "latitude": latitude,
            "longitude": longitude,
            "date": ISO8601DateFormatter().string(from: Date())
        ]

        if let imageData {
            body["imageData"] = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
        }

        let request = try makeRequest("/api/rapports", method: "POST", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(ReportDTO.self, from: data, response: response)
    }

    func changerEtat(rapportId: String, nouvelEtat: ReportEtat,
                     description: String, imageData: Data?) async throws -> ReportDTO {
        var body: [String: Any] = [
            "etat": nouvelEtat.rawValue,
            "description": description
        ]
        if let imageData {
            body["imageData"] = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
        }

        let request = try makeRequest(
            "/api/rapports/\(rapportId)/etat",
            method: "PATCH",
            body: body
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(ReportDTO.self, from: data, response: response)
    }

    // MARK: - Utilisateurs

    func listerUtilisateurs() async throws -> [UserDTO] {
        let request = try makeRequest("/api/utilisateurs")
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode([UserDTO].self, from: data, response: response)
    }

    func modifierUtilisateur(userId: String, prenom: String, nom: String,
                             telephone: String, adresse: String,
                             role: UserRole, numeroAgent: String?) async throws -> UserDTO {
        var body: [String: Any] = [
            "prenom": prenom,
            "nom": nom,
            "telephone": telephone,
            "adresse": adresse,
            "role": role.rawValue
        ]
        body["numeroAgent"] = numeroAgent ?? ""

        let request = try makeRequest("/api/utilisateurs/\(userId)", method: "PUT", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(UserDTO.self, from: data, response: response)
    }

    func modifierProfil(userId: String, prenom: String, nom: String,
                        telephone: String, adresse: String,
                        motDePasse: String?) async throws -> UserDTO {
        var body: [String: Any] = [
            "prenom": prenom,
            "nom": nom,
            "telephone": telephone,
            "adresse": adresse
        ]
        if let motDePasse, !motDePasse.isEmpty {
            body["motDePasse"] = motDePasse
        }

        let request = try makeRequest("/api/utilisateurs/\(userId)", method: "PUT", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(UserDTO.self, from: data, response: response)
    }

    func supprimerUtilisateur(userId: String) async throws {
        let request = try makeRequest("/api/utilisateurs/\(userId)", method: "DELETE")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateNoContent(data, response: response)
    }
}
