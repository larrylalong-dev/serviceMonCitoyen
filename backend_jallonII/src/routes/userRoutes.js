const express = require('express');
const { verifierToken, exigerRole } = require('../middleware/auth');
const { obtenirProfil, mettreAJourProfil, listerUtilisateurs, supprimerUtilisateur } = require('../controllers/userController');
const router = express.Router();

router.get('/', verifierToken, exigerRole('employe', 'agent'), listerUtilisateurs);
router.get('/:id', verifierToken, obtenirProfil);
router.put('/:id', verifierToken, mettreAJourProfil);
router.delete('/:id', verifierToken, exigerRole('agent'), supprimerUtilisateur);

module.exports = router;
