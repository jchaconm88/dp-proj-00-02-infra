#!/usr/bin/env bash
# =============================================================================
# Bootstrap del proyecto SEED (único paso manual antes de Terraform por ambiente).
# Crea: proyecto seed, bucket de estado GCS, SA terraform-bootstrap y permisos
# sobre el bucket. NO crea proyectos dev/qa/prd (los crea Terraform en dp-proj-00-02-infra).
#
# Tras este script, un administrador de la organización debe otorgar a la SA bootstrap
# permiso para CREAR proyectos bajo la carpeta u org donde aplicaréis Terraform, p. ej.:
#   gcloud resource-manager folders add-iam-policy-binding FOLDER_ID \
#     --member="serviceAccount:${BOOTSTRAP_SA_EMAIL}" \
#     --role="roles/resourcemanager.projectCreator"
#   gcloud organizations add-iam-policy-binding ORG_ID ...  (si creáis en raíz de org)
# y roles de facturación si aplica (p. ej. roles/billing.user sobre la cuenta de facturación).
#
# Requiere: gcloud, BILLING_ACCOUNT_ID exportado.
# =============================================================================
set -euo pipefail

export PROJECT_SEED="${PROJECT_SEED:-dp-proj-00-02-seed}"
export TF_STATE_BUCKET="${TF_STATE_BUCKET:-${PROJECT_SEED}-tfstate}"
export TF_STATE_REGION="${TF_STATE_REGION:-us-central1}"

export BOOTSTRAP_SA_ID="${BOOTSTRAP_SA_ID:-terraform-bootstrap}"
export BOOTSTRAP_SA_EMAIL="${BOOTSTRAP_SA_ID}@${PROJECT_SEED}.iam.gserviceaccount.com"

if [[ -z "${BILLING_ACCOUNT_ID:-}" ]]; then
  echo "ERROR: exporta BILLING_ACCOUNT_ID (gcloud billing accounts list)."
  exit 1
fi

echo "==> 1) Proyecto seed"
gcloud projects create "${PROJECT_SEED}" \
  --name="dp-proj-00-02 seed (Terraform estado)" \
  2>/dev/null || echo "    (proyecto ya existía)"

gcloud billing projects link "${PROJECT_SEED}" --billing-account="${BILLING_ACCOUNT_ID}" \
  2>/dev/null || echo "    (facturación ya vinculada o revisar manualmente)"

echo "==> 2) APIs en seed"
# iam.googleapis.com es necesario para crear la SA terraform-bootstrap (sin esto, create falla y el script podía seguir en falso).
gcloud services enable \
  storage.googleapis.com \
  serviceusage.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  cloudbilling.googleapis.com \
  firebase.googleapis.com \
  --project="${PROJECT_SEED}"

echo "==> 3) Bucket de estado Terraform"
gcloud storage buckets create "gs://${TF_STATE_BUCKET}" \
  --project="${PROJECT_SEED}" \
  --location="${TF_STATE_REGION}" \
  --uniform-bucket-level-access \
  2>/dev/null || echo "    (bucket ya existía)"

gcloud storage buckets update "gs://${TF_STATE_BUCKET}" \
  --versioning \
  --project="${PROJECT_SEED}"

echo "==> 4) SA terraform-bootstrap"
if gcloud iam service-accounts describe "${BOOTSTRAP_SA_EMAIL}" --project="${PROJECT_SEED}" &>/dev/null; then
  echo "    (SA ya existía: ${BOOTSTRAP_SA_EMAIL})"
else
  gcloud iam service-accounts create "${BOOTSTRAP_SA_ID}" \
    --project="${PROJECT_SEED}" \
    --display-name="Terraform bootstrap (infra + proyectos por ambiente)"
fi

gcloud storage buckets add-iam-policy-binding "gs://${TF_STATE_BUCKET}" \
  --project="${PROJECT_SEED}" \
  --member="serviceAccount:${BOOTSTRAP_SA_EMAIL}" \
  --role="roles/storage.objectAdmin"

KEY_OUT="${KEY_OUT:-./terraform-bootstrap-key.json}"
gcloud iam service-accounts keys create "${KEY_OUT}" \
  --iam-account="${BOOTSTRAP_SA_EMAIL}" \
  --project="${PROJECT_SEED}"

echo ""
echo "-------------------------------------------------------------------"
echo "Listo (seed + bucket + SA + clave)."
echo "  1) Sube ${KEY_OUT} al secret GitHub del repo infra: GCP_TERRAFORM_SA_KEY"
echo "  2) Variable TF_STATE_BUCKET = ${TF_STATE_BUCKET}"
echo "  3) En la carpeta u ORG donde Terraform creará dp-proj-00-02-{dev|qa|prd}-XXXX,"
echo "     concede a ${BOOTSTRAP_SA_EMAIL} roles/resourcemanager.projectCreator (y billing si hace falta)."
echo "  4) Tras el primer apply por ambiente, crea claves JSON de las SAs github-deploy-*"
echo "     o configura WIF; sincroniza outputs con terraform/scripts/sync-github-env.sh"
echo "  5) Borra la clave local: rm -f ${KEY_OUT}"
echo "-------------------------------------------------------------------"
