# Pinned Codex skills on the management account

This runbook installs third-party instructions for the `gildra-admin` account.
It does not install system packages, application runtimes or production
services, and it never requires `sudo`.

## Design

`agent/skills.lock.json` is the source of truth. Every GitHub source is pinned to
a full commit SHA. Compatible skills are downloaded into an inactive catalog at
`~/.local/share/gildra-agent-skills/catalog`. The selected profile is exposed to
Codex through symlinks in `~/.agents/skills`.

The default `server` profile contains infrastructure, Linux, Docker, CI/CD,
database, Cloudflare, reliability, secrets and security review guidance needed
for this repository. Backend, frontend, design and offensive test guidance stays
in the catalog until work in the matching repository or isolated test
environment is explicitly authorized.

This separation is intentional: Codex discovers skill metadata at startup, and
an excessively large active set can exceed the initial skill-description budget.
Symlinked skill directories are supported by Codex.

## Trust boundary

Installation copies third-party text and supporting files; it does not make the
content trusted. The manager:

- validates repository names, immutable SHAs and traversal-safe source paths;
- uses the bundled official Codex GitHub skill installer without shell pipes;
- requires `SKILL.md` frontmatter with a name and description;
- rejects catalog entries that are symlinks or contain symlinks escaping their
  own directory;
- records repository, SHA and source path beside each installed skill;
- refuses to overwrite an existing catalog entry or unmanaged active path;
- never executes scripts shipped by a downloaded skill.

Review changed pins and upstream diffs before every catalog update. The manifest
records provenance, not a permanent security approval of upstream content.

## Preflight

Run from the checked-out `Server` repository as `gildra-admin`:

```bash
test "$(id -un)" = gildra-admin
test -f "$HOME/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py"
python3 --version
git status --short
python3 scripts/manage-agent-skills.py \
  --manifest agent/skills.lock.json \
  --check-manifest
```

Abort if the worktree is dirty for an unexplained reason, the bundled installer
is missing, a source pin changed without review, or any command requests `sudo`,
a credential, a GitHub token for public sources, or execution of downloaded
code.

## Install the catalog

```bash
python3 scripts/manage-agent-skills.py \
  --manifest agent/skills.lock.json \
  --installer "$HOME/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py" \
  --install-catalog
```

The operation is idempotent only when every existing entry has the expected
`.gildra-source.json` marker. A mismatched or unmarked directory is a stop
condition and must be reviewed manually; do not delete it to force success.

## Activate and verify the server profile

```bash
python3 scripts/manage-agent-skills.py \
  --manifest agent/skills.lock.json \
  --activate-profile server \
  --check-catalog

find "$HOME/.agents/skills" -maxdepth 1 -type l -printf '%f -> %l\n' | sort
```

Restart Codex after installing or changing the active profile. If a skill does
not appear, verify its `SKILL.md` name and description, the symlink target and the
active-root permissions before changing any configuration.

Other profiles can be activated later with `--activate-profile backend`,
`frontend`, `design` or `security`. Activation replaces only symlinks listed in
`.gildra-managed.json`; unrelated user files are preserved and collisions stop
the operation.

## Deferred sources and developer tools

The manifest identifies repositories that were requested but do not currently
provide a compatible standalone `SKILL.md`, or provide a plugin requiring a
separate permission review. They are not silently converted or installed.

Storybook, Chromatic, Changesets, Renovate, golangci-lint, Biome and Turborepo
are also recorded but deferred. Once application code exists, add exact versions
to the owning repository and run them in its development/CI environment. They do
not belong as untracked global programs on the production candidate.

## Update procedure

1. Inspect the upstream repository and license read-only.
2. Review the diff from the old SHA to the proposed SHA, including `SKILL.md`,
   references, scripts and assets.
3. Update the full SHA in `agent/skills.lock.json` through a reviewed Server
   change and run `./scripts/validate.ps1`.
4. Install to a new empty test catalog first. The manager intentionally does not
   overwrite an existing pinned entry.
5. Record the result in `docs/operations/`, then promote and reactivate only the
   required profile.

## Recovery

Skill activation has no production-service impact. To deactivate the managed
profile, move `~/.agents/skills/.gildra-managed.json` and the symlinks named in
that file into a private backup directory outside the repository. Do not remove
unmanaged paths. Restart Codex and verify that the skills are no longer listed.

The inactive catalog can remain for audit and rollback. Deleting it is not part
of this runbook. Re-activating the previous pinned catalog/profile restores the
prior state.
