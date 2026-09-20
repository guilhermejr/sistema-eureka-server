# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The **service registry**. Every microservice registers here, and the gateway resolves `lb://<service>` routes through it.

| | |
|---|---|
| Port | `8761` |

## Security

Two in-memory users, credentials from Vault:

| User | Role | Access |
|---|---|---|
| `${eurekaServerUser}` | `ROLE_ADMIN` | dashboard and registration API |
| `${actuatorUser}` | `ROLE_ACTUATOR` | `/actuator/**` only |

`/actuator/health` is public so orchestrators can probe it.

**Careful:** the two users must have different usernames. Pointing both Vault keys at the same value makes `InMemoryUserDetailsManager` fail at startup with `user should not exist`.

## Running it locally

Do **not** pass `--eureka.client.enabled=false`. The Eureka *server* needs the client beans; disabling them fails startup with a missing `ApplicationInfoManager`.

## Registration lag

A newly registered service can take ~30s to become routable through the gateway, because of the registry refresh interval. A 503 right after a deploy usually means just that.

## Configuration comes from outside

This service stores almost no configuration of its own. `application.yml` only bootstraps `spring.config.import`, which pulls from:

- **Vault** — `secret/application` (shared: `JWTSecret`, actuator credentials, mail, AWS) and `secret/<service-name>` (its own DB credentials)
- **Config Server** — `server.port`, `server.servlet.context-path`, datasource, JPA settings

Both must be reachable or the service will not start.

`VAULT_TOKEN` is required and **has no default**. Without it Spring sends the literal string `${VAULT_TOKEN}` to Vault, gets a 403 that Spring Cloud Vault swallows (`fail-fast` is off), and the startup fails much later with a misleading `${someProperty} is malformed`. If you are chasing a confusing startup error, check `VAULT_TOKEN` first.

## Building and running

Java **21 only**. The Homebrew default JDK on this machine is newer and will break the build:

```bash
export JAVA_HOME=/Users/guilhermejr/Library/Java/JavaVirtualMachines/openjdk-21.0.2/Contents/Home
./mvnw clean package
VAULT_TOKEN=<token> java -jar target/*.jar --spring.profiles.active=dev
```

Do not raise `java.version` past 21 while ModelMapper is a dependency — the ByteBuddy bundled in it cannot generate classes on JDK 24+, and the app dies building its mappers with an `UnsupportedOperationException` that does not name the real cause.

## Deploying

`git push origin main` **is** the deploy. A `post-receive` hook on the VPS checks out, runs `mvn clean package` inside a throwaway `maven:3.9-amazoncorretto-21` container, builds the image and restarts it via docker compose. There is no separate release step.

Because the build happens on the VPS, any dependency from a private repository needs credentials **there**, not locally — the hook mounts `/home/guilhermejr/.m2` and passes `GITHUB_TOKEN`.

The `Dockerfile` only copies a prebuilt jar; it carries a `HEALTHCHECK` that polls `/actuator/health`.
