---
name: worktree-docker
description: Use when running multiple git branches simultaneously, spinning up parallel dev environments, managing worktree Docker containers, or needing isolated dev stacks per branch. Triggers on "worktree docker", "parallel dev", "run another branch", "isolated environment".
---

# Worktree Docker

Manage Docker-containerized git worktrees with full lifecycle support. Creates isolated dev environments per branch with shared infrastructure and unique ports.

**Announce:** "I'm using the worktree-docker skill to [create/start/stop/list/destroy] a containerized worktree."

## Prerequisites

- Docker and Docker Compose v2 (`docker compose` subcommand)
- Git with worktree support
- A project with a `docker-compose.yml`

## Quick Reference

| Command | What it does |
|---------|-------------|
| `create <branch>` | Create worktree + Docker config + database + start |
| `start [branch]` | Start a worktree's services (and shared infra if needed) |
| `stop [branch]` | Stop a worktree's services (keep shared infra) |
| `list` | Show all worktrees with slots, ports, status |
| `destroy <branch>` | Stop services, drop database, remove worktree |
| `status` | Health check all running stacks |

## Architecture

```
Shared infra (one set):        Per-worktree (isolated):
  Postgres (:5432)               Rails (:3003 + slot*100)
  Redis (:6379)                  Vite  (:3036 + slot*100)
  Kafka (:9092)                  Sidekiq (no port)
  Schema Registry (:9090)        Karafka (no port)
```

Each worktree gets a **slot** (0-3). App service ports = `base_port + (slot * 100)`.

## Create Command

### Step 1: Determine branch type

```bash
# Check if branch already exists (local or remote)
git branch --list <branch> | grep -q . && echo "exists" || \
git branch -r --list "origin/<branch>" | grep -q . && echo "remote" || echo "new"
```

- **Existing local branch**: `git worktree add <path> <branch>`
- **Existing remote branch**: `git worktree add <path> <branch>` (auto-tracks remote)
- **New branch**: `git worktree add <path> -b <branch>`

### Step 2: Create worktree

Follow the `using-git-worktrees` skill for:
- Directory selection (`.worktrees/` preferred)
- Safety verification (`.gitignore` check)
- Project setup (bundle install, yarn install, etc.)

The worktree path will be: `.worktrees/<sanitized-branch-name>/`

Branch name sanitization: replace `/` with `-` for directory names.

### Step 3: Allocate slot

Read `.worktrees/.docker-registry.json`. For each candidate slot (starting from 0), verify its ports are actually free using `lsof -i :<port>`. Pick the first `null` slot whose ports are all available. If all 4 slots are taken or all have port conflicts, report current allocations and ask which to stop/destroy.

### Step 4: Classify services (first run only)

Parse the project's `docker-compose.yml` to classify services:

**Infrastructure** (shared) — matches ANY of:
- Image matches: `postgres`, `redis`, `mysql`, `mariadb`, `mongo`, `kafka`, `zookeeper`, `elasticsearch`, `rabbitmq`, `memcached`, `minio`, `apicurio`, `schema-registry`, `kafka-ui`
- Has no `build:` directive AND does not mount project source
- Has label `worktree.role: infra`

**App** (per-worktree) — matches ANY of:
- Has a `build:` directive
- Mounts project directory (`volumes: - .:/app` or similar)
- Has label `worktree.role: app`

Present classification to user for confirmation:

```
Service classification for docker-compose.yml:

INFRASTRUCTURE (shared):
  - db (postgres:17.5-alpine)
  - cache (redis:7.0.0-alpine3.15)
  - kafka (extends kafka.yml)

APP (per-worktree):
  - web (builds docker/Dockerfile)

Does this look right? (y/n/edit)
```

Cache result in `.worktrees/.docker-config.json` (see references/config-template.md for schema).

### Step 5: Generate Docker Compose files

If `.worktrees/docker-compose.infra.yml` doesn't exist, generate it from the classified infra services. See references/config-template.md for template.

Generate per-worktree override at `.worktrees/<branch>/.docker-compose.worktree.yml`. See references/config-template.md for template.

**Critical networking:** All compose files use an external Docker network named `<project>-worktree-shared`. The infra compose creates it; worktree composes reference it as `external: true`.

### Step 6: Create isolated database

```bash
# Ensure infra is running
docker compose -f .worktrees/docker-compose.infra.yml up -d

# Create database for this slot
docker compose -f .worktrees/docker-compose.infra.yml exec db \
  createdb -U <postgres_user> <project>_development_wt<slot>
```

### Step 7: Generate .env.worktree

Write `.worktrees/<branch>/.env.worktree` with slot-specific overrides. See references/config-template.md for template.

### Step 8: Run database setup

```bash
cd .worktrees/<branch>
source .env.worktree
bin/rails db:schema:load  # or db:migrate if schema already loaded
```

### Step 9: Update registry and report

Update `.worktrees/.docker-registry.json` with the new slot allocation.

Report:
```
Worktree ready:
  Branch: <branch>
  Path: .worktrees/<branch>/
  Slot: <N>
  Rails: http://localhost:<port>
  Database: <project>_development_wt<slot>

To start: cd .worktrees/<branch> && source .env.worktree && <project-start-command>
Or Docker: docker compose -f .docker-compose.worktree.yml up

Detect the project's start command by checking (in order):
1. `package.json` scripts: look for `start` script → `yarn start`
2. `Procfile.dev` exists → `the project's start command (e.g. `yarn start`, `bin/dev`)`
3. `the project's start command (e.g. `yarn start`, `bin/dev`)` exists → `the project's start command (e.g. `yarn start`, `bin/dev`)`
4. Ask the user
```

## Start Command

```bash
# 1. Ensure shared infra is running
docker compose -f .worktrees/docker-compose.infra.yml up -d

# 2. Start worktree app services (Docker mode)
docker compose -f .worktrees/<branch>/.docker-compose.worktree.yml up -d

# OR host-native mode:
cd .worktrees/<branch>
source .env.worktree
the project's start command (e.g. `yarn start`, `bin/dev`)
```

Update registry status to `"running"`.

## Stop Command

```bash
# Stop worktree services only (keep shared infra)
docker compose -f .worktrees/<branch>/.docker-compose.worktree.yml down

# OR if running host-native, Ctrl-C the the project's start command (e.g. `yarn start`, `bin/dev`) process
```

Update registry status to `"stopped"`. Do NOT stop shared infra — other worktrees may need it.

## List Command

Read `.worktrees/.docker-registry.json` and display:

```
Slot  Branch              Status   Rails    Database
0     feature/auth        running  :3003    mithrin_development_wt0
1     feature/billing     stopped  :3103    mithrin_development_wt1
2     (available)
3     (available)

Shared infra: running (postgres:5432, redis:6379, kafka:9092)
```

## Destroy Command

```bash
# 1. Stop worktree services if running
docker compose -f .worktrees/<branch>/.docker-compose.worktree.yml down 2>/dev/null

# 2. Drop the database
docker compose -f .worktrees/docker-compose.infra.yml exec db \
  dropdb -U <postgres_user> --if-exists <project>_development_wt<slot>

# 3. Remove the git worktree
git worktree remove .worktrees/<branch> --force

# 4. Free slot in registry (set to null)
```

Ask for confirmation before destroying.

## Status Command

For each running worktree, check:
```bash
# Port accessibility
curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>/
# Container health
docker compose -f .worktrees/<branch>/.docker-compose.worktree.yml ps
```

## Port Allocation Reference

Slot offset = `slot * 100`. Read the project's compose file to discover base ports for each app service, then apply offset.

| Slot | Offset | Example (base 3003) | Example (base 3036) |
|------|--------|---------------------|---------------------|
| 0 | +0 | :3003 | :3036 |
| 1 | +100 | :3103 | :3136 |
| 2 | +200 | :3203 | :3236 |
| 3 | +300 | :3303 | :3336 |

Before starting, verify ports aren't in use:
```bash
lsof -i :<port> 2>/dev/null && echo "PORT IN USE" || echo "available"
```

## Database Isolation

| Service | Isolation method |
|---------|-----------------|
| Postgres | Separate database: `<project>_development_wt<slot>` |
| Redis | Database number: `redis://host:6379/<slot>` |
| Kafka | Topic prefix env var: `KAFKA_TOPIC_PREFIX=wt<slot>_` |

## Hybrid Mode (Recommended)

Most projects run app services natively (not in Docker). The skill supports this:
- Docker runs **only infrastructure** (Postgres, Redis, Kafka)
- App services run via `the project's start command (e.g. `yarn start`, `bin/dev`)` or foreman in each worktree
- `.env.worktree` provides correct connection strings with slot-specific ports

This is the default recommendation. Only use Docker for app services if the project requires it.

## Edge Cases

| Situation | Action |
|-----------|--------|
| All 4 slots taken | Show current allocations, ask which to stop/destroy |
| Port already in use | Check with `lsof`, suggest next available slot |
| Worktree exists without Docker config | Offer to retroactively set up (allocate slot, generate files) |
| Shared infra not running | `start` always ensures infra is up first |
| Branch name has slashes | Sanitize: replace `/` with `-` for directory and service names |
| Multiple compose files | Follow `COMPOSE_FILE` env var or detect from project |
| Registry file corrupted | Rebuild from `docker ps` and `git worktree list` |
| macOS memory pressure | Warn when creating 3rd+ stack; suggest stopping unused ones |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Stopping shared infra | Never stop infra unless ALL worktrees are stopped |
| Forgetting to source .env.worktree | Always `source .env.worktree` before running host-native services |
| Running db:create instead of createdb | Use `createdb` via docker exec on the shared Postgres container |
| Not checking port conflicts | Always `lsof -i :<port>` before starting |
| Hardcoded ports in project config | After creating worktree, patch `Procfile.dev` (Rails `-p` flag), `config/vite.json` (port), and any other files with hardcoded ports to use the slot's ports. Env vars alone may not override these. |

## Integration

**Delegates to:** `using-git-worktrees` for worktree creation (Step 2 of create)
**Works with:** Any project that has a `docker-compose.yml`
