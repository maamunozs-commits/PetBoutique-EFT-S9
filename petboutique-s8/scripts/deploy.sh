#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
ENVIRONMENT=${1:?staging o production}; VERSION=${2:?version}
[[ "$ENVIRONMENT" =~ ^(staging|production)$ && "$VERSION" =~ ^[a-zA-Z0-9._-]+$ ]] || exit 2
mkdir -p "$ROOT/state" "$ROOT/evidence"
exec 9>"$ROOT/state/deploy.lock"; flock -w 120 9
if [[ "$ENVIRONMENT" == staging ]]; then PROJECT=petboutique-s8-staging; PORT=8081; else PROJECT=petboutique-s6; PORT=8080; fi
STATE="$ROOT/state/$ENVIRONMENT.env"; OLD="$ROOT/state/$ENVIRONMENT.previous.env"
REPORT="$ROOT/evidence/$ENVIRONMENT-$VERSION"; mkdir -p "$REPORT"
if [[ ! -f "$STATE" && "$ENVIRONMENT" == production ]]; then
  API_OLD=$(sudo docker inspect petboutique-s6-api-1 --format '{{.Config.Image}}')
  WEB_OLD=$(sudo docker inspect petboutique-s6-web-1 --format '{{.Config.Image}}')
  printf 'API_IMAGE=%s\nWEB_IMAGE=%s\nWEB_PORT=%s\n' "$API_OLD" "$WEB_OLD" "$PORT" > "$STATE"
fi
[[ ! -f "$STATE" ]] || cp "$STATE" "$OLD"
NEXT="$ROOT/state/$ENVIRONMENT.next.env"
printf 'API_IMAGE=petboutique/api:%s\nWEB_IMAGE=petboutique/web:%s\nWEB_PORT=%s\n' "$VERSION" "$VERSION" "$PORT" > "$NEXT"
compose() { sudo docker compose --project-name "$PROJECT" --env-file "$1" -f "$ROOT/compose.yaml" "${@:2}"; }
# Validate images and configuration before changing the running service.
sudo docker image inspect "petboutique/api:$VERSION" "petboutique/web:$VERSION" > "$REPORT/images.json"
compose "$NEXT" config --quiet
CHANGED=0
recover() {
  local failure=$?
  trap - ERR
  if [[ "$CHANGED" == 1 && -f "$OLD" ]]; then
    compose "$OLD" up -d --no-build --pull never --force-recreate > "$REPORT/rollback.log" 2>&1
    sleep 5
    python3 "$ROOT/verify.py" "http://127.0.0.1:$PORT" > "$REPORT/rollback-tests.json" 2>&1
    cp "$OLD" "$STATE"
  elif [[ "$CHANGED" == 1 ]]; then
    compose "$NEXT" down > "$REPORT/cleanup.log" 2>&1
  fi
  printf 'failed; rollback attempted; exit=%s\n' "$failure" >> "$REPORT/deploy.log"
  exit "$failure"
}
trap recover ERR
CHANGED=1
compose "$NEXT" up -d --no-build --pull never --force-recreate > "$REPORT/deploy.log" 2>&1
READY=0
for attempt in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:$PORT/health" > /dev/null; then READY=1; break; fi
  sleep 2
done
[[ "$READY" == 1 ]]
python3 "$ROOT/verify.py" "http://127.0.0.1:$PORT" > "$REPORT/tests.json"
compose "$NEXT" ps > "$REPORT/containers.txt"
compose "$NEXT" logs --no-color --tail=100 > "$REPORT/containers.log"
sudo docker stats --no-stream > "$REPORT/resources.txt"
cp "$NEXT" "$STATE"
date -u '+%Y-%m-%dT%H:%M:%SZ' >> "$REPORT/deploy.log"
echo "success environment=$ENVIRONMENT version=$VERSION" >> "$REPORT/deploy.log"
trap - ERR
