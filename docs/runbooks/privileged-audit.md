# Privileged read-only host audit

Operation family: `GLD-HOST-AUDIT-PRIVILEGED`. Использование `sudo` расширяет
доступ к чувствительным данным, хотя состояние хоста не меняется.

## Preconditions

1. Владелец подтвердил exact target `gildra-prod` и read-only scope.
2. Репозиторий Server clean и pinned на записанный commit SHA.
3. Работает текущая SSH session; OVH console/rescue path подтверждён.
4. Оператор знает, какие поля нужно редактировать до сохранения evidence.
5. Не устанавливать отсутствующие инструменты в рамках этого аудита.

## Разрешённые проверки

Сначала подтвердить identity и время, затем читать:

- effective SSH policy через `sudo sshd -T` и syntax через `sudo sshd -t`;
- listeners через `sudo ss -lntup`;
- активный firewall backend и ruleset через read-only
  `sudo nft list ruleset`, `sudo iptables-save` и `sudo ip6tables-save`;
- выбранные IPv4/IPv6 sysctls через `sudo sysctl`;
- `/proc/mdstat`, `sudo mdadm --detail --scan` и details каждого найденного
  md device;
- наличие `smartctl`; если он уже установлен — scan и health/details дисков;
- enabled/failed services, timers, AppArmor status и unattended-upgrades;
- sudo-capable accounts, effective sudo rules и authentication events;
- backup timers/jobs, artifact metadata, destination reference и alert path.

Если команда отсутствует, записать `tool_absent`. Не заменять этот факт
автоматической установкой.

## Запрещённые действия

В этом проходе нельзя выполнять `apt install/upgrade`, изменять files/permissions,
очищать logs, запускать backups, reload/restart services, менять SSH/firewall/
sysctl, создавать users/keys, запускать Compose или “исправлять” найденные ошибки.

Raw output не коммитится. Особенно редактируются hostnames, addresses, source IP,
usernames, fingerprints, serials, UUID, firewall source ranges, account IDs,
backup paths и любые credential-like values.

## Evidence format

Для каждой проверки сохранить в operation record:

| Поле | Значение |
|---|---|
| control | например `ssh.effective-policy` |
| timestamp | UTC |
| tool identity | binary и version, если доступна |
| result | `verified`, `not_verified`, `tool_absent`, `blocked` |
| redacted summary | только необходимый вывод |
| raw evidence | ссылка на approved private storage, не Git |
| candidate change | отдельное предложение, не authorization |

## Stop conditions

Остановить аудит при неожиданном target identity, RAID degradation, disk error,
недоступности console path, обнаружении credential material в output или если
команда имеет побочный эффект. Findings не исправляются в том же change.

## Completion

Обновить `docs/audits/` только редактированным summary. Затем подготовить
отдельную Stage 1 change card с точными diffs, checks, abort criteria и rollback.
