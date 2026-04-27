const bcrypt = require('bcryptjs');
const pool = require('../config/database');

const ROLES_VALIDES = ['citoyen', 'employe', 'agent'];

function nettoyerTexte(valeur) {
    return typeof valeur === 'string' ? valeur.trim() : '';
}

function formatUser(row) {
    return {
        id: row.id,
        prenom: row.prenom,
        nom: row.nom,
        courriel: row.courriel,
        telephone: row.telephone,
        adresse: row.adresse,
        role: row.role,
        numeroAgent: row.numero_agent,
    };
}

function validerMiseAJourProfil(reqBody, { prenom, nom, telephone, adresse, roleCible, motDePasse }) {
    const erreurs = [];

    if (reqBody.prenom !== undefined && !prenom) {
        erreurs.push('Le prénom est obligatoire.');
    }
    if (reqBody.nom !== undefined && !nom) {
        erreurs.push('Le nom est obligatoire.');
    }
    if (telephone !== undefined) {
        const chiffresTelephone = telephone.replace(/\D/g, '');
        if (!telephone) erreurs.push('Le téléphone est obligatoire.');
        else if (chiffresTelephone.length < 10) erreurs.push('Le téléphone doit contenir au moins 10 chiffres.');
    }
    if (adresse !== undefined) {
        if (roleCible === 'citoyen' && !adresse) erreurs.push('L’adresse est obligatoire.');
        else if (adresse && adresse.length < 5) erreurs.push('L’adresse doit contenir au moins 5 caractères.');
    }
    if (motDePasse && motDePasse.length < 4) {
        erreurs.push('Le mot de passe doit contenir au moins 4 caractères.');
    }

    return erreurs;
}

async function obtenirProfil(req, res) {
    const { id } = req.params;

    if (req.utilisateur.id !== id && !['employe', 'agent'].includes(req.utilisateur.role)) {
        return res.status(403).json({ erreur: 'Accès refusé.' });
    }

    try {
        const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ erreur: 'Utilisateur introuvable.' });
        }
        res.json(formatUser(result.rows[0]));
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

async function mettreAJourProfil(req, res) {
    const { id } = req.params;
    const estAgent = req.utilisateur.role === 'agent';

    if (req.utilisateur.id !== id && !estAgent) {
        return res.status(403).json({ erreur: 'Vous ne pouvez modifier que votre propre profil.' });
    }

    const prenom = nettoyerTexte(req.body.prenom);
    const nom = nettoyerTexte(req.body.nom);
    const telephone = req.body.telephone !== undefined ? nettoyerTexte(req.body.telephone) : undefined;
    const adresse = req.body.adresse !== undefined ? nettoyerTexte(req.body.adresse) : undefined;
    const role = req.body.role !== undefined ? nettoyerTexte(req.body.role) : undefined;
    const numeroAgent = req.body.numeroAgent !== undefined ? nettoyerTexte(req.body.numeroAgent) : undefined;
    const motDePasse = typeof req.body.motDePasse === 'string' ? req.body.motDePasse : '';
    const roleCible = role || req.utilisateur.role;

    const erreurs = validerMiseAJourProfil(req.body, {
        prenom, nom, telephone, adresse, roleCible, motDePasse
    });
    if (erreurs.length > 0) {
        return res.status(400).json({ erreur: erreurs[0], champs: erreurs });
    }

    try {
        const champs = [];
        const valeurs = [];
        let idx = 1;

        if (prenom) { champs.push(`prenom = $${idx++}`); valeurs.push(prenom); }
        if (nom) { champs.push(`nom = $${idx++}`); valeurs.push(nom); }
        if (telephone !== undefined) { champs.push(`telephone = $${idx++}`); valeurs.push(telephone); }
        if (adresse !== undefined) { champs.push(`adresse = $${idx++}`); valeurs.push(adresse); }
        if (role !== undefined) {
            if (!estAgent) {
                return res.status(403).json({ erreur: 'Seuls les agents peuvent modifier les rôles.' });
            }
            if (!ROLES_VALIDES.includes(role)) {
                return res.status(400).json({ erreur: `Rôle invalide. Valeurs acceptées: ${ROLES_VALIDES.join(', ')}` });
            }
            champs.push(`role = $${idx++}`);
            valeurs.push(role);
        }
        if (numeroAgent !== undefined && estAgent) {
            champs.push(`numero_agent = $${idx++}`);
            valeurs.push(numeroAgent || null);
        }
        if (motDePasse) {
            const hash = await bcrypt.hash(motDePasse, 10);
            champs.push(`mot_de_passe = $${idx++}`);
            valeurs.push(hash);
        }

        if (champs.length === 0) {
            return res.status(400).json({ erreur: 'Aucun champ à mettre à jour.' });
        }

        valeurs.push(id);
        const result = await pool.query(
            `UPDATE users SET ${champs.join(', ')} WHERE id = $${idx} RETURNING *`,
            valeurs
        );

        res.json(formatUser(result.rows[0]));
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

async function listerUtilisateurs(req, res) {
    try {
        const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
        res.json(result.rows.map(formatUser));
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

async function supprimerUtilisateur(req, res) {
    const { id } = req.params;

    if (req.utilisateur.id === id) {
        return res.status(400).json({ erreur: 'Un agent ne peut pas supprimer son propre compte.' });
    }

    try {
        const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING id', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ erreur: 'Utilisateur introuvable.' });
        }
        res.status(204).send();
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

module.exports = { obtenirProfil, mettreAJourProfil, listerUtilisateurs, supprimerUtilisateur };
