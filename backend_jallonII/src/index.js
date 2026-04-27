require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const reportRoutes = require('./routes/reportRoutes');

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/health', (req, res) => {
    res.json({ statut: 'ok', service: 'CitoyenActif API', version: '1.0.0' });
});

app.use('/api/auth', authRoutes);
app.use('/api/utilisateurs', userRoutes);
app.use('/api/rapports', reportRoutes);

app.use((req, res) => {
    res.status(404).json({ erreur: 'Route introuvable.' });
});

app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ erreur: 'Erreur interne du serveur.' });
});

app.listen(PORT, HOST, () => {
    console.log(`CitoyenActif API démarrée sur http://${HOST}:${PORT}`);
});
