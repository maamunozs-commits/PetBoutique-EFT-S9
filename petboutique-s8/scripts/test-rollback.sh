#!/usr/bin/env bash
# Controlled test on loopback staging. It does not stop production.
set -Eeuo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
GOOD=${1:?version validada, por ejemplo s8-5}
[[ "$GOOD" =~ ^s8-[0-9]+$ ]] || exit 2
cd "$ROOT"
BAD=s8-rollback-test
cleanup() {
  sudo docker compose -p petboutique-s8-staging --env-file state/staging.env -f compose.yaml down
}
trap cleanup EXIT
bash scripts/deploy.sh staging "$GOOD"
mkdir -p rollback-fixture
cat > rollback-fixture/default.conf <<'EOF'
server {
 listen 8080;
 location / { return 503 'Candidato defectuoso para prueba de recuperacion'; }
 location = /health-web { return 200 'Healthy'; }
}
EOF
printf 'FROM petboutique/web:%s\nCOPY default.conf /etc/nginx/conf.d/default.conf\n' "$GOOD" > rollback-fixture/Dockerfile
sudo docker build -t "petboutique/web:$BAD" rollback-fixture
sudo docker tag "petboutique/api:$GOOD" "petboutique/api:$BAD"
set +e
bash scripts/deploy.sh staging "$BAD"
failure=$?
set -e
test "$failure" -ne 0
python3 verify.py http://127.0.0.1:8081 > evidence/rollback-final-tests.json
python3 - <<'PY'
import json
from pathlib import Path
p=Path('evidence/staging-s8-rollback-test/rollback-tests.json')
data=json.loads(p.read_text())
assert data['passed']==10 and data['total']==10
print('Recuperacion verificada: candidato fallo y la version anterior aprobo 10/10.')
PY
python3 verify.py http://127.0.0.1 > evidence/production-after-rollback-test.json
date -u '+%Y-%m-%dT%H:%M:%SZ'
