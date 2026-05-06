# Migración de datos (Firestore / Auth) — referencia

En un **despliegue greenfield**, los proyectos `dp-proj-00-02-{dev|qa|prd}-{suffix}` creados por Terraform empiezan **vacíos**: no hay migración automática desde `layout-admin`, `dp-proj-00-02-admin-q` u otros IDs legacy.

Si en el futuro necesitáis **importar** datos o usuarios desde proyectos antiguos:

1. Exportad Firestore (Datastore export o scripts por colección) desde el proyecto origen.
2. Importad o rehidratad en el **nuevo** `project_id` del ambiente, respetando reglas e índices desplegados desde el pipeline **web**.
3. Para **Auth**, usad las herramientas de export/import de Identity Platform o flujos manuales; validad custom claims y UIDs referenciados en Firestore.

Este documento no sustituye un plan de cutover; solo delimita que **Terraform en `dp-proj-00-02-infra` no migra datos**.
