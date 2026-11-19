# Oficina de Bicicletas

Aplicativo Flutter (Dart) para registrar ordens de serviço de uma oficina de
bicicletas com persistência local em SQLite, API própria em Node.js/Express e
banco PostgreSQL remoto. O app funciona **offline-first**: o cadastro nunca é
perdido quando a API está indisponível e pode ser sincronizado manualmente
depois.

---

## 1. Diagnóstico inicial (auditoria)

O repositório, antes desta etapa, continha apenas o esqueleto do app:

| Item encontrado | Situação |
| --- | --- |
| `lib/main.dart` | Lista em memória (`List<dynamic>`), sem persistência |
| `lib/screens/formulario.dart` | Formulário com OS e valor, devolvia o objeto para a tela anterior |
| `lib/models/transferencia.dart` | Modelo `ServicoBicicleta` (valor + ordem de serviço) |
| `lib/components/editor.dart` | Campo de texto reutilizável |
| `pubspec.yaml` | Apenas `flutter`, `flutter_test` e `flutter_lints` |
| API / banco / repository / services / database | **Não existiam** |

Requisitos que estavam **pendentes**: SQLite, API Node.js, PostgreSQL, camada
`services`, camada `repository`, estratégia offline-first, marcação de
pendentes, botão de sincronização manual e documentação.

A identidade visual (tema "Oficina de Bicicletas", ícones de bicicleta, telas
de lista e cadastro) foi preservada e evoluída.

---

## 2. Estrutura do projeto

```text
lib/
├── components/
│   └── editor.dart                    # campo de formulário reutilizável
├── models/
│   ├── ordem_servico.dart             # modelo local + JSON da API
│   └── transferencia.dart             # modelo legado (fluxo em memória)
├── screens/
│   └── formulario.dart                # cadastro de OS
├── services/
│   └── api_service.dart               # HTTP (GET/POST /ordens)
├── repository/
│   └── ordem_servico_repository.dart  # regra offline-first
├── database/
│   └── sqlite_database.dart           # abertura, CRUD e pendências no SQLite
└── main.dart                          # lista, status e sincronização manual

api/
├── index.js                           # bootstrap (dotenv + Express)
├── package.json
├── .env.example                       # modelo de variáveis de ambiente
└── src/
    ├── app.js                         # middlewares e rotas
    ├── controllers/ordens.controller.js
    ├── routes/ordens.routes.js
    ├── services/ordens.service.js
    ├── middlewares/errorHandler.js
    └── database/
        ├── index.js                   # pool pg (DATABASE_URL)
        └── schema.sql                 # tabela ordens_servico
```

---

## 3. API (Node.js + Express + PostgreSQL)

### Variáveis de ambiente

Crie `api/.env` a partir de `api/.env.example`:

```bash
DATABASE_URL=postgresql://USUARIO:SENHA@HOST:5432/BANCO?sslmode=require
DATABASE_SSL=false
PORT=3000
```

- `DATABASE_URL` é obrigatória e não deve ser versionada.
- `DATABASE_SSL=true` apenas se o provedor exigir SSL sem certificado
  validável localmente.
- Nenhuma credencial está escrita no código ou no repositório.

### Instalação e execução

```bash
cd api
npm install
npm start        # produção
npm run dev      # desenvolvimento (watch)
```

O schema é criado/verificado automaticamente na inicialização
(`api/src/database/schema.sql`, idempotente com `CREATE TABLE IF NOT EXISTS`).

### Rotas

| Método | Rota | Descrição |
| --- | --- | --- |
| `GET` | `/health` | Verifica API + conexão com o PostgreSQL |
| `GET` | `/ordens` | Lista todas as ordens (mais recentes primeiro) |
| `POST` | `/ordens` | Cadastra uma ordem |

**POST /ordens**

```json
{
  "ordemServico": 1024,
  "valor": 89.9
}
```

Resposta `201`:

```json
{
  "id": 1,
  "ordemServico": 1024,
  "valor": 89.9,
  "criadoEm": "2026-11-18T12:00:00.000Z"
}
```

Erros de validação retornam `400`:

```json
{
  "erro": "Dados inválidos.",
  "detalhes": ["\"valor\" deve ser um número maior ou igual a zero."]
}
```

---

## 4. Persistência local (SQLite)

Banco `oficina_bicicletas.db`, tabela `ordens_servico`:

| Coluna | Tipo | Papel |
| --- | --- | --- |
| `id` | INTEGER PK AUTOINCREMENT | id local |
| `ordem_servico` | INTEGER | número da OS |
| `valor` | REAL | valor do serviço |
| `sincronizado` | INTEGER (0/1) | `1` = confirmada pela API |
| `remote_id` | INTEGER | id devolvido pelo PostgreSQL |
| `criado_em` | TEXT (ISO-8601 UTC) | data do cadastro |

O acesso fica isolado em `lib/database/sqlite_database.dart`
(inserir, listar, listar pendentes, contar pendentes, marcar como sincronizada).

---

## 5. Fluxo offline-first

### API disponível

1. A tela de cadastro chama `OrdemServicoRepository.cadastrar`.
2. O repositório envia `POST /ordens`.
3. A API grava no PostgreSQL e devolve o `id`.
4. O registro é persistido no SQLite com `sincronizado = 1` e `remote_id`.
5. A lista exibe **"Sincronizada com a API"**.

### API indisponível

1. O envio HTTP falha (timeout, conexão recusada, erro 5xx etc.).
2. O repositório **não descarta** o cadastro.
3. A ordem é gravada no SQLite com `sincronizado = 0`.
4. A lista exibe **"Pendente de sincronização"**, ícone de nuvem desligada,
   contador no topo e faixa de aviso.

### API volta a responder

1. O usuário toca no ícone de sincronização (ou em **Sincronizar** na faixa).
2. O repositório busca as ordens com `sincronizado = 0`.
3. Cada ordem é enviada via `POST /ordens`.
4. Somente após a confirmação do servidor o registro é marcado com
   `sincronizado = 1` e o `remote_id` recebido.
5. A lista e o contador são atualizados; um `SnackBar` informa quantas ordens
   foram sincronizadas e quantas continuam pendentes.

Se a conexão cair durante a sincronização, o processo para na primeira falha
de rede para não repetir timeouts em todas as ordens; as restantes permanecem
pendentes e podem ser reenviadas depois.

### Onde fica cada responsabilidade

- **UI** (`screens`, `main.dart`): apenas estado de tela e feedback ao usuário.
- **Repository**: decide entre API e SQLite e controla a marcação de
  pendências/sincronização.
- **Service**: única camada que conhece HTTP e o formato JSON da API.
- **Database**: única camada que conhece SQL/SQLite.

---

## 6. Executar o aplicativo

Pré-requisitos: Flutter 3.x, um dispositivo/emulador Android (SQLite não roda
no Flutter Web) e a API acessível.

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

- `10.0.2.2` é o host da máquina visto pelo **emulador Android**.
- Em aparelho físico, use o IP da máquina na rede local, por exemplo:
  `--dart-define=API_BASE_URL=http://192.168.0.10:3000`.
- Sem `--dart-define`, o padrão é `http://10.0.2.2:3000`.
- Para dispositivo físico em HTTP, o Android já está configurado com
  `usesCleartextTraffic`; em produção prefira HTTPS.

---

## 7. Testes manuais dos três cenários

Os cenários abaixo descrevem a validação funcional esperada. Execute-os com a
API/PostgreSQL configurados.

1. **API disponível**
   - API no ar, cadastrar OS no app.
   - Esperado: `POST /ordens` retorna `201`; lista mostra "Sincronizada";
     registro presente em `GET /ordens` e no PostgreSQL.

2. **API indisponível**
   - Parar a API (ou deixar `API_BASE_URL` apontando para uma porta fechada).
   - Cadastrar OS no app.
   - Esperado: cadastro aceito, salvo no SQLite, "Pendente de sincronização";
     contador e faixa de aviso visíveis.

3. **Sincronização manual**
   - Religar a API e tocar no ícone de sincronização.
   - Esperado: ordens pendentes enviadas, marcadas como sincronizadas após
     confirmação, contador zerado e registro disponível em `GET /ordens`.

### Verificação estática executada neste repositório

```bash
flutter pub get
flutter analyze
```

A API **não foi executada** nesta máquina nesta etapa, pois depende de um
PostgreSQL remoto configurado (`DATABASE_URL`). Nenhum resultado de teste de
integração é inventado neste documento: os três cenários acima precisam ser
executados com credenciais reais.

---

## 8. Publicação

### Android

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://SUA-API
```

- Gere uma keystore própria e configure `android/key.properties` +
  `signingConfigs` (o projeto ainda usa a assinatura de debug).
- A API deve estar publicada com HTTPS (Render, Railway, Fly.io, VPS etc.) e o
  PostgreSQL remoto (Neon, Supabase, Railway, RDS etc.) com `DATABASE_URL`
  configurada no painel do serviço.

### Checklist

- [ ] `api/.env` criado fora do versionamento.
- [ ] `DATABASE_URL` do PostgreSQL remoto válida.
- [ ] `POST /ordens` e `GET /ordens` respondendo no host público.
- [ ] `--dart-define=API_BASE_URL` apontando para a API publicada.
- [ ] Testar os três cenários (online, offline e sincronização manual).
- [ ] Chave de assinatura release configurada.

---

## 9. Pendências que exigem ação manual

- Criar o banco PostgreSQL remoto e preencher `api/.env`.
- Executar `npm install` e publicar a API (não há infraestrutura publicada por
  este repositório).
- Rodar o app em emulador/dispositivo para validar os três cenários reais.
- Configurar assinatura release e URL HTTPS antes de publicar na loja.
