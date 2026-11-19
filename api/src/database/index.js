const fs = require('node:fs');
const path = require('node:path');
const { Pool } = require('pg');

let pool;

function obterPool() {
  if (pool) {
    return pool;
  }

  const connectionString = process.env.DATABASE_URL;

  if (!connectionString) {
    throw new Error('A variável de ambiente DATABASE_URL não foi definida.');
  }

  pool = new Pool({
    connectionString,
    max: Number(process.env.DATABASE_POOL_MAX || 10),
    ssl:
      process.env.DATABASE_SSL === 'true'
        ? { rejectUnauthorized: false }
        : undefined,
  });

  pool.on('error', (erro) => {
    console.error('[postgres] Erro inesperado no pool:', erro.message);
  });

  return pool;
}

async function inicializarBanco() {
  const script = fs.readFileSync(
    path.join(__dirname, 'schema.sql'),
    'utf8',
  );

  await obterPool().query(script);
  console.log('[postgres] Schema verificado com sucesso.');
}

async function encerrarBanco() {
  if (pool) {
    await pool.end();
    pool = undefined;
  }
}

module.exports = {
  obterPool,
  inicializarBanco,
  encerrarBanco,
};
