const { obterPool } = require('../database');

function mapearOrdem(linha) {
  return {
    id: linha.id,
    ordemServico: linha.ordem_servico,
    valor: Number(linha.valor),
    criadoEm: new Date(linha.criado_em).toISOString(),
  };
}

async function listarOrdens() {
  const { rows } = await obterPool().query(
    `SELECT id, ordem_servico, valor, criado_em
       FROM ordens_servico
      ORDER BY id DESC`,
  );

  return rows.map(mapearOrdem);
}

async function criarOrdem({ ordemServico, valor }) {
  const { rows } = await obterPool().query(
    `INSERT INTO ordens_servico (ordem_servico, valor)
     VALUES ($1, $2)
     RETURNING id, ordem_servico, valor, criado_em`,
    [ordemServico, valor],
  );

  return mapearOrdem(rows[0]);
}

module.exports = {
  listarOrdens,
  criarOrdem,
};
