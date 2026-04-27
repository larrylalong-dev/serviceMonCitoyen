const express = require('express');
const { verifierToken } = require('../middleware/auth');
const {
    listerRapports,
    obtenirRapport,
    creerRapport,
    changerEtat,
    mettreAJourRapport,
    supprimerRapport,
    rapportsDuCitoyen,
} = require('../controllers/reportController');
const router = express.Router();

router.get('/', verifierToken, listerRapports);
router.get('/citoyen/:citoyenId', verifierToken, rapportsDuCitoyen);
router.get('/:id', verifierToken, obtenirRapport);
router.post('/', verifierToken, creerRapport);
router.patch('/:id/etat', verifierToken, changerEtat);
router.put('/:id', verifierToken, mettreAJourRapport);
router.delete('/:id', verifierToken, supprimerRapport);

module.exports = router;
