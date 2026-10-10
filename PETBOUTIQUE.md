# PetBoutique Antecedente de planificación de la experiencia 1

Este archivo conserva los criterios y la propuesta de trabajo de la experiencia 1. La implementación y la validación de cierre de las tres experiencias se documentan en README.md y en el informe final de la carpeta entrega; los resultados se acreditan mediante corridas y registros fechados.

El alcance implementado es catálogo y cotización de demostración. No hay pago, registro de clientes ni persistencia de pedidos. Los precios y productos son ficticios. No usar como tienda de producción.

## Criterios de aceptación

- La página principal identifica PetBoutique y advierte que es una simulación.
- El catálogo expone tres productos con identificadores únicos y precios positivos en CLP.
- Dos unidades del producto 1 totalizan 25980 CLP.
- Se rechazan cantidades fuera de 1–10, valores no numéricos y productos inexistentes.
- El endpoint de salud responde 200 y una ruta inexistente devuelve 404.
- CI compila, ejecuta nueve pruebas HTTP y publica el mismo paquete con commit y checksum.
- CD se habilita después de disponer de VM, conexión SSH restringida y agente confiable.

## Propuesta de trabajo para Azure Boards

1. PB-01: catálogo y cotización de demostración; aceptación funcional anterior.
2. PB-02: repositorio y CI; nueve pruebas y artefacto trazable.
3. PB-03: red y VM; SSH limitado, aplicación en loopback, túnel y pruebas de rechazo.
4. PB-04: despliegue y recuperación; versión identificable y reversión verificada.
5. PB-05: informe y presentación; capturas auténticas, permisos docentes y grabación.

Son tareas propuestas; el archivo por sí solo no acredita su creación en Azure Boards. No se asignan a compañeros ni se inventan tiempos anteriores. La medición inicial debe registrar duración de ejecución, pruebas aprobadas y artefactos producidos. Frecuencia de despliegue, tasa de fallos y tiempo de recuperación requieren más observaciones reales.
