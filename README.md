# rsync-ssh

A Docker container that syncs files to a Synology NAS over SSH using rsync. Runs on startup and on a configurable cron schedule. Source files are deleted after a confirmed successful transfer.

## Features

- Sync multiple source folders to different destinations on the same NAS
- Deletes source files after successful transfer (`--remove-source-files`)
- Runs on container startup, then on a cron schedule (default: hourly)
- SSH key authentication
- Docker healthcheck — fails if no sync has run in the last 2 hours

## Requirements

- Docker and Docker Compose
- An SSH key with access to the Synology NAS
- SSH enabled on the NAS (Control Panel → Terminal & SNMP → Enable SSH)
- Destination folders already created on the NAS

## Setup

**1. Copy the config files:**

```sh
cp .env.example .env
cp sync-pairs.txt.example sync-pairs.txt
```

**2. Edit `.env` with your NAS details:**

```sh
NAS_HOST=192.168.1.100
NAS_USER=backup
NAS_PORT=22
SSH_KEY_PATH=/root/.ssh/id_rsa
SYNC_PAIRS_FILE=/config/sync-pairs.txt
CRON_SCHEDULE=0 * * * *
```

**3. Edit `sync-pairs.txt` with your source and destination folders:**

```
/data/photos:/volume1/backups/photos
/data/documents:/volume1/backups/documents
```

The source path is the path **inside the container**. Map your host folders to these paths via volume mounts in the next step.

**4. Add your source volume mounts to `docker-compose.yml`:**

```yaml
volumes:
  - ~/.ssh/id_rsa:/root/.ssh/id_rsa:ro
  - ./sync-pairs.txt:/config/sync-pairs.txt:ro
  - /host/path/to/photos:/data/photos
  - /host/path/to/documents:/data/documents
```

**5. Build and start:**

```sh
docker compose up -d
```

## Usage

```sh
# Start (syncs immediately, then runs on schedule)
docker compose up -d

# Watch logs
docker compose logs -f

# Check health status
docker compose ps

# Run a manual sync
docker compose exec rsync-ssh /usr/local/bin/sync.sh

# Stop
docker compose down
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `NAS_HOST` | required | Synology hostname or IP |
| `NAS_USER` | required | SSH username on the NAS |
| `NAS_PORT` | `22` | SSH port |
| `SSH_KEY_PATH` | `/root/.ssh/id_rsa` | Path to the mounted private key inside the container |
| `SYNC_PAIRS_FILE` | `/config/sync-pairs.txt` | Path to the pairs config file inside the container |
| `CRON_SCHEDULE` | `0 * * * *` | Cron expression — see [crontab.guru](https://crontab.guru) |

## sync-pairs.txt format

One `source:destination` pair per line. Lines starting with `#` and blank lines are ignored.

```
# comment
/data/photos:/volume1/backups/photos
/data/documents:/volume1/backups/documents
```

## Healthcheck

The container is considered healthy if a sync has run within the last 2 hours. If you set `CRON_SCHEDULE` to a longer interval, update the threshold in both `Dockerfile` and `docker-compose.yml` (the `7200` value, in seconds).

## Notes

- `--remove-source-files` removes files but not directories. Empty directories are cleaned up automatically after each sync.
- The destination path must already exist on the NAS — rsync will not create it.
- If a pair fails, the source files are left in place and the next scheduled run will retry.
