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

## Synology NAS Setup

Complete these steps once in DSM before starting the container.

**1. Create a dedicated user**

Control Panel → User & Group → Create a user (e.g. `rsync`).

**2. Enable SSH access for the user**

The user needs a real home directory and shell. In DSM:

Control Panel → User & Group → Advanced → Enable user home service

This creates `/var/services/homes/<username>` for each user.

**3. Add the SSH public key**

SSH into the NAS as the rsync user (or as admin and `sudo su rsync`) and add the public key:

```sh
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAA... your-public-key" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**4. Grant rsync application privilege**

Control Panel → User & Group → Edit the user → Applications tab → enable **rsync**

Without this, Synology blocks rsync sessions at the application layer even after SSH auth succeeds.

**5. Grant shared folder permissions**

Control Panel → Shared Folder → select the destination folder → Edit → Permissions tab → set the rsync user to **Read/Write**

**6. Create destination directories**

rsync will not create destination directories. Create them manually on the NAS before the first sync:

```sh
mkdir -p /volume1/<shared-folder>/<destination-path>
```

**7. Use the NAS's direct LAN IP as `NAS_HOST`**

If you access the NAS by hostname, confirm what IP it resolves to from the container — it may differ from how your host machine resolves it (e.g. via a local `~/.ssh/config` override). Using the direct LAN IP (e.g. `10.19.0.2`) avoids this.

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
  - ~/.ssh/id_ed25519:/run/ssh/id_rsa:ro  # mounted to staging path; entrypoint copies to root-owned location
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
