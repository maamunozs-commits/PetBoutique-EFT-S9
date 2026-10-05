# PetBoutique Experiencia 3 Semana 8

Este material continúa los contenedores y la VM de EXP1 y EXP2. Incluye un pipeline de Azure DevOps con CI, staging, producción académica y supervisión periódica. El informe Word documenta la corrida verificada y sus resultados. No incluye claves SSH, contraseñas ni tokens.

## Archivos

- `azure-pipelines-s8.yml`: definición principal. En el repositorio de Azure Repos existe una copia en la raíz, que es la registrada por Azure Pipelines.
- `pipeline-deploy.yml`: transferencia, integridad, promoción y recolección de evidencia.
- `api/` y `web/`: código y Dockerfiles recuperados desde EXP2. La interfaz identifica la experiencia 3.
- `compose.yaml`: entornos parametrizados por imágenes y puerto local.
- `verify.py`: diez comprobaciones HTTP, con salida JSON y estado de error cuando hay fallos.
- `scripts/deploy.sh`: promoción, bloqueo de concurrencia y recuperación.
- `scripts/monitor.py`, servicio y timer: supervisión periódica.
- `scripts/petboutique-logrotate`: rotación del registro del monitor.
- `scripts/test-rollback.sh`: ensayo controlado de recuperación en staging.
- `known_hosts`: identidad pública del servidor previamente conocida; no contiene la clave privada.

## Recursos existentes

Proyecto: https://dev.azure.com/maamunozs/ISY2201-Pipeline

Pipeline: PetBoutique-Exp3-S8. Rama: `maamunozs/petboutique-exp3-s8`.

VM: `vm-petboutique-lab`, Ubuntu 24.04, IP pública `20.80.27.195`, usuario `azureuser`. Apache reenvía el puerto HTTP al loopback 8080. La VM cuenta con Docker, Compose, Python 3, curl, flock, systemd y sudo. El proyecto de producción conserva el nombre `petboutique-s6` para actualizar los contenedores anteriores.

Entornos Azure DevOps: `petboutique-s8-staging` y `petboutique-s8-production`. Son destinos lógicos; los contenedores comparten una VM. No se registró un agente nuevo dentro de la VM: la instalación usa SSH desde el agente alojado de Azure Pipelines.

## Ejecutar de nuevo

1. Revisar el cambio en la rama académica y verificar que conserva los prerrequisitos de la VM.
2. La biblioteca Secure files debe tener `petboutique-lab-ed25519-s8`, con permiso exclusivo para este pipeline YAML. El archivo seguro se configuró con autorización del titular y no se entrega en este paquete.
3. Crear un commit en la rama indicada para activar CI/CD. También se puede usar Run pipeline y elegir esa rama. `runDeployment=true` ejecuta las tres etapas; `false` ejecuta únicamente CI.
4. Consultar CI, Staging y Production y descargar los artefactos de la corrida. Las tres etapas deben terminar en Success para declarar una promoción completa.
5. Verificar el servicio público y consultar el monitoreo en la VM.

La construcción se ejecuta en Ubuntu 24.04 alojado por Microsoft. Las mismas imágenes se empaquetan y se cargan en la VM; no se reconstruyen durante la promoción. `release.sha256` valida la integridad del paquete. Las etiquetas `s8-ID` relacionan las imágenes con la corrida, mientras `COMMIT.txt` relaciona el paquete con el código.

## Operación en la VM

Desde `/home/azureuser/petboutique-s8`:

```bash
sudo systemctl status petboutique-monitor.timer
sudo systemctl list-timers petboutique-monitor.timer
sudo journalctl -u petboutique-monitor.service --no-pager
sudo tail /var/log/petboutique-s8/health.jsonl
python3 verify.py http://127.0.0.1
sudo docker compose -p petboutique-s6 --env-file state/production.env -f compose.yaml ps
```

El monitor registra salud de web y API, catálogo, latencia y recolección de CPU, RAM y disco. Una falla devuelve estado 1 y produce una alerta local en el journal. No reinicia automáticamente los contenedores ni envía avisos externos. El timer vuelve a observar en su siguiente activación.

## Recuperación

Cada promoción conserva `state/ENTORNO.previous.env`. El script intenta restaurar las referencias previas si falla después de comenzar la actualización. La recuperación necesita que esas imágenes sigan almacenadas en la VM. Revisar siempre `rollback.log` y `rollback-tests.json` para confirmar el resultado.

Para practicar sin detener producción:

```bash
bash scripts/test-rollback.sh s8-ID > evidence/rollback-test.txt 2>&1
```

Sustituir ID por la corrida validada. El script crea una web defectuosa en staging, comprueba el fracaso del candidato, verifica diez casos tras recuperar la versión previa y detiene el entorno temporal. El candidato de ensayo conserva una etiqueta distinta de la versión validada.

## Alcance y cierre

Producción es el entorno académico publicado por HTTP. Antes de un uso comercial se requieren HTTPS, identidad de despliegue de privilegios mínimos, análisis de vulnerabilidades, pruebas de carga y disponibilidad acordes al servicio. El registro ACR de EXP2 se conserva como antecedente; S8 transporta imágenes mediante Pipeline Artifacts y no publica una nueva versión en ACR.

El video de Teams y su enlace se agregan después de realizar la presentación. Cada integrante responde personalmente su quiz. El guion de video se preparará por solicitud posterior del estudiante.
