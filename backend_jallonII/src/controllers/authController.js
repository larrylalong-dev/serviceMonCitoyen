const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function nettoyerTexte(valeur) {
    return typeof valeur === 'string' ? valeur.trim() : '';
}

function validerInscription({ prenom, nom, courriel, telephone, adresse, motDePasse }) {
    const erreurs = [];
    const chiffresTelephone = telephone.replace(/\D/g, '');

    if (!prenom) erreurs.push('Le prénom est obligatoire.');
    if (!nom) erreurs.push('Le nom est obligatoire.');
    if (!courriel) erreurs.push('Le courriel est obligatoire.');
    else if (!EMAIL_REGEX.test(courriel)) erreurs.push('Le courriel est invalide.');
    if (!telephone) erreurs.push('Le téléphone est obligatoire.');
    else if (chiffresTelephone.length < 10) erreurs.push('Le téléphone doit contenir au moins 10 chiffres.');
    if (!adresse) erreurs.push('L’adresse est obligatoire.');
    else if (adresse.length < 5) erreurs.push('L’adresse doit contenir au moins 5 caractères.');
    if (!motDePasse) erreurs.push('Le mot de passe est obligatoire.');
    else if (motDePasse.length < 4) erreurs.push('Le mot de passe doit contenir au moins 4 caractères.');

    return erreurs;
}

function validerConnexion({ courriel, motDePasse }) {
    const erreurs = [];

    if (!courriel) erreurs.push('Le courriel est obligatoire.');
    else if (!EMAIL_REGEX.test(courriel)) erreurs.push('Le courriel est invalide.');
    if (!motDePasse) erreurs.push('Le mot de passe est obligatoire.');

    return erreurs;
}

function genererToken(utilisateur) {
    return jwt.sign(
        { id: utilisateur.id, courriel: utilisateur.courriel, role: utilisateur.role },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
    );
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

async function inscription(req, res) {
    const prenom = nettoyerTexte(req.body.prenom);
    const nom = nettoyerTexte(req.body.nom);
    const courriel = nettoyerTexte(req.body.courriel).toLowerCase();
    const telephone = nettoyerTexte(req.body.telephone);
    const adresse = nettoyerTexte(req.body.adresse);
    const role = nettoyerTexte(req.body.role);
    const numeroAgent = nettoyerTexte(req.body.numeroAgent);
    const motDePasse = typeof req.body.motDePasse === 'string' ? req.body.motDePasse : '';

    const erreurs = validerInscription({ prenom, nom, courriel, telephone, adresse, motDePasse });
    if (erreurs.length > 0) {
        return res.status(400).json({ erreur: erreurs[0], champs: erreurs });
    }

    const roleValide = ['citoyen', 'employe', 'agent'].includes(role) ? role : 'citoyen';

    try {
        const existe = await pool.query('SELECT id FROM users WHERE courriel = $1', [courriel]);
        if (existe.rows.length > 0) {
            return res.status(409).json({ erreur: 'Ce courriel est déjà utilisé.' });
        }

        const hash = await bcrypt.hash(motDePasse, 10);
        const result = await pool.query(
            `INSERT INTO users (prenom, nom, courriel, telephone, adresse, role, numero_agent, mot_de_passe)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
            [prenom, nom, courriel, telephone, adresse, roleValide, numeroAgent || null, hash]
        );

        const utilisateur = formatUser(result.rows[0]);
        const token = genererToken(utilisateur);
        res.status(201).json({ utilisateur, token });
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

async function connexion(req, res) {
    const courriel = nettoyerTexte(req.body.courriel).toLowerCase();
    const motDePasse = typeof req.body.motDePasse === 'string' ? req.body.motDePasse : '';

    const erreurs = validerConnexion({ courriel, motDePasse });
    if (erreurs.length > 0) {
        return res.status(400).json({ erreur: erreurs[0], champs: erreurs });
    }

    try {
        const result = await pool.query('SELECT * FROM users WHERE courriel = $1', [courriel]);
        if (result.rows.length === 0) {
            return res.status(401).json({ erreur: 'Identifiants incorrects.' });
        }

        const row = result.rows[0];
        const valide = await bcrypt.compare(motDePasse, row.mot_de_passe);
        if (!valide) {
            return res.status(401).json({ erreur: 'Identifiants incorrects.' });
        }

        const utilisateur = formatUser(row);
        const token = genererToken(utilisateur);
        res.json({ utilisateur, token });
    } catch (err) {
        console.error(err);
        res.status(500).json({ erreur: 'Erreur serveur.' });
    }
}

module.exports = { inscription, connexion };
