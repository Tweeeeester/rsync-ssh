FROM alpine:3.18

RUN apk add --no-cache rsync openssh-client

COPY sync.sh /usr/local/bin/sync.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/sync.sh /usr/local/bin/entrypoint.sh

# Default config and data mount points
VOLUME ["/config", "/data"]

# Healthy = crond is alive and a sync ran within the last 2 hours (2x the default hourly schedule).
# Adjust the 7200 threshold if you change CRON_SCHEDULE.
HEALTHCHECK --interval=5m --timeout=10s --start-period=90s --retries=2 \
  CMD [ -f /tmp/last-sync ] && \
      [ $(( $(date +%s) - $(cat /tmp/last-sync) )) -lt 7200 ] || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
