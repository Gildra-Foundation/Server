# План настройки и развёртывания Gildra

Это последовательность gates, а не команда “установить всё”. Переход к следующему
этапу разрешён после acceptance предыдущего и отдельного change record.

## Этап 0 — контекст и read-only baseline

Статус: **in progress**.

Работы:

- поддерживать product context, repository boundary и architecture;
- выполнить non-privileged и затем одобренный privileged read-only audit;
- подтвердить effective SSH config, firewall, public listeners, sysctls, SMART,
  RAID detail, alert delivery, package state и backup absence;
- сохранить доказательства в редактированном виде.

Acceptance:

- Debian 12 отражён в Ansible;
- console/rescue path подтверждён владельцем;
- неизвестные privileged facts имеют владельца и следующий шаг;
- никаких изменений хоста не выполнено в рамках аудита.

Rollback: не требуется, этап read-only.

## Этап 1 — host baseline и безопасный доступ

Risk: R3. Нужны точное подтверждение и открытая текущая SSH session.

Работы:

- установить только согласованные base packages и Docker;
- подтвердить источник Docker/Compose packages и наличие Compose v2 на Debian 12;
- проверить SMART и RAID alert delivery;
- определить один firewall backend и минимальный inbound allowlist;
- отключить ненужный LLMNR на public path;
- применить reviewed sysctl baseline;
- подтвердить effective SSH policy, выключить X11 и лишние auth methods только
  после проверки key path во второй session;
- создать `/srv/gildra` с минимальными permissions.

Acceptance:

- второй SSH login работает, provider console/rescue доступен;
- SSH syntax valid, firewall не закрыл management path;
- снаружи доступны только явно утверждённые ports;
- Docker daemon healthy, failed systemd units отсутствуют;
- RAID/SMART alerts доходят до реального внешнего получателя.

Abort: потеря второго access path, RAID degradation, неизвестный active firewall,
ошибка `sshd -t`, package conflict или новый public listener.

Rollback: dedicated config snippets, предыдущий firewall ruleset и OVH console.

## Этап 2 — recovery foundation

До production-данных:

- выбрать off-host destination и encryption owner;
- определить PostgreSQL backup/PITR, ClickHouse backup и config backup;
- задать retention, RPO/RTO и capacity;
- выполнить isolated restore в quarantined target;
- настроить backup age/integrity alerts.

Acceptance: успешный restore с integrity/application checks и измеренными RPO/RTO.
Успешный backup job без restore не считается acceptance.

## Этап 3 — data plane

Работы:

- выбрать reviewed image digests;
- создать secret files/references вне Git;
- проверить `docker compose config` и resource/volume/network plan;
- поднять PostgreSQL, ClickHouse и Redis без published ports;
- выполнить health, persistence, restart и recovery smoke tests;
- зафиксировать volume ownership и backup coverage.

Acceptance:

- target сообщает ожидаемые digests;
- healthchecks проходят после controlled restart;
- databases недоступны с public interface;
- PostgreSQL/ClickHouse входят в проверенный backup scope;
- Redis можно очистить без потери истины.

Rollback: остановка только новых stateless consumers и возврат к известным
digests. Volumes не удаляются. Stateful rollback опирается на restore plan.

## Этап 4 — application runtime

Gate: application repositories содержат immutable revision, Dockerfiles,
health/readiness endpoints, OpenAPI, migrations и environment contract.

Работы:

- добавить Next.js/Payload, Go API и River worker;
- запускать containers non-root, read-only где возможно;
- внедрить goose/Payload migration gate;
- подключить Sentry release/digest и structured redacted logs;
- проверить RU/EN critical paths, auth и subscription flows.

Acceptance:

- внешний smoke test проходит через temporary restricted ingress;
- migrations повторяемы и совместимы с rollback/forward-fix policy;
- worker retry/idempotency и queue lag наблюдаемы;
- secrets отсутствуют в images, logs и rendered Compose evidence.

## Этап 5 — edge, identity и media

Risk: R3 для Cloudflare/DNS/TLS/OAuth.

Работы:

- Cloudflare DNS/TLS/WAF/rate limits и origin restriction;
- Battle.net/email auth, затем Telegram/Discord/Patreon/Boosty links;
- Timeweb CDN + imgproxy и lifecycle media originals;
- IndexNow после появления canonical production URLs.

Acceptance:

- origin нельзя обойти по неутверждённому public path;
- OAuth state/PKCE/redirect allowlists и unlink/revoke flows проверены;
- media cache purge и origin failure имеют runbook;
- critical user path проходит только через intended edge.

## Этап 6 — observability и release automation

Работы:

- Beszel agent и выбранный безопасный hub placement;
- Plausible только после cookie/privacy и capacity решения;
- external uptime, user-path probes, alerts и runbooks;
- GitHub Actions: test, scan, build once, immutable image digest, SBOM/
  provenance, protected environment, deploy, verify и rollback;
- Testcontainers работают на isolated CI runner, не на production.

Acceptance:

- untrusted PR jobs не получают production secrets;
- actions pinned, permissions минимальны;
- deploy продвигает тот же digest, который был протестирован;
- environment approval и concurrency предотвращают racing deploys;
- target-reported digest и observation window подтверждены.

## Этап 7 — analytics и внешние imports

Работы:

- Warcraft Logs, wago.tools, SimulationCraft, Scrape.do и Bright Data только
  через bounded River jobs;
- per-provider timeout, retry, budget, rate limit, circuit breaker и provenance;
- ClickHouse event contracts, retention, MVs и dashboard query budgets;
- Cloudflare AI Gateway с ограничением spend/logging и отдельным token scope.

Acceptance:

- jobs idempotent, bounded и не блокируют web workload;
- raw payload retention минимизирован;
- provider outage не ломает core user path;
- cost, queue lag, data freshness и terms compliance наблюдаемы.

## Этап 8 — capacity-gated services

Postal, self-hosted Plausible, Beszel hub и тяжёлые SimulationCraft jobs
размещаются на основном host только после измерения CPU/RAM/IO, deliverability и
blast radius. Иначе они выносятся в отдельный approved environment.

## Общий production-ready gate

Gildra считается готовой к открытию только когда одновременно доказаны:

- внешний HTTPS user path и RU/EN critical journeys;
- access, firewall, TLS и origin restrictions;
- immutable deployed digests;
- database migration compatibility;
- off-host backup и isolated restore;
- alerts с владельцами и runbooks;
- отсутствие critical secret/vulnerability findings;
- rollback либо явно задокументированный forward-fix;
- устойчивость в согласованном observation window.
