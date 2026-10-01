#!/usr/bin/env bash
#
# Build the student web bundle and publish it to the VPS.
#
#   tool/deploy_web.sh
#
# Why this is a script rather than an rsync: Flutter's web entry points are not
# content-hashed. `index.html` always loads `flutter_bootstrap.js`, which always
# loads `main.dart.js`, under those exact names on every build. Cloudflare sits
# in front of the origin and caches both for hours, so a redeploy is invisible
# to anyone whose browser or edge node already holds them -- the origin serves
# the new code and the students keep running the old.
#
# Two things fix that, and both are needed:
#
#   * The origin stops claiming the unhashed entry points are cacheable. That
#     is in bin/serve_web.py on the server, and stops the problem recurring.
#   * This script stamps a content hash into the two references. `index.html`
#     is sent no-store, so a fresh index always names a bootstrap URL that is
#     new whenever the build changed, which in turn names a new main.dart.js
#     URL. A new URL is a new cache key, so it cannot be served stale -- and
#     an unchanged build produces an unchanged stamp and stays cached.
set -euo pipefail

cd "$(dirname "$0")/.."

KEY=${DEPLOY_KEY:-$HOME/.ssh/aitutor_ed25519}
HOST=${DEPLOY_HOST:-brathna@100.125.135.15}
API=${DEPLOY_API:-https://aitutor.mekhla.digital/api/v1}
SITE=${DEPLOY_SITE:-https://aitutor.mekhla.digital}
SSH=(ssh -i "$KEY" -o BatchMode=yes)

say() { printf '\n\033[1m== %s\033[0m\n' "$1"; }

say "1/5  building"
flutter build web --pwa-strategy=none \
  --dart-define=APP_ENV=production \
  --dart-define=BACKEND_BASE_URL="$API"

# Assert the build is actually pointed at the API before anything ships.
#
# --dart-define values are compiled in, and Flutter's incremental build does
# not reliably invalidate on a define change: a plain `flutter build web` run
# once for any reason leaves a cached kernel that later builds reuse, and the
# localhost default in app_config.dart then rides out to production. Every
# request from the live site went to http://localhost:4000 and the browser
# reported it as a CORS error.
#
# Byte-comparing the build against the edge cannot catch this -- the bytes
# matched perfectly while being wrong -- so the content is checked instead.
host=$(printf '%s' "$API" | sed -E 's#^https?://##; s#/.*##')
if ! grep -q "$host" build/web/main.dart.js; then
  echo "  REFUSING TO DEPLOY: the bundle does not mention $host." >&2
  echo "  The --dart-define did not reach the compiler. Run 'flutter clean' and retry." >&2
  exit 1
fi
if grep -q 'localhost:4000' build/web/main.dart.js; then
  echo "  REFUSING TO DEPLOY: the bundle still calls http://localhost:4000." >&2
  echo "  That is the dev default; the build did not pick up BACKEND_BASE_URL." >&2
  exit 1
fi
echo "  bundle points at $host, no localhost fallback"

# The stamp has to come from the compiled output, not from git: an unchanged
# build must produce an unchanged stamp or every deploy would needlessly evict
# a 4MB object from the edge cache.
STAMP=$(shasum -a 256 build/web/main.dart.js | cut -c1-12)
say "2/5  stamping entry points with $STAMP"
python3 - "$STAMP" <<'PY'
import io, re, sys
stamp = sys.argv[1]

# main.dart.js is named in flutter_bootstrap.js, sometimes more than once.
p = 'build/web/flutter_bootstrap.js'
s = io.open(p, encoding='utf-8').read()
before = s.count('main.dart.js')
s = s.replace('main.dart.js', f'main.dart.js?v={stamp}')
assert before, 'flutter_bootstrap.js never mentions main.dart.js'
io.open(p, 'w', encoding='utf-8').write(s)
print(f'  main.dart.js referenced {before}x -> stamped')

# flutter_bootstrap.js is named in index.html, which is served no-store.
p = 'build/web/index.html'
s = io.open(p, encoding='utf-8').read()
pattern = r'(<script src="flutter_bootstrap\.js)(" async>)'
s, n = re.subn(pattern, rf'\1?v={stamp}\2', s)
assert n == 1, f'expected one bootstrap script tag, found {n}'
io.open(p, 'w', encoding='utf-8').write(s)
print('  flutter_bootstrap.js -> stamped')
PY

say "3/5  fixing origin cache headers"
# Long caching is correct for the hashed asset bundle and canvaskit, and wrong
# for the three entry points, whose names never change.
"${SSH[@]}" "$HOST" 'python3 - <<"PY"
import io
p = "/home/brathna/reanai/bin/serve_web.py"
s = io.open(p, encoding="utf-8").read()
old = """        if path in ("/", "/index.html") or path.endswith(".json"):"""
new = """        unhashed = (
            "/",
            "/index.html",
            "/flutter_bootstrap.js",
            "/flutter.js",
            "/main.dart.js",
        )
        if path in unhashed or path.endswith(".json"):"""
if new in s:
    print("  already applied")
elif old in s:
    io.open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
    print("  entry points are now no-store")
else:
    raise SystemExit("  !! serve_web.py does not look as expected; not edited")
PY'

say "4/5  uploading"
"${SSH[@]}" "$HOST" 'rm -rf ~/reanai/web.prev && cp -a ~/reanai/web ~/reanai/web.prev'
rsync -az --delete -e "ssh -i $KEY -o BatchMode=yes" build/web/ "$HOST:~/reanai/web/"
"${SSH[@]}" "$HOST" 'systemctl --user restart reanai-web && sleep 3 && echo "  web: $(systemctl --user is-active reanai-web)"'

say "5/5  verifying the edge serves this build"
local_size=$(wc -c < build/web/main.dart.js | tr -d ' ')
live_size=$(curl -s -o /dev/null -w '%{size_download}' --max-time 90 "$SITE/main.dart.js?v=$STAMP")
printf '  built %s bytes\n  live  %s bytes\n' "$local_size" "$live_size"
if [ "$local_size" = "$live_size" ]; then
  echo "  OK - the live site is serving this build"
else
  echo "  MISMATCH - the edge is still serving something else" >&2
  exit 1
fi

cat <<DONE

Rollback:
  ssh -i $KEY $HOST 'rm -rf ~/reanai/web && mv ~/reanai/web.prev ~/reanai/web && systemctl --user restart reanai-web'
DONE
