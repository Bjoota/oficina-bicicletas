const { Router } = require('express');
const ordensController = require('../controllers/ordens.controller');

const rotas = Router();

rotas.get('/', ordensController.listar);
rotas.post('/', ordensController.criar);

module.exports = rotas;
