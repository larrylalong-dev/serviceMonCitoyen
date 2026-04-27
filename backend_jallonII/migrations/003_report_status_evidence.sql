-- Migration 003: Preuves d'action pour les changements d'etat
ALTER TABLE reports ADD COLUMN IF NOT EXISTS etat_description TEXT;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS etat_image_url VARCHAR(500);
ALTER TABLE reports ADD COLUMN IF NOT EXISTS etat_modifie_par UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS etat_modifie_par_nom VARCHAR(255);
ALTER TABLE reports ADD COLUMN IF NOT EXISTS etat_modifie_le TIMESTAMPTZ;
