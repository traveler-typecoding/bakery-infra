# Managing Docker Volume Growth

Named volumes (`postgres_data`, `kafka_data`) persist on the Docker host and
can grow without bound if you don't watch them. Here's how to monitor and
control that growth.

## 1. See where space is going

```bash
# High-level: images, containers, volumes, build cache
docker system df

# Per-volume detail (sizes)
docker system df -v

# Inspect one volume's mountpoint on the host
docker volume inspect docker_postgres_data
```

> Volume names are prefixed with the compose project name (the folder name).
> So `postgres_data` becomes `docker_postgres_data` here.

## 2. Reclaim space safely

```bash
# Remove dangling images + build cache + stopped containers (keeps volumes)
docker system prune

# Also remove volumes NOT used by any container — be careful
docker volume prune

# Remove only build cache
docker builder prune
```

`docker compose down` keeps your volumes. `docker compose down -v` DELETES
them (all database data gone). Know the difference.

## 3. Control growth at the source

Growth is already constrained in `docker-compose.yml`:

- **Container logs** — every service has a `json-file` log driver capped at
  `10m x 3 files`. Without this, container stdout logs grow forever.
- **Postgres WAL** — `max_wal_size=1GB` bounds write-ahead-log disk use.
- **Kafka retention** — `log.retention.hours=168` (7 days) and
  `log.retention.bytes=1GB` per partition cap topic data.

### Postgres-specific housekeeping

```bash
# Connect
docker compose exec postgres psql -U appuser -d appdb

# Find the biggest tables/indexes
\dt+
SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) AS size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;

# Reclaim bloat after large deletes (does NOT shrink the file; VACUUM FULL does)
VACUUM (VERBOSE, ANALYZE);
```

Autovacuum runs by default and keeps most bloat in check. `VACUUM FULL`
rewrites a table and returns disk to the OS, but it locks the table — run it
during a maintenance window.

## 4. Put a hard cap on a volume (optional)

A plain `local` volume uses all available host disk. To physically cap it,
back the volume with a size-limited filesystem. Two common approaches:

**a) tmpfs for throwaway data (RAM-backed, lost on restart):**

```yaml
volumes:
  - type: tmpfs
    target: /some/cache
    tmpfs:
      size: 536870912   # 512 MB
```

**b) A pre-sized loopback/ext4 image mounted at the volume path** — more
involved; usually overkill. Prefer the retention/log limits above plus host
disk monitoring.

## 5. Monitor on a schedule

Add this to cron (Linux) or Task Scheduler (Windows) to alert when the Docker
data root crosses a threshold. On Windows with Docker Desktop + WSL2, the data
lives inside the WSL distro's virtual disk (`ext4.vhdx`), which only ever
*grows*. To shrink it after pruning:

```powershell
wsl --shutdown
# then compact the vhdx (Docker Desktop: Settings > Resources > Disk, or)
Optimize-VHD -Path "$env:LOCALAPPDATA\Docker\wsl\data\ext4.vhdx" -Mode Full
```

## Quick reference

| Task                        | Command                                  |
|-----------------------------|------------------------------------------|
| Usage overview              | `docker system df -v`                    |
| Prune safe junk             | `docker system prune`                    |
| Prune unused volumes        | `docker volume prune`                    |
| Stop, keep data             | `docker compose down`                    |
| Stop, delete data           | `docker compose down -v`                 |
| Compact WSL vhdx (Windows)  | `Optimize-VHD ... -Mode Full`            |
