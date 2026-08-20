# Gildra Server

Воспроизводимая и проверяемая инфраструктура для **Gildra** — двуязычного сайта
с гайдами и аналитикой по World of Warcraft: PvE, PvP, Mythic+, рейды, тир-листы,
метрики и будущая игровая база данных.

Репозиторий находится на **этапе 0**. Купленный OVH-сервер обследован только в
режиме чтения; Docker и сервисы Gildra ещё не установлены и не запущены. Текущий
код подготавливает Debian-хост и описывает изолированный data plane:
PostgreSQL, ClickHouse и Redis.

Полный продуктовый стек и ответственность компонентов описаны в
[контексте проекта](docs/project-context.md), а порядок безопасного развёртывания —
в [плане](docs/deployment-plan.md).

## Safety model

- No IP addresses, passwords, API tokens, private keys, or production inventory are committed.
- Example files use documentation-only values and cannot authorize a deployment.
- Stateful services expose no host ports.
- Server changes require an explicit host limit, check-mode review, a change record,
  and a verified OVH console or rescue path.
- Production images must be locked by digest. Exact tags in `compose/env.example`
  are review defaults, not production approval.
- Агент может изменять только этот репозиторий. Остальные репозитории
  [Gildra Foundation](https://github.com/orgs/Gildra-Foundation/repositories)
  доступны ему исключительно для чтения и отслеживания контрактов.

## Repository map

```text
AGENTS.md               Полномочия и обязательные правила для агентов
ansible/                 Host audit and Debian bootstrap
compose/                 Isolated PostgreSQL, ClickHouse and Redis services
docs/project-context.md  Что такое Gildra и какой стек требуется
docs/architecture.md     Целевая архитектура и trust boundaries
docs/deployment-plan.md  Этапы, gates и критерии готовности
docs/audits/             Редактированные результаты обследований
docs/runbooks/           Human-operated procedures
docs/operations/         Append-only change records
scripts/validate.ps1     Local, secret-safe validation
agent/skills.lock.json   Pinned third-party Codex skill catalog and profiles
.github/workflows/       Pull-request checks only
```

## Начало работы для инфраструктурного агента

1. Прочитать `AGENTS.md` и документы из карты выше.
2. Выполнить `git pull --ff-only` в локальном клоне `Server`.
3. При необходимости проверить обновления организации только для чтения:
   [Gildra Foundation repositories](https://github.com/orgs/Gildra-Foundation/repositories).
4. Перед любой настройкой сервера выполнить read-only audit и подготовить
   отдельную change card. Текущий известный baseline находится в
   [аудите от 2026-08-20](docs/audits/2026-08-20-initial.md).
5. Для воспроизводимой установки пользовательских навыков Codex использовать
   [runbook agent tooling](docs/runbooks/agent-tooling.md); не устанавливать
   frontend/backend build-инструменты глобально на production-хост.

Рабочий SSH alias в инструкциях — `gildra-prod`. Реальные адреса, hostnames,
идентификаторы OVH и credentials в Git не добавляются.

## Local validation

Requirements: PowerShell 7, Docker Compose, Python 3.11+, `ansible-core==2.19.12`, and
`yamllint==1.38.0`.

Run Ansible from Linux, WSL, or CI; native Windows is not an Ansible control node.

```powershell
./scripts/validate.ps1
```

Use the production switch only after replacing image tags with reviewed digests:

```powershell
./scripts/validate.ps1 -Production
```

## Preparing an inventory

Copy the example locally. The destination is ignored by Git.

```powershell
Copy-Item ansible/inventories/production/hosts.example.yml `
  ansible/inventories/production/hosts.yml
```

Put only a hostname or SSH-config alias in `hosts.yml`; never put a password or
private key in it. Follow [the bootstrap runbook](docs/runbooks/bootstrap.md) before
using a mutating playbook.

## Current non-goals

- Application Dockerfiles: Go and Next.js do not exist yet.
- Неутверждённые Cloudflare, DNS, firewall и SSH mutations.
- Database initialization or migrations.
- Production deployment до выполнения gates из `docs/deployment-plan.md`.
- Изменения в любых репозиториях организации, кроме `Server`.

Git remote уже настроен на
[Gildra-Foundation/Server](https://github.com/Gildra-Foundation/Server).
