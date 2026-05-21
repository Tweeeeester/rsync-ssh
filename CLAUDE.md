# rsync-ssh

Docker container that syncs files to a Synology NAS over SSH using rsync.

## Stack
- Alpine Linux + rsync + openssh-client + busybox crond
- Config: env vars (`.env`) + mounted plain-text pairs file (`sync-pairs.txt`)

## Commands
```sh
docker compose build          # build the image
docker compose up             # run (syncs on start, then on cron)
docker compose run rsync-ssh  # one-shot run
```

## Key files
- `sync.sh` — core sync logic; reads pairs file, loops rsync calls
- `entrypoint.sh` — writes crontab from $CRON_SCHEDULE, runs sync once, starts crond
- `sync-pairs.txt` — user's live config (not committed); `.example` is the template
- `.env` — user's live config (not committed); `.env.example` is the template

## Rules
- MUST NOT commit `sync-pairs.txt`, `.env`, or any SSH keys
- Source files are deleted after successful transfer (`--remove-source-files`)
- All destination paths must already exist on the NAS before syncing
