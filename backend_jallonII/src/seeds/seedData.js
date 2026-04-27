require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('../config/database');

async function seed() {
    const hash = await bcrypt.hash('1234', 10);

    const usersData = [
        { prenom: 'Marie',  nom: 'Tremblay', courriel: 'marie@test.com',  telephone: '819-000-0001', adresse: '123 Rue des Forges',       role: 'citoyen', numero_agent: null },
        { prenom: 'Jean',   nom: 'Côté',     courriel: 'jean@test.com',   telephone: '819-000-0002', adresse: '450 Boul. des Récollets',  role: 'citoyen', numero_agent: null },
        { prenom: 'Pierre', nom: 'Roy',      courriel: 'pierre@ville.com',telephone: '819-000-0010', adresse: '',                         role: 'employe', numero_agent: 'EMP-001' },
        { prenom: 'Sophie', nom: 'Lavoie',   courriel: 'sophie@ville.com',telephone: '819-000-0020', adresse: '',                         role: 'agent',   numero_agent: 'AGT-001' },
    ];

    const userIds = {};
    for (const u of usersData) {
        const r = await pool.query(
            `INSERT INTO users (prenom, nom, courriel, telephone, adresse, role, numero_agent, mot_de_passe)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
             ON CONFLICT (courriel) DO UPDATE SET prenom = EXCLUDED.prenom
             RETURNING id`,
            [u.prenom, u.nom, u.courriel, u.telephone, u.adresse, u.role, u.numero_agent, hash]
        );
        userIds[u.courriel] = r.rows[0].id;
        console.log(`Utilisateur inséré : ${u.prenom} ${u.nom} (${u.courriel})`);
    }

    const now = new Date().toISOString();
    const reportsData = [
        // Marie — 2 rapports
        {
            titre: 'Lampadaire éteint',
            details: 'Le lampadaire au coin de la rue est éteint depuis 3 jours, créant un risque pour la sécurité des piétons la nuit.',
            categorie: 'eclairage', etat: 'enAttente',
            adresse: '123 Rue des Forges, Trois-Rivières',
            latitude: 46.3432, longitude: -72.5424,
            citoyen: 'marie@test.com',
        },
        {
            titre: 'Nid-de-poule dangereux',
            details: 'Un grand nid-de-poule au milieu de la chaussée a abîmé mon véhicule. Il faut le réparer rapidement.',
            categorie: 'voirie', etat: 'enCours',
            adresse: '450 Boul. des Récollets, Trois-Rivières',
            latitude: 46.3510, longitude: -72.5510,
            citoyen: 'marie@test.com',
        },
        // Jean — 2 rapports
        {
            titre: 'Banc de parc brisé',
            details: 'Le banc près de l\'entrée principale du parc est complètement brisé. Des éclats de bois risquent de blesser les enfants.',
            categorie: 'mobilier', etat: 'enAttente',
            adresse: '200 Parc Laviolette, Trois-Rivières',
            latitude: 46.3480, longitude: -72.5480,
            citoyen: 'jean@test.com',
        },
        {
            titre: 'Gazon non entretenu',
            details: 'Le gazon du terre-plein central n\'a pas été taillé depuis plus d\'un mois. La végétation bloque la visibilité.',
            categorie: 'espacesVerts', etat: 'repare',
            adresse: '89 Avenue Royale, Trois-Rivières',
            latitude: 46.3450, longitude: -72.5450,
            citoyen: 'jean@test.com',
        },
        // Pierre — 2 rapports
        {
            titre: 'Panneau de stop renversé',
            details: 'Le panneau d\'arrêt à l\'intersection est couché par terre suite à une collision. Danger immédiat pour la circulation.',
            categorie: 'signalisation', etat: 'enCours',
            adresse: '5 Rue Saint-Pierre, Trois-Rivières',
            latitude: 46.3400, longitude: -72.5400,
            citoyen: 'pierre@ville.com',
        },
        {
            titre: 'Feu de circulation défectueux',
            details: 'Le feu de circulation clignote en rouge en permanence au lieu de fonctionner normalement. Cause de bouchons importants.',
            categorie: 'signalisation', etat: 'enAttente',
            adresse: '12 Rue Laviolette, Trois-Rivières',
            latitude: 46.3415, longitude: -72.5415,
            citoyen: 'pierre@ville.com',
        },
        // Sophie — 2 rapports
        {
            titre: 'Poubelle publique déversée',
            details: 'La poubelle publique au coin de rue est renversée et les déchets traînent sur le trottoir depuis ce matin.',
            categorie: 'mobilier', etat: 'ignore',
            adresse: '78 Rue des Ursulines, Trois-Rivières',
            latitude: 46.3490, longitude: -72.5490,
            citoyen: 'sophie@ville.com',
        },
        {
            titre: 'Éclairage de parc hors service',
            details: 'Plusieurs lampadaires du parc municipal sont hors service, rendant les promenades nocturnes dangereuses.',
            categorie: 'eclairage', etat: 'enCours',
            adresse: '340 Boul. Saint-Jean, Trois-Rivières',
            latitude: 46.3460, longitude: -72.5460,
            citoyen: 'sophie@ville.com',
        },
    ];

    for (const r of reportsData) {
        const citoyenId = userIds[r.citoyen];
        const userRow = await pool.query('SELECT prenom, nom FROM users WHERE id = $1', [citoyenId]);
        const citoyenNom = `${userRow.rows[0].prenom} ${userRow.rows[0].nom}`;

        await pool.query(
            `INSERT INTO reports (titre, details, categorie, etat, date, adresse, latitude, longitude, citoyen_id, citoyen_nom)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
            [r.titre, r.details, r.categorie, r.etat, now, r.adresse, r.latitude, r.longitude, citoyenId, citoyenNom]
        );
        console.log(`Rapport inséré : ${r.titre}`);
    }

    console.log('\nSeed terminé — 4 utilisateurs, 8 rapports.');
    await pool.end();
}

seed().catch(err => {
    console.error('Erreur seed:', err.message);
    process.exit(1);
});
