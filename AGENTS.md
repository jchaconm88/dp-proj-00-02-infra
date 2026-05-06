# dp-proj-00-02-infra

Fuente de verdad para **Terraform** de los proyectos GCP por ambiente (dev / qa / prd): proyecto unificado, Firebase (Firestore, Auth, Hosting web + admin), Artifact Registry, Cloud Run (IAM y SAs de runtime/deploy), sin Cloud Functions.

- Convenciones del monorepo: raíz del repo [`.cursor/rules/00-monorepo-agent-router.mdc`](../.cursor/rules/00-monorepo-agent-router.mdc).
- Bootstrap y estado remoto: [README.md](README.md).

Los repos **web**, **admin** y **backend** solo despliegan aplicación; consumen variables de **GitHub Environments** alineadas con los outputs de este Terraform (o sync documentado en `scripts/`).
