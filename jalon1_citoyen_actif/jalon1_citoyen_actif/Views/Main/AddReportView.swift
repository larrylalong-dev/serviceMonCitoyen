// AddReportView.swift
// Formulaire pour soumettre un nouveau rapport de bris (s'ouvre en sheet)

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct AddReportView: View {

    @Environment(AuthViewModel.self) var authVM
    @Environment(ReportViewModel.self) var reportVM

    // Permet de fermer le sheet depuis cette vue
    @Binding var estPresente: Bool

    // Les champs du formulaire
    @State private var titre: String = ""
    @State private var description: String = ""
    @State private var adresse: String = ""
    @State private var categorieChoisie: ReportCategorie = .voirie
    @State private var messageErreur: String = ""
    
    // Coordonnées géographiques
    @State private var latitude: Double = 46.3432  // Trois-Rivières par défaut
    @State private var longitude: Double = -72.5424
    @State private var coordonneesValides: Bool = false
    
    // Géolocalisation
    @StateObject private var locationManager = LocationManager()
    @State private var utilisateurLocaliationAutorisee: Bool = false
    
    // Autocomplétion d'adresses
    @State private var suggestionsAdresses: [String] = []
    @State private var afficherSuggestions: Bool = false
    
    // Éléments pour la prise de photo
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    
    
    var body: some View {
        NavigationStack {
            Form {

                Section(header: Text("Informations du bris")) {
                    TextField("Titre du bris", text: $titre)

                    // Zone de texte pour la description
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description du problème...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                    }

                    // Champ adresse avec géocodage automatique et autocomplétion
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Adresse du bris", text: $adresse)
                            .onChange(of: adresse) { oldValue, newValue in
                                // Déclenche le géocodage quand l'adresse change
                                geocodeAdresse(newValue)
                                // Charge les suggestions d'adresses
                                if newValue.count > 2 {
                                    chargerSuggestionsAdresses(newValue)
                                } else {
                                    suggestionsAdresses = []
                                    afficherSuggestions = false
                                }
                            }
                        
                        // Liste des suggestions d'adresses
                        if afficherSuggestions && !suggestionsAdresses.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(suggestionsAdresses, id: \.self) { suggestion in
                                    Button(action: {
                                        adresse = suggestion
                                        afficherSuggestions = false
                                        geocodeAdresse(suggestion)
                                    }) {
                                        HStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                            Text(suggestion)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                    }
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                                }
                            }
                            .padding(8)
                            .background(Color.white)
                            .border(Color(.systemGray3), width: 1)
                            .cornerRadius(8)
                        }
                        
                        // Affiche les coordonnées détectées
                        if coordonneesValides {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Coordonnées détectées")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text("Lat: \(String(format: "%.4f", latitude)), Lng: \(String(format: "%.4f", longitude))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }

                Section(header: Text("Catégorie")) {
                    // Picker pour choisir parmi les catégories prédéfinies
                    Picker("Catégorie", selection: $categorieChoisie) {
                        ForEach(ReportCategorie.allCases, id: \.self) { cat in
                            Text(cat.label).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Photo")) {
                    // Bouton pour ouvrir le sélecteur d'image
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Prendre ou sélectionner une photo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
                    // Affiche l'image sélectionnée
                    if let image = selectedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo sélectionnée ✓")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                            
                            // Bouton pour enlever l'image
                            Button(role: .destructive, action: {
                                selectedImage = nil
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Enlever cette photo")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Aucune photo")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }

                // Message d'erreur si le formulaire est incomplet
                if !messageErreur.isEmpty {
                    Section {
                        Text(messageErreur)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Nouveau rapport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Bouton Annuler à gauche
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        estPresente = false
                    }
                }
                // Bouton Soumettre à droite
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Soumettre") {
                        soumettre()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Demander la permission de géolocalisation et pré-remplir l'adresse
                demanderGeolocalisation()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
    }

    // Valide et soumet le formulaire
    func soumettre() {
        guard !titre.isEmpty, !adresse.isEmpty else {
            messageErreur = "Veuillez remplir le titre et l'adresse."
            return
        }
        let user = authVM.utilisateurConnecte
        
        // Convertir l'image en Data si elle existe
        var imageData: Data? = nil
        if let image = selectedImage {
            imageData = image.jpegData(compressionQuality: 0.8)
        }
        
        // Passer les coordonnées détectées
        reportVM.ajouterRapportAvecImageEtCoordonnees(
            titre: titre,
            details: description,
            categorie: categorieChoisie,
            adresse: adresse,
            latitude: latitude,
            longitude: longitude,
            citoyenId: user?.id ?? "inconnu",
            citoyenNom: "\(user?.prenom ?? "") \(user?.nom ?? "")",
            imageData: imageData
        )
        // Ferme le sheet après soumission
        estPresente = false
    }
    
    // Fonction de géocodage pour convertir adresse → coordonnées
    func geocodeAdresse(_ adresse: String) {
        guard !adresse.isEmpty else {
            coordonneesValides = false
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(adresse) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first,
                   let location = placemark.location {
                    // Coordonnées trouvées
                    self.latitude = location.coordinate.latitude
                    self.longitude = location.coordinate.longitude
                    self.coordonneesValides = true
                } else {
                    // Si l'adresse commence par un nombre connu (Trois-Rivières), utiliser les coords par défaut
                    self.latitude = 46.3432
                    self.longitude = -72.5424
                    self.coordonneesValides = false
                }
            }
        }
    }
    
    // Demande la permission de géolocalisation et pré-remplit l'adresse
    func demanderGeolocalisation() {
        // Demander la permission et obtenir la localisation
        locationManager.requestLocation()
        
        // Attendre un petit délai pour que la localisation soit disponible
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let location = locationManager.location {
                latitude = location.latitude
                longitude = location.longitude
                
                // Convertir les coordonnées en adresse (géocodage inverse)
                let geocoder = CLGeocoder()
                let loc = CLLocation(latitude: latitude, longitude: longitude)
                
                geocoder.reverseGeocodeLocation(loc) { placemarks, error in
                    DispatchQueue.main.async {
                        if let placemark = placemarks?.first {
                            // Construire l'adresse à partir du placemark
                            var adresseComposee = ""
                            
                            if let street = placemark.thoroughfare {
                                adresseComposee += street
                            }
                            if let city = placemark.locality {
                                if !adresseComposee.isEmpty {
                                    adresseComposee += ", "
                                }
                                adresseComposee += city
                            }
                            if let postalCode = placemark.postalCode {
                                if !adresseComposee.isEmpty {
                                    adresseComposee += ", "
                                }
                                adresseComposee += postalCode
                            }
                            
                            if !adresseComposee.isEmpty {
                                self.adresse = adresseComposee
                                self.coordonneesValides = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Charge les suggestions d'adresses basées sur la saisie
    func chargerSuggestionsAdresses(_ recherche: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = recherche
        searchRequest.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                if let response = response {
                    // Extraire les adresses des résultats
                    self.suggestionsAdresses = response.mapItems.compactMap { item in
                        var adresse = ""
                        if let street = item.placemark.thoroughfare {
                            adresse += street
                        }
                        if let city = item.placemark.locality {
                            if !adresse.isEmpty {
                                adresse += ", "
                            }
                            adresse += city
                        }
                        return adresse.isEmpty ? nil : adresse
                    }
                    self.afficherSuggestions = !self.suggestionsAdresses.isEmpty
                } else {
                    self.suggestionsAdresses = []
                    self.afficherSuggestions = false
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Report.self, configurations: config)
    let authVM = AuthViewModel(modelContext: container.mainContext)
    let reportVM = ReportViewModel(modelContext: container.mainContext)
    
    AddReportView(estPresente: .constant(true))
        .environment(authVM)
        .environment(reportVM)
        .modelContainer(container)
}
