#!/bin/sh

PAIRS_FILE="${SYNC_PAIRS_FILE:-/config/sync-pairs.txt}"
NAS_PORT="${NAS_PORT:-22}"
SSH_KEY="${SSH_KEY_PATH:-/root/.ssh/id_rsa}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

if [ ! -f "$PAIRS_FILE" ]; then
  log "ERROR: Sync pairs file not found: $PAIRS_FILE"
  exit 1
fi

if [ -z "$NAS_HOST" ] || [ -z "$NAS_USER" ]; then
  log "ERROR: NAS_HOST and NAS_USER environment variables must be set"
  exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
  log "ERROR: SSH key not found: $SSH_KEY"
  exit 1
fi

pair_count=0
success_count=0
fail_count=0

while IFS= read -r line; do
  # Skip blank lines and comments
  case "$line" in
    ''|\#*) continue ;;
  esac

  src="${line%%:*}"
  dst="${line#*:}"

  if [ -z "$src" ] || [ -z "$dst" ] || [ "$src" = "$dst" ]; then
    log "WARN: Skipping invalid pair: '$line'"
    continue
  fi

  pair_count=$((pair_count + 1))
  log "Syncing [$pair_count] $src -> $NAS_USER@$NAS_HOST:$dst"

  if rsync -avz --remove-source-files \
    -e "ssh -i $SSH_KEY -p $NAS_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
    "$src/" \
    "$NAS_USER@$NAS_HOST:$dst"; then

    # Remove empty directories left behind by --remove-source-files
    find "$src" -mindepth 1 -type d -empty -delete 2>/dev/null || true

    log "OK [$pair_count] $src"
    success_count=$((success_count + 1))
  else
    log "FAILED [$pair_count] $src (rsync exit code: $?)"
    fail_count=$((fail_count + 1))
  fi

done < "$PAIRS_FILE"

log "Done. $success_count succeeded, $fail_count failed (of $pair_count pairs)"

# Write timestamps for healthcheck
date +%s > /tmp/last-sync
[ "$fail_count" -eq 0 ] && date +%s > /tmp/last-sync-success || true
