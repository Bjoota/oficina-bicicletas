const ordensService = require('../services/ordens.service');

function validarOrdem(corpo) {
  const erros = [];
  const ordemServico = Number(corpo?.ordemServico);
  const valor = Number(corpo?.valor);

  if (!Number.isInteger(ordemServico) || ordemServico <= 0) {
    erros.push('"ordemServico" deve ser um número inteiro positivo.');
  }

  if (!Number.isFinite(valor) || valor < 0) {
    erros.push('"valor" deve ser um número maior ou igual a zero.');
  }

  return { erros, dados: { ordemServico, valor } };
}

async function listar(req, res, next) {
  try {
    const ordens = await ordensService.listarOrdens();
    return res.json(ordens);
  } catch (erro) {
    return next(erro);
  }
}

async function criar(req, res, next) {
  try {
    const { erros, dados } = validarOrdem(req.body);

    if (erros.length > 0) {
      return res.status(400).json({
        erro: 'Dados inválidos.',
        detalhes: erros,
      });
    }

    const ordem = await ordensService.criarOrdem(dados);
    return res.status(201).json(ordem);
  } catch (erro) {
    return next(erro);
  }
}

module.exports = {
  listar,
  criar,
};
