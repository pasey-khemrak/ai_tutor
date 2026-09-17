"""Serve the built Flutter web app for local testing.

Two things this exists to prevent, both of which cost days once:

* A cached bundle. Every response is no-store, so a rebuild is always what the
  browser gets back.
* A stale service worker. One registered by an earlier build keeps serving its
  own cache for the origin it was registered on, which is indistinguishable from
  a fix that did not work. Switching the port gives a clean origin -- but only
  53123 and 53124 are in the gateway's CORS allowlist, so alternate between
  those two rather than inventing a new port.

Requests are logged next to this script, so it is possible to tell whether the
browser actually fetched the build or answered from its own cache.

    python3 tool/serve_web.py [port]   # from ai_tutor/
"""
import datetime
import functools
import http.server
import pathlib
import socketserver
import sys

ALLOWED_PORTS = (53123, 53124)
ROOT = pathlib.Path(__file__).resolve().parent.parent / "build" / "web"
LOG = pathlib.Path(__file__).resolve().parent / "serve_web.log"


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, fmt, *args):
        stamp = datetime.datetime.now().strftime("%H:%M:%S")
        with LOG.open("a") as log:
            log.write(f"{stamp} {fmt % args}\n")


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else ALLOWED_PORTS[0]
    if port not in ALLOWED_PORTS:
        sys.exit(f"port {port} is not in the gateway CORS allowlist {ALLOWED_PORTS}")
    if not (ROOT / "main.dart.js").exists():
        sys.exit(f"no build at {ROOT} -- run: flutter build web --pwa-strategy=none")
    handler = functools.partial(Handler, directory=str(ROOT))
    with Server(("127.0.0.1", port), handler) as httpd:
        print(f"serving {ROOT} on http://localhost:{port}")
        print(f"requests logged to {LOG}")
        httpd.serve_forever()
