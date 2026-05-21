# SPEC: rsync-ssh

## Overview
A Docker container that syncs files from local source paths to a Synology NAS over SSH using rsync. Syncs run on container startup and on a configurable cron schedule. Source files are removed after a confirmed successful transfer.

## Tech Stack
- Base image: `alpine:3.19`
- Tools: `rsync`, `openssh-client`, busybox `crond`
- Config: environment variables + a mounted plain-text pairs file

## Architecture
```
[Host volumes] --> [Container /data/...] --> rsync over SSH --> [Synology NAS]
```

- `entrypoint.sh` generates the crontab from `$CRON_SCHEDULE`, runs an initial sync, then starts `crond` in the foreground
- `sync.sh` reads `sync-pairs.txt`, loops over each `src:dst` pair, and runs rsync for each
- All connection config (host, user, key, port) comes from environment variables
- Path pairs come from a mounted config file

## Key Features (in priority order)
1. Multiple `src:dst` path pairs via a plain-text config file
2. Run on startup + hourly cron (configurable)
3. SSH key authentication
4. Delete source files after successful transfer (`--remove-source-files`)
5. Structured logging with timestamps per pair

## Environment Variables
| Variable | Default | Description |
|---|---|---|
| `NAS_HOST` | required | Synology hostname or IP |
| `NAS_USER` | required | SSH username on the NAS |
| `NAS_PORT` | `22` | SSH port |
| `SSH_KEY_PATH` | `/root/.ssh/id_rsa` | Path to mounted private key |
| `SYNC_PAIRS_FILE` | `/config/sync-pairs.txt` | Path to the pairs config file |
| `CRON_SCHEDULE` | `0 * * * *` | Cron expression for sync schedule |

## Out of Scope
- Multiple destination hosts (all pairs go to the same NAS)
- Per-pair rsync flag overrides
- Encryption or compression beyond what SSH provides
- Push notifications or alerting on failure
