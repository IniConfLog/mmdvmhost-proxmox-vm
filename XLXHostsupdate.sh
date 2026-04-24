#!/bin/bash
###############################################################################
# XLXHostsupdate.sh (PRODUCTION VERSION)
# Safe updater for DMRGateway XLXHosts.txt
###############################################################################

set -euo pipefail

# =========================
# CONFIG
# =========================

if [ -n "${1:-}" ]; then
  XLXHOSTS="$1"
else
  XLXHOSTS="$(dirname "$0")/XLXHosts.txt"
fi

BACKUP_COUNT=3
TMP_FILE="${XLXHOSTS}.tmp"
LOG_FILE="/var/log/xlxhostsupdate.log"

API_URL="http://xlxapi.rlx.lu/api.php?do=GetXLXDMRMaster"

echo "[$(date)] Starting XLX update -> $XLXHOSTS" | tee -a "$LOG_FILE"

# =========================
# REQUIREMENTS CHECK
# =========================

command -v curl >/dev/null 2>&1 || {
  echo "ERROR: curl not installed" | tee -a "$LOG_FILE"
  exit 1
}

# =========================
# DOWNLOAD SAFE (NO DIRECT WRITE)
# =========================

if ! curl -fsSL "$API_URL" > "$TMP_FILE"; then
  echo "ERROR: failed to download XLX master list" | tee -a "$LOG_FILE"
  rm -f "$TMP_FILE"
  exit 1
fi

# =========================
# VALIDATE CONTENT
# =========================

if [ ! -s "$TMP_FILE" ]; then
  echo "ERROR: downloaded file is empty" | tee -a "$LOG_FILE"
  rm -f "$TMP_FILE"
  exit 1
fi

# =========================
# BACKUP CURRENT FILE
# =========================

if [ -f "$XLXHOSTS" ]; then
  cp "$XLXHOSTS" "${XLXHOSTS}.$(date +%Y%m%d_%H%M%S)"

  # cleanup old backups
  ls -1t "${XLXHOSTS}".* 2>/dev/null | tail -n +$((BACKUP_COUNT+1)) | xargs -r rm -f
fi

# =========================
# GENERATE FILE
# =========================

awk '
BEGIN {
  print "# XLX Number;host;default module"
}

/^XLX/ {
  reflector=4004

  if ($1 == "XLX004") reflector=4001
  else if ($1 == "XLX235") reflector=4001
  else if ($1 == "XLX268") reflector=4005
  else if ($1 == "XLX284") reflector=4002
  else if ($1 == "XLX313") reflector=4001
  else if ($1 == "XLX359") reflector=4002
  else if ($1 == "XLX389") reflector=4017
  else if ($1 == "XLX518") reflector=4006
  else if ($1 == "XLX755") reflector=4011
  else if ($1 == "XLX886") reflector=4003
  else if ($1 == "XLX950") reflector=4005

  printf "%s;%s;%d\n",
    substr($1,4),
    substr($2,1,length($2)-1),
    reflector
}
' "$TMP_FILE" > "$XLXHOSTS"

rm -f "$TMP_FILE"

# =========================
# FINAL VALIDATION
# =========================

if [ ! -s "$XLXHOSTS" ]; then
  echo "CRITICAL ERROR: XLXHosts generation failed - restoring backup" | tee -a "$LOG_FILE"

  LATEST_BACKUP=$(ls -1t "${XLXHOSTS}".* 2>/dev/null | head -n 1)
  if [ -n "$LATEST_BACKUP" ]; then
    cp "$LATEST_BACKUP" "$XLXHOSTS"
  fi

  exit 1
fi

# =========================
# RESULT
# =========================

LINES=$(wc -l < "$XLXHOSTS")

echo "[$(date)] XLX update completed successfully. Lines: $LINES" | tee -a "$LOG_FILE"

exit 0
