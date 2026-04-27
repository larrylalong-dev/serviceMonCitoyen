-- Migration 002: Ajout de la colonne image_url pour le stockage sur disque
ALTER TABLE reports ADD COLUMN IF NOT EXISTS image_url VARCHAR(500);
