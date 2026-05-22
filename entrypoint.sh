#!/bin/sh
set -e

CRON_SCHEDULE="${CRON_SCHEDULE:-0 * * * *}"

# Copy mounted SSH key into a root-owned location so SSH accepts it
SSH_KEY_PATH="${SSH_KEY_PATH:-/root/.ssh/id_rsa}"
SSH_KEY_STAGING="${SSH_KEY_STAGING:-/run/ssh/id_rsa}"
if [ -f "$SSH_KEY_STAGING" ]; then
  mkdir -p "$(dirname "$SSH_KEY_PATH")"
  cp "$SSH_KEY_STAGING" "$SSH_KEY_PATH"
  chmod 600 "$SSH_KEY_PATH"
fi

# Write crontab using the configured schedule
echo "$CRON_SCHEDULE /usr/local/bin/sync.sh >> /var/log/sync.log 2>&1" > /etc/crontabs/root

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting rsync-ssh (schedule: $CRON_SCHEDULE)"

# Run once immediately on startup
/usr/local/bin/sync.sh

# Hand off to cron daemon (runs in foreground to keep container alive)
exec crond -f -l 2
