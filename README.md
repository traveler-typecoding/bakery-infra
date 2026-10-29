# bakery-infra

Orchestration repo for the Bakery system. Holds the Docker Compose stack,
environment config, database init scripts, and operational docs. The actual
application source lives in separate repos.

## Related repos

| Repo             | Contents                                   |
|------------------|--------------------------------------------|
| `bakery-infra`   | This repo: compose, env, db init, ops docs |
| `bakery-golang`  | Go backend: source, Dockerfile, migrations |
| `bakery-angular` | Angular frontend: source, Dockerfile       |

## Expected local layout

Compose references the sibling repos by relative path, so clone all three
side by side:

```
bakery-system/
├── bakery-infra/      # <- you run docker compose from here
├── bakery-golang/
└── bakery-angular/
```

```bash
git clone <url>/bakery-infra.git
git clone <url>/bakery-golang.git
git clone <url>/bakery-angular.git
```

If you keep them elsewhere, override the paths in `.env`:
`BACKEND_CONTEXT` and `FRONTEND_CONTEXT`.

## First run (build from source)

```bash
cp .env.example .env     # Windows: copy .env.example .env
docker compose up --build
```

- Frontend: http://localhost:4200
- Backend:  http://localhost:8080/health
- Postgres: localhost:5432

## Two ways to run a service

The backend/frontend services have both a `build:` (from the sibling repo) and
an `image:` tag:

- **Build from source** (local dev) — `docker compose up --build`. Uses
  `BACKEND_CONTEXT` / `FRONTEND_CONTEXT`.
- **Pull prebuilt images** (CI / prod) — set `BACKEND_IMAGE` /
  `FRONTEND_IMAGE` in `.env` to registry tags, then
  `docker compose pull && docker compose up -d`. No source checkout needed.

In a real deployment each service repo's CI builds and pushes its image; this
repo only references the tags.

## Dev vs prod targets

Driven by `.env`:

- `BACKEND_TARGET=dev` → Go hot reload (air); `prod` → static binary
- `FRONTEND_TARGET=dev` → ng serve; `prod` → nginx static

## Kafka (later)

Gated behind a compose profile so it stays off by default:

```bash
docker compose --profile kafka up --build
```

## Disk / volume growth

See [VOLUME_MANAGEMENT.md](./VOLUME_MANAGEMENT.md).

```bash
docker system df -v        # see what's using space
docker compose down        # stop, KEEP data
docker compose down -v     # stop, DELETE volumes (destroys DB)
```
