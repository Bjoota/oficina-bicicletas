const express = require('express');
const cors = require('cors');

const rotasOrdens = require('./routes/ordens.routes');
const { obterPool } = require('./database');
const { rotaNaoEncontrada, tratarErros } = require('./middlewares/errorHandler');

function criarApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get('/health', async (req, res) => {
    try {
      await obterPool().query('SELECT 1');
      return res.json({ status: 'ok', banco: 'conectado' });
    } catch (erro) {
      return res.status(503).json({ status: 'indisponivel', banco: 'sem conexao' });
    }
  });

  app.use('/ordens', rotasOrdens);

  app.use(rotaNaoEncontrada);
  app.use(tratarErros);

  return app;
}

module.exports = {
  criarApp,
};
