#!/bin/sh
ROOT=/var/mobile/Library/BasementOS
PID=$ROOT/dropbear.pid
BIN=$(command -v dropbear || echo /usr/sbin/dropbear)
DROPBEAR_DSS=/etc/dropbear/dropbear_dss_host_key
DROPBEAR_RSA=/etc/dropbear/dropbear_rsa_host_key

if [ "$1" = "stop" ]; then
  if [ -f "$PID" ]; then kill "$(cat $PID)" 2>/dev/null; rm -f "$PID"; fi
  killall dropbear 2>/dev/null
  exit 0
fi

if [ ! -f "$DROPBEAR_RSA" ] || [ ! -f "$DROPBEAR_DSS" ]; then
  echo "dropbear: host keys missing (check /etc/dropbear/)" >&2
  exit 1
fi
mkdir -p "$ROOT"
"$BIN" -p 22 -P "$PID"
echo "dropbear started on :22"
