CREATE TABLE IF NOT EXISTS ordens_servico (
  id SERIAL PRIMARY KEY,
  ordem_servico INTEGER NOT NULL CHECK (ordem_servico > 0),
  valor NUMERIC(10, 2) NOT NULL CHECK (valor >= 0),
  criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ordens_servico_criado_em
  ON ordens_servico (criado_em DESC);
