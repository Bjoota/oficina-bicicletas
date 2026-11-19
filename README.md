# Oficina de Bicicletas

- **Temática:** Oficina de Bicicletas
- **Estudante:** Bruno Jose Rodrigues Da Silva
- **API publicada:** https://oficina-bicicletas.onrender.com
- **Repositório:** https://github.com/Bjoota/oficina-bicicletas

Aplicativo Flutter para cadastrar ordens de serviço (número da OS e valor) com
SQLite local, API Node.js/Express e PostgreSQL remoto. Funciona **offline-first**:
se a API estiver indisponível, o cadastro é salvo localmente como pendente e
pode ser sincronizado manualmente depois.

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

## Offline-first

1. **API disponível:** o repository envia `POST /ordens`, salva no SQLite com
   `sincronizado = 1` e o app mostra "Sincronizada com a API".
2. **API indisponível:** o cadastro é salvo no SQLite com `sincronizado = 0`,
   exibido como "Pendente de sincronização" com contador no topo.
3. **Sincronização manual:** o botão de nuvem envia os pendentes e marca cada
   registro como sincronizado somente após a confirmação do servidor.
4. **Buscar da API:** o outro botão importa registros remotos que ainda não
   existem no SQLite.

## Como rodar

```powershell
$env:Path = "C:\flutter\bin;" + $env:Path
flutter pub get
flutter run -d edge
```

O app usa por padrão `https://oficina-bicicletas.onrender.com`. O Render pode
levar ~30 s para acordar; o timeout do app é de 45 s.

Se o `flutter run -d edge` falhar ao conectar no debug service (instabilidade do
Edge), use o servidor web e abra a URL manualmente:

```powershell
flutter run -d web-server --release --web-port 53127
# abra http://127.0.0.1:53127 no Edge
```

### Atalho no Windows

Na Área de Trabalho há o atalho **Oficina de Bicicletas**. Ele executa
`abrir_oficina.ps1`, sobe o servidor local se necessário e abre o app em uma
janela própria do Edge (sem abas nem barra de endereço). A primeira abertura
pode levar até 1 minuto; depois é quase instantânea.

Para simular a API indisponível e depois sincronizar (mantenha a mesma porta
para preservar o SQLite do navegador):

```powershell
# offline
flutter run -d edge --web-port 53127 --dart-define=API_BASE_URL=http://127.0.0.1:9

# online novamente
flutter run -d edge --web-port 53127
```

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

## Roteiro do vídeo (até 5 min)

1. Abrir o app e mostrar a listagem.
2. Cadastrar uma OS com a API no ar e mostrar em `/ordens`.
3. Reiniciar com a URL inválida, cadastrar outra OS e mostrar como pendente.
4. Reiniciar com a URL real, sincronizar e mostrar o registro na API.
5. Mostrar rapidamente as pastas `services`, `repository` e `database`.

## API local (opcional)

```bash
cd api
npm install
npm start
```
