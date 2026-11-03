#!/bin/sh
ROOT=/var/mobile/Library/BasementOS
CONF=$ROOT/lighttpd.conf
WWW=$ROOT/www
PID=$ROOT/lighttpd.pid
BIN=$(command -v lighttpd || echo /usr/sbin/lighttpd)

if [ "$1" = "stop" ]; then
  if [ -f "$PID" ]; then kill "$(cat $PID)" 2>/dev/null; rm -f "$PID"; fi
  killall lighttpd 2>/dev/null
  exit 0
fi

mkdir -p "$WWW"
if [ ! -f "$CONF" ]; then
cat > "$CONF" <<CONF
server.modules = ()
server.port = 8080
server.document-root = "$WWW/"
server.bind = "0.0.0.0"
server.pid-file = "$PID"
index-file.names = ( "index.html" )
mimetype.assign = ( ".html" => "text/html", ".css" => "text/css", ".js" => "text/javascript", ".txt" => "text/plain" )
CONF
fi
[ -f "$WWW/index.html" ] || printf '<html><body><h1>BasementOS</h1></body></html>' > "$WWW/index.html"
"$BIN" -f "$CONF"
echo "lighttpd started on :8080"
