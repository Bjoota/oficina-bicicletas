require('dotenv').config();

const { criarApp } = require('./src/app');
const { inicializarBanco, encerrarBanco } = require('./src/database');

const PORTA = Number(process.env.PORT || 3000);

async function iniciar() {
  await inicializarBanco();

  const app = criarApp();
  const servidor = app.listen(PORTA, () => {
    console.log(`[api] Oficina de Bicicletas ouvindo em http://localhost:${PORTA}`);
  });

  async function encerrar(sinal) {
    console.log(`[api] Encerrando após ${sinal}...`);
    servidor.close(async () => {
      await encerrarBanco();
      process.exit(0);
    });
  }

  process.on('SIGINT', () => encerrar('SIGINT'));
  process.on('SIGTERM', () => encerrar('SIGTERM'));
}

iniciar().catch((erro) => {
  console.error('[api] Falha ao iniciar:', erro.message);
  process.exit(1);
});
