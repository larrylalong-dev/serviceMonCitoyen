const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

const migrations = ['001_init.sql', '002_image_url.sql', '003_report_status_evidence.sql'];

async function runMigrations() {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS migrations_appliquees (
            nom VARCHAR(255) PRIMARY KEY,
            appliquee_le TIMESTAMPTZ DEFAULT NOW()
        )
    `);

    for (const fichier of migrations) {
        const deja = await pool.query(
            'SELECT nom FROM migrations_appliquees WHERE nom = $1', [fichier]
        );
        if (deja.rows.length > 0) {
            console.log(`Migration ${fichier} déjà appliquée, ignorée.`);
            continue;
        }

        const sql = fs.readFileSync(path.join(__dirname, fichier), 'utf8');
        try {
            await pool.query(sql);
            await pool.query(
                'INSERT INTO migrations_appliquees (nom) VALUES ($1)', [fichier]
            );
            console.log(`Migration ${fichier} exécutée avec succès.`);
        } catch (err) {
            console.error(`Erreur lors de la migration ${fichier}:`, err.message);
            process.exit(1);
        }
    }
    await pool.end();
}

runMigrations();
