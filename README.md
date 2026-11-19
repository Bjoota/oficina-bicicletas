# Oficina de Bicicletas

- **Temática:** Oficina de Bicicletas
- **Estudante:** Bruno Jose Rodrigues Da Silva
- **API publicada:** https://oficina-bicicletas.onrender.com
- **Repositório:** https://github.com/Bjoota/oficina-bicicletas

## Estrutura

```text
lib/
├── components/editor.dart
├── models/ordem_servico.dart
├── screens/formulario.dart
├── services/api_service.dart
├── repository/ordem_servico_repository.dart
├── database/sqlite_database.dart
└── main.dart

api/
├── index.js
├── package.json
└── src/
    ├── app.js
    ├── routes/ordens.routes.js
    ├── controllers/ordens.controller.js
    ├── services/ordens.service.js
    ├── middlewares/errorHandler.js
    └── database/
        ├── index.js
        └── schema.sql
```

## API

| Método | Rota | Descrição |
| --- | --- | --- |
| `GET` | `/health` | Status da API e do PostgreSQL |
| `GET` | `/ordens` | Lista as ordens de serviço |
| `POST` | `/ordens` | Cadastra uma ordem |

```json
POST /ordens
{ "ordemServico": 1001, "valor": 89.90 }

201 Created
{ "id": 1, "ordemServico": 1001, "valor": 89.9, "criadoEm": "..." }
```

A API usa `DATABASE_URL` e `PORT` (veja `api/.env.example`). O schema é criado
automaticamente na inicialização.



## Testes realizados

```text
flutter analyze  → No issues found!
flutter test     → 2 testes aprovados
API /health      → 200 (PostgreSQL conectado)
API GET /ordens  → 200
API POST /ordens → 201 (registro gravado no PostgreSQL)
CORS             → liberado
```

Cenários para validar/demonstrar:

1. **Online:** cadastrar uma OS e conferir o registro em `/ordens`.
2. **Offline:** rodar com a URL inválida, cadastrar e ver o registro pendente.
3. **Sincronizar:** voltar a URL real, tocar em sincronizar e conferir em
   `/ordens`.

