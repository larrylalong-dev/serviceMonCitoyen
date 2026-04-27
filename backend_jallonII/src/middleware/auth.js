const jwt = require('jsonwebtoken');

function verifierToken(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ erreur: 'Token manquant ou invalide.' });
    }
    const token = authHeader.split(' ')[1];
    try {
        req.utilisateur = jwt.verify(token, process.env.JWT_SECRET);
        next();
    } catch {
        return res.status(401).json({ erreur: 'Token expiré ou invalide.' });
    }
}

function exigerRole(...roles) {
    return (req, res, next) => {
        if (!roles.includes(req.utilisateur.role)) {
            return res.status(403).json({ erreur: 'Accès refusé: rôle insuffisant.' });
        }
        next();
    };
}

module.exports = { verifierToken, exigerRole };
