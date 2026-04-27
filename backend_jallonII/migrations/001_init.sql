-- Migration 001: Initialisation des tables CitoyenActif

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prenom VARCHAR(100) NOT NULL,
    nom VARCHAR(100) NOT NULL,
    courriel VARCHAR(255) UNIQUE NOT NULL,
    telephone VARCHAR(20),
    adresse TEXT,
    role VARCHAR(20) NOT NULL DEFAULT 'citoyen'
        CHECK (role IN ('citoyen', 'employe', 'agent')),
    numero_agent VARCHAR(50),
    mot_de_passe VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des rapports de dommages
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titre VARCHAR(255) NOT NULL,
    details TEXT,
    categorie VARCHAR(50) NOT NULL
        CHECK (categorie IN ('eclairage', 'voirie', 'mobilier', 'espacesVerts', 'signalisation')),
    etat VARCHAR(50) NOT NULL DEFAULT 'enAttente'
        CHECK (etat IN ('enAttente', 'enCours', 'repare', 'ignore')),
    date VARCHAR(50) NOT NULL,
    adresse TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    citoyen_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    citoyen_nom VARCHAR(255),
    image_data TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_reports_citoyen_id ON reports(citoyen_id);
CREATE INDEX IF NOT EXISTS idx_reports_etat ON reports(etat);
CREATE INDEX IF NOT EXISTS idx_reports_categorie ON reports(categorie);
CREATE INDEX IF NOT EXISTS idx_users_courriel ON users(courriel);

-- Trigger pour updated_at automatique
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS users_updated_at ON users;
CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS reports_updated_at ON reports;
CREATE TRIGGER reports_updated_at
    BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
