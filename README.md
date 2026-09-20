# eureka-server

**Service registry** do sistema. É onde os microsserviços se registram e se descobrem.

## Stack

| Item | Versão |
|---|---|
| Java | 21 |
| Spring Boot | 4.1.1 |
| Spring Cloud | 2025.1.3 |

| Porta |
|---|
| 8761 |

## Painel

O painel web do Eureka fica em `http://localhost:8761`, protegido por **HTTP Basic**.

## Segurança

Dois usuários em memória, com credenciais vindas do Vault:

| Usuário | Perfil | Acesso |
|---|---|---|
| `${eurekaServerUser}` | `ROLE_ADMIN` | painel e API de registro |
| `${actuatorUser}` | `ROLE_ACTUATOR` | apenas `/actuator/**` |

## Registro dos clientes

Os serviços apontam para cá através de:

```yaml
eureka:
  client:
    service-url:
      defaultZone: 'http://<usuario>:<senha>@<host>:8761/eureka'
```

O `gateway-server` usa esse registro para resolver as rotas `lb://<nome-do-servico>`.

## Configuração

A aplicação não guarda configuração própria: ela busca tudo no arranque, via `spring.config.import`.

| Origem | O que vem de lá |
|---|---|
| **Vault** (`secret/application`) | segredos compartilhados: `JWTSecret`, credenciais de e-mail, AWS, Eureka |
| **Vault** (`secret/<nome-do-serviço>`) | segredos próprios, como as credenciais do banco |
| **Config Server** | `server.port`, `context-path`, datasource e demais propriedades |

### Variável de ambiente obrigatória

| Variável | Para que serve |
|---|---|
| `VAULT_TOKEN` | token de acesso ao Vault |

`VAULT_TOKEN` **não tem valor padrão**. Sem ela, o Spring envia a string literal `${VAULT_TOKEN}` ao Vault, recebe `403` e — como `spring.cloud.vault.fail-fast` vem desligado — o erro só aparece bem depois, disfarçado de placeholder não resolvido (`${...} is malformed`). Se quiser que a falha apareça na hora, ligue `spring.cloud.vault.fail-fast: true`.

Também são necessários `VAULT_HOST`, `VAULT_PORT` e `VAULT_SCHEME` quando o Vault não está em `localhost:8200` via `http`, e `CONFIG_SERVER_USER` / `CONFIG_SERVER_PASS` nos serviços que leem do Config Server.

## Como executar

```bash
# build
./mvnw clean package

# execução
VAULT_TOKEN=<seu-token> java -jar target/eureka-server-*.jar --spring.profiles.active=dev
```

A aplicação sobe em `http://localhost:8761`.

### Docker

O `Dockerfile` espera o jar já na raiz do projeto, com o nome `sistema-eureka-server.jar`:

```bash
./mvnw clean package
cp target/eureka-server-*.jar sistema-eureka-server.jar

docker build \
  --build-arg VAULT_HOST=<host> \
  --build-arg VAULT_TOKEN=<token> \
  -t eureka-server .
```
