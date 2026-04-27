const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const pool = require('../config/database');

const CATEGORIES_VALIDES = ['eclairage', 'voirie', 'mobilier', 'espacesVerts', 'signalisation'];
const ETATS_VALIDES = ['enAttente', 'enCours', 'repare', 'ignore'];
const UPLOADS_DIR = path.join(__dirname, '../../uploads');
const REPORT_COLUMNS = `id, titre, details, categorie, etat, date, adresse, latitude, longitude,
                    citoyen_id, citoyen_nom, image_url, etat_description, etat_image_url,
                    etat_modifie_par, etat_modifie_par_nom, etat_modifie_le, created_at, updated_at`;

function nettoyerTexte(valeur) {
    return typeof valeur === 'string' ? valeur.trim() : '';
}

function sauvegarderImage(imageData) {
    if (!imageData) return null;
    if (!fs.existsSync(UPLOADS_DIR)) fs.mkdirSync(UPLOADS_DIR, { recursive: true });

    const base64 = imageData.replace(/^data:image\/\w+;base64,/, '');
    const filename = `${uuidv4()}.jpg`;
    fs.writeFileSync(path.join(UPLOADS_DIR, filename), Buffer.from(base64, 'base64'));
    return `/uploads/${filename}`;
}

function supprimerImageFichier(imageUrl) {
    if (!imageUrl) return;
    const filepath = path.join(UPLOADS_DIR, path.basename(imageUrl));
    if (fs.existsSync(filepath)) fs.unlinkSync(filepath);
}

function formatReport(row) {
    return {
        id: row.id,
        titre: row.titre,
        details: row.details,
        categorie: row.categorie,
        etat: row.etat,
        date: row.date,
        adresse: row.adresse,
        latitude: row.latitude,
        longitude: row.longitude,
        citoyenId: row.citoyen_id,
        citoyenNom: row.citoyen_nom,
        imageUrl: row.image_url || null,
        etatDescription: row.etat_description || null,
        etatImageUrl: row.etat_image_url || null,
        etatModifiePar: row.etat_modifie_par || null,
        etatModifieParNom: row.etat_modifie_par_nom || null,
        etatModifieLe: row.etat_modifie_le || null,
    };
}

async function listerRapports(req, res) {
    const { etat, categorie, citoyenId } = req.query;
    const conditions = [];
    const valeurs = [];
    let idx = 1;

    if (etat && ETATS_VALIDES.includes(etat)) {
        conditions.push(`etat = $${idx++}`);
        valeurs.push(etat);
    }
    if (categorie && CATEGORIES_VALIDES.includes(categorie)) {
        conditions.push(`categorie = $${idx++}`);
        valeurs.push(categorie);
    }
    if (citoyenId) {
        conditions.push(`citoyen_id = $${idx++}`);
        valeurs.push(citoyenId);
    }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    try {
        const result = await pool.query(
            `SELECT ${REPORT_COLUMNS}
             FROM reports ${where} ORDER BY created_at DESC`,
            valeurs
        );
        res.json(result.rows.map(formatReport));
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

async function obtenirRapport(req, res) {
    try {
        const result = await pool.query(
            `SELECT ${REPORT_COLUMNS}
             FROM reports WHERE id = $1`,
            [req.params.id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ erreur: 'Rapport introuvable.' });
        }
        res.json(formatReport(result.rows[0]));
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

async function creerRapport(req, res) {
    const titre = nettoyerTexte(req.body.titre);
    const details = nettoyerTexte(req.body.details);
    const categorie = nettoyerTexte(req.body.categorie);
    const adresse = nettoyerTexte(req.body.adresse);
    const { latitude, longitude, date, imageData } = req.body;

    if (!titre || !categorie || !CATEGORIES_VALIDES.includes(categorie)) {
        return res.status(400).json({ erreur: 'Titre et catégorie valide requis.' });
    }
    if (!adresse) {
        return res.status(400).json({ erreur: 'Adresse requise.' });
    }

    const citoyenId = req.utilisateur.id;
    const dateRapport = date || new Date().toISOString();

    try {
        const userResult = await pool.query('SELECT prenom, nom FROM users WHERE id = $1', [citoyenId]);
        const nomComplet = userResult.rows.length > 0
            ? `${userResult.rows[0].prenom} ${userResult.rows[0].nom}`
            : '';

        const imageUrl = sauvegarderImage(imageData);

        const result = await pool.query(
            `INSERT INTO reports (titre, details, categorie, etat, date, adresse, latitude, longitude, citoyen_id, citoyen_nom, image_url)
             VALUES ($1,$2,$3,'enAttente',$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
            [titre, details || '', categorie, dateRapport, adresse, latitude || null, longitude || null, citoyenId, nomComplet, imageUrl]
        );

        res.status(201).json(formatReport(result.rows[0]));
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

async function changerEtat(req, res) {
    const etat = nettoyerTexte(req.body.etat);
    const description = nettoyerTexte(req.body.description);
    const { imageData } = req.body;

    if (!etat || !ETATS_VALIDES.includes(etat)) {
        return res.status(400).json({ erreur: `État invalide. Valeurs acceptées: ${ETATS_VALIDES.join(', ')}` });
    }

    if (req.utilisateur.role !== 'agent') {
        return res.status(403).json({ erreur: 'Seuls les agents municipaux peuvent modifier l’état d’un bris.' });
    }

    if (!description || description.length < 5) {
        return res.status(400).json({ erreur: 'Une description d’au moins 5 caractères est requise pour justifier le changement d’état.' });
    }

    if (description.length > 1000) {
        return res.status(400).json({ erreur: 'La description du changement d’état doit contenir au maximum 1000 caractères.' });
    }

    try {
        const existant = await pool.query('SELECT etat_image_url FROM reports WHERE id = $1', [req.params.id]);
        if (existant.rows.length === 0) {
            return res.status(404).json({ erreur: 'Rapport introuvable.' });
        }

        const agent = await pool.query('SELECT prenom, nom FROM users WHERE id = $1', [req.utilisateur.id]);
        const agentNom = agent.rows.length > 0
            ? `${agent.rows[0].prenom} ${agent.rows[0].nom}`
            : req.utilisateur.courriel;

        supprimerImageFichier(existant.rows[0].etat_image_url);
        const etatImageUrl = sauvegarderImage(imageData);

        const result = await pool.query(
            `UPDATE reports
             SET etat = $1,
                 etat_description = $2,
                 etat_image_url = $3,
                 etat_modifie_par = $4,
                 etat_modifie_par_nom = $5,
                 etat_modifie_le = NOW()
             WHERE id = $6
             RETURNING *`,
            [etat, description, etatImageUrl, req.utilisateur.id, agentNom, req.params.id]
        );
        res.json(formatReport(result.rows[0]));
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

async function mettreAJourRapport(req, res) {
    const { id } = req.params;

    try {
        const existant = await pool.query('SELECT * FROM reports WHERE id = $1', [id]);
        if (existant.rows.length === 0) {
            return res.status(404).json({ erreur: 'Rapport introuvable.' });
        }

        const rapport = existant.rows[0];
        const estProprietaire = rapport.citoyen_id === req.utilisateur.id;
        const estStaff = ['employe', 'agent'].includes(req.utilisateur.role);

        if (!estProprietaire && !estStaff) {
            return res.status(403).json({ erreur: 'Accès refusé.' });
        }

        const { titre, details, adresse, latitude, longitude, imageData, etat } = req.body;
        const champs = [];
        const valeurs = [];
        let idx = 1;

        if (etat !== undefined) {
            return res.status(400).json({ erreur: 'Utilisez la route de changement d’état avec une description d’action.' });
        }

        if (titre) { champs.push(`titre = $${idx++}`); valeurs.push(titre); }
        if (details !== undefined) { champs.push(`details = $${idx++}`); valeurs.push(details); }
        if (adresse !== undefined) { champs.push(`adresse = $${idx++}`); valeurs.push(adresse); }
        if (latitude !== undefined) { champs.push(`latitude = $${idx++}`); valeurs.push(latitude); }
        if (longitude !== undefined) { champs.push(`longitude = $${idx++}`); valeurs.push(longitude); }
        if (imageData !== undefined) {
            supprimerImageFichier(rapport.image_url);
            const imageUrl = sauvegarderImage(imageData);
            champs.push(`image_url = $${idx++}`);
            valeurs.push(imageUrl);
        }
        if (champs.length === 0) {
            return res.status(400).json({ erreur: 'Aucun champ à mettre à jour.' });
        }

        valeurs.push(id);
        const result = await pool.query(
            `UPDATE reports SET ${champs.join(', ')} WHERE id = $${idx} RETURNING *`,
            valeurs
        );
        res.json(formatReport(result.rows[0]));
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

async function supprimerRapport(req, res) {
    const { id } = req.params;

    try {
        const existant = await pool.query('SELECT citoyen_id, image_url FROM reports WHERE id = $1', [id]);
        if (existant.rows.length === 0) {
            return res.status(404).json({ erreur: 'Rapport introuvable.' });
        }

        const estProprietaire = existant.rows[0].citoyen_id === req.utilisateur.id;
        const estAgent = req.utilisateur.role === 'agent';

        if (!estProprietaire && !estAgent) {
            return res.status(403).json({ erreur: 'Accès refusé.' });
        }

        supprimerImageFichier(existant.rows[0].image_url);
        await pool.query('DELETE FROM reports WHERE id = $1', [id]);
        res.status(204).send();
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

async function rapportsDuCitoyen(req, res) {
    const { citoyenId } = req.params;

    if (req.utilisateur.id !== citoyenId && !['employe', 'agent'].includes(req.utilisateur.role)) {
        return res.status(403).json({ erreur: 'Accès refusé.' });
    }

    try {
        const result = await pool.query(
            `SELECT ${REPORT_COLUMNS}
             FROM reports WHERE citoyen_id = $1 ORDER BY created_at DESC`,
            [citoyenId]
        );
        res.json(result.rows.map(formatReport));
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

module.exports = {
    listerRapports,
    obtenirRapport,
    creerRapport,
    changerEtat,
    mettreAJourRapport,
    supprimerRapport,
    rapportsDuCitoyen,
};
