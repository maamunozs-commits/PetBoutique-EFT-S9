# PetBoutique Informe de Evaluación Final Transversal

DevOps ISY2201 · Semana 9 · Grupo 6 · 10 de octubre de 2026.

Integrantes: Matías Andrés Muñoz Soto y Bastián Ortiz Gómez.

La entrega consolida las experiencias 1, 2 y 3: infraestructura de Azure, contenedores web y API, Docker Compose, integración continua, promoción a staging y producción académica, monitoreo y recuperación.

## Entrega

- `entrega/Informe_EFT_S9_Grupo6_Matias_Munoz_Bastian_Ortiz.docx`: informe sobre la plantilla institucional original.
- `petboutique-s8/`: aplicación, Dockerfiles, Compose, verificadores y scripts de operación.
- `azure-pipelines-s8.yml`: pipeline registrado y autorizado en Azure DevOps.
- `evidencias/s8/`: registros históricos de la experiencia 3.
- `evidencias/s9/`: comprobaciones y ejecución de cierre de la evaluación final.

## Recursos

- Azure DevOps: https://dev.azure.com/maamunozs/ISY2201-Pipeline
- Azure Repos, rama final: `maamunozs/petboutique-eft-s9`.
- Pipeline autorizado: `PetBoutique-Exp3-S8`, definición 4. Se reutiliza para validar la rama final y conservar los permisos del archivo seguro.
- VM: https://portal.azure.com/#@duoc.cl/resource/subscriptions/1fdaaaf8-fac4-468f-a9b0-541fd7376aa9/resourceGroups/rg-petboutique-lab/providers/Microsoft.Compute/virtualMachines/vm-petboutique-lab/overview
- Servicio: http://20.80.27.195/

## Repetir la validación

En Azure Pipelines, abrir `PetBoutique-Exp3-S8`, seleccionar **Run pipeline**, elegir la rama `maamunozs/petboutique-eft-s9` y mantener `runDeployment=true`. La ejecución construye dos imágenes, ejecuta diez comprobaciones, promueve el mismo paquete a staging y producción y publica tres artefactos. El disparador automático se conserva limitado a la rama S8; la validación S9 se inicia explícitamente para que los commits de documentación no redeplieguen el servicio.

No se necesitan nuevas máquinas virtuales ni recursos de pago para esta consolidación. Las credenciales permanecen fuera del repositorio; la clave SSH existente se consume desde Azure DevOps Secure files.

La grabación de Teams la realiza y añade el estudiante por separado.
