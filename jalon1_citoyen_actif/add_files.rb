#!/usr/bin/env ruby
require 'xcodeproj'

# Ouvre le projet Xcode
project_path = '/Users/larrylalong/Dossiers_personnel/Dossiers d etude/inf1032/tp1/jalon1_citoyen_actif/jalon1_citoyen_actif.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Le groupe principal du projet (dossier jalon1_citoyen_actif)
main_group = project.main_group['jalon1_citoyen_actif']

# Fichiers à ajouter organisés par groupe
files_to_add = {
  'Models'         => ['Models/User.swift', 'Models/Report.swift'],
  'ViewModels'     => ['ViewModels/AuthViewModel.swift', 'ViewModels/ReportViewModel.swift'],
  'Views/Auth'     => ['Views/Auth/LoginView.swift', 'Views/Auth/RegisterView.swift', 'Views/Auth/ForgotPasswordView.swift'],
  'Views/Main'     => ['Views/Main/MainTabView.swift', 'Views/Main/ReportListView.swift', 'Views/Main/MapView.swift', 'Views/Main/ProfileView.swift', 'Views/Main/AddReportView.swift'],
  'Data'           => ['Data/reports.json'],
}

# La target principale
target = project.targets.first

files_to_add.each do |group_path, files|
  # Crée ou retrouve le groupe (supporte les sous-groupes avec /)
  parts = group_path.split('/')
  group = main_group
  parts.each do |part|
    existing = group[part]
    if existing
      group = existing
    else
      group = group.new_group(part)
    end
  end

  files.each do |relative_path|
    full_path = "/Users/larrylalong/Dossiers_personnel/Dossiers d etude/inf1032/tp1/jalon1_citoyen_actif/jalon1_citoyen_actif/#{relative_path}"
    
    # Vérifie que le fichier existe
    unless File.exist?(full_path)
      puts "FICHIER MANQUANT: #{full_path}"
      next
    end

    # Ajoute le fichier au groupe
    file_ref = group.new_file(full_path)
    
    # Ajoute à la phase de compilation (seulement pour .swift)
    if relative_path.end_with?('.swift')
      target.source_build_phase.add_file_reference(file_ref)
    else
      # Pour le JSON, on l'ajoute dans les ressources
      target.resources_build_phase.add_file_reference(file_ref)
    end

    puts "Ajouté : #{relative_path}"
  end
end

project.save
puts "\nProjet sauvegardé !"
