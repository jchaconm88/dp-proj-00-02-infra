#!/usr/bin/env bash
# =============================================================================
# Tras `terraform apply`, propaga outputs a un GitHub Environment (dev|qa|prd).
#
# Requisitos: gh CLI autenticado, repo correcto (GH_REPO=owner/name), permisos para
# escribir variables del entorno.
#
# Uso (desde el directorio del stack, p. ej. terraform/environments/dev):
#   export GH_REPO="mi-org/dp-proj-00-02-web"
#   export TARGET_ENV="dev"
#   bash ../../scripts/sync-github-env.sh
#
# Variables de repo (no secretos) que se escriben si existen en terraform output:
#   GCP_PROJECT_ID, CLOUD_RUN_RUNTIME_SERVICE_ACCOUNT, CLOUD_RUN_SERVICE_NAME,
#   FIREBASE_HOSTING_SITE_ID_ADMIN, ARTIFACT_REGISTRY_URL
# =============================================================================
set -euo pipefail

STACK_DIR="$(pwd)"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: instala GitHub CLI (gh) y autentícate con gh auth login."
  exit 1
fi

if [[ -z "${GH_REPO:-}" ]]; then
  echo "ERROR: exporta GH_REPO=owner/repo (repo donde escribir variables, p. ej. web o backend)."
  exit 1
fi

if [[ -z "${TARGET_ENV:-}" ]]; then
  echo "ERROR: exporta TARGET_ENV=dev|qa|prd (nombre del GitHub Environment)."
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform no está en PATH."
  exit 1
fi

cd "${STACK_DIR}"
JSON="$(terraform output -json)"

project_id="$(echo "${JSON}" | jq -r '.project_id.value // empty')"
runtime_sa="$(echo "${JSON}" | jq -r '.runtime_service_account_email.value // empty')"
admin_site="$(echo "${JSON}" | jq -r '.firebase_hosting_site_id_admin.value // empty')"
ar_url="$(echo "${JSON}" | jq -r '.artifact_registry_url.value // empty')"
cr_hint="$(echo "${JSON}" | jq -r '.cloud_run_service_hint.value // empty')"

if [[ -z "${project_id}" ]]; then
  echo "ERROR: terraform output no contiene project_id. ¿Ejecutaste apply en ${STACK_DIR}?"
  exit 1
fi

echo "==> Escribiendo variables en ${GH_REPO} environment=${TARGET_ENV}"

gh variable set GCP_PROJECT_ID --repo "${GH_REPO}" --env "${TARGET_ENV}" --body "${project_id}"

if [[ -n "${runtime_sa}" ]]; then
  gh variable set CLOUD_RUN_RUNTIME_SERVICE_ACCOUNT --repo "${GH_REPO}" --env "${TARGET_ENV}" --body "${runtime_sa}"
fi

if [[ -n "${cr_hint}" ]]; then
  gh variable set CLOUD_RUN_SERVICE_NAME --repo "${GH_REPO}" --env "${TARGET_ENV}" --body "${cr_hint}"
fi

if [[ -n "${admin_site}" ]]; then
  gh variable set FIREBASE_HOSTING_SITE_ID_ADMIN --repo "${GH_REPO}" --env "${TARGET_ENV}" --body "${admin_site}"
fi

if [[ -n "${ar_url}" ]]; then
  gh variable set ARTIFACT_REGISTRY_URL --repo "${GH_REPO}" --env "${TARGET_ENV}" --body "${ar_url}"
fi

echo "Listo. Los secretos (JSON de SAs, VITE_*) deben cargarse a mano o con gh secret set."
