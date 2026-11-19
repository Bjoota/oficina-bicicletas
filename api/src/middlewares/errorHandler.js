function rotaNaoEncontrada(req, res) {
  return res.status(404).json({
    erro: `Rota não encontrada: ${req.method} ${req.originalUrl}`,
  });
}

// eslint-disable-next-line no-unused-vars
function tratarErros(erro, req, res, next) {
  console.error('[api] Erro na requisição:', erro.message);

  return res.status(500).json({
    erro: 'Erro interno ao processar a requisição.',
  });
}

module.exports = {
  rotaNaoEncontrada,
  tratarErros,
};
