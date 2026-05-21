#!/bin/sh
set -e

CRON_SCHEDULE="${CRON_SCHEDULE:-0 * * * *}"

# Write crontab using the configured schedule
echo "$CRON_SCHEDULE /usr/local/bin/sync.sh >> /var/log/sync.log 2>&1" > /etc/crontabs/root

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting rsync-ssh (schedule: $CRON_SCHEDULE)"

# Run once immediately on startup
/usr/local/bin/sync.sh

# Hand off to cron daemon (runs in foreground to keep container alive)
exec crond -f -l 2
