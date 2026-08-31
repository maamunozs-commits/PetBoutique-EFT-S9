#!/usr/bin/env bash
# Instalado por bootstrap-vm.sh; ejecutar solo en la VM autorizada.
set -euo pipefail
[[ ${EUID} -eq 0 ]] || { echo 'Se requiere root' >&2; exit 1; }
release_id=${1:?Falta BuildId}
[[ $release_id =~ ^[0-9]+$ ]] || exit 1
incoming="/home/azureuser/isy2201-incoming/$release_id"
release="/opt/isy2201/releases/$release_id"
[[ -d $incoming && ! -L $incoming ]] || exit 1
[[ ! -e $release ]] || { echo 'La versión ya existe; no se sobrescribe.' >&2; exit 1; }
cd "$incoming"
sha256sum --check app.tar.gz.sha256
if tar -tzf app.tar.gz | grep -E '(^/|(^|/)\.\.(/|$))'; then exit 1; fi
old=$(readlink -f /opt/isy2201/current || true)
activated=false
rollback() {
  rc=$?
  if [[ $rc -ne 0 && $activated == true ]]; then
    if [[ -n $old && -d $old ]]; then
      ln -sfn "$old" /opt/isy2201/current
      systemctl restart isy2201
      echo "Reversión a $old; comprobar salud del servicio." >&2
    else
      systemctl stop isy2201 || true
      echo 'Primer despliegue fallido: servicio detenido.' >&2
    fi
  fi
  exit "$rc"
}
trap rollback EXIT
install -d -m 0755 "$release"
tar --no-same-owner --no-same-permissions -xzf app.tar.gz -C "$release"
[[ -x "$release/pipelines-dotnet-core" ]] || exit 1
chown -R root:isy2201 "$release"
chmod -R g+rX,o-rwx "$release"
ln -sfn "$release" /opt/isy2201/current
activated=true
systemctl restart isy2201
for attempt in {1..20}; do
  if curl --fail --silent --max-time 3 http://127.0.0.1:5000/health | grep -qx Healthy; then
    echo "Despliegue verificado: $release_id"
    cat "$release/COMMIT.txt"
    exit 0
  fi
  sleep 1
done
echo 'Falló health check; se activa reversión.' >&2
exit 1
