# dp-proj-00-02-infra

Infraestructura como código para **un proyecto GCP por ambiente** (`dev`, `qa`, `prd`) con patrón `dp-proj-00-02-{env}-{suffix}` (suffix de 4 hex fijado por Terraform).

Incluye: APIs, **Artifact Registry**, **Firebase** (Firestore nativo, Hosting sitio web + sitio admin), **SAs** (runtime Cloud Run, deploy backend, deploy web, deploy admin) e **IAM** mínimo. **No** se despliegan Cloud Functions; esa lógica vive en el backend (Cloud Run).

## Requisitos previos

1. **Proyecto seed** (único paso manual fuera de Terraform de ambientes): bucket GCS de estado + SA `terraform-bootstrap` con permisos para crear proyectos bajo vuestra **org** o **carpeta** y gestionar IAM. Ver [terraform/scripts/bootstrap-seed.sh](terraform/scripts/bootstrap-seed.sh).
2. Variables Terraform por stack: `billing_account_id` y `folder_id` **o** `org_id` (uno de los dos para `google_project`).

### Permisos mínimos adicionales (fuera del seed)

Además del seed, la SA `terraform-bootstrap@<PROJECT_SEED>.iam.gserviceaccount.com` necesita permisos a nivel **Billing Account** y **Org/Folder** para poder crear proyectos nuevos y vincularles facturación.

Ejecutar (con una identidad que sea admin de Billing/Org):

```bash
# 1) Billing Account: permitir asociar (link) la facturación a proyectos nuevos
gcloud billing accounts add-iam-policy-binding BILLING_ACCOUNT_ID \
  --member="serviceAccount:terraform-bootstrap@dp-proj-00-02-seed.iam.gserviceaccount.com" \
  --role="roles/billing.user"

# 2) Organización: permitir crear proyectos (si usas TF_GCP_ORG_ID / org_id)
gcloud organizations add-iam-policy-binding ORG_ID_NUMERICO \
  --member="serviceAccount:terraform-bootstrap@dp-proj-00-02-seed.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.projectCreator"
```

Si en lugar de organización creas bajo una **carpeta**, aplica el rol de creación a nivel folder:

```bash
gcloud resource-manager folders add-iam-policy-binding FOLDER_ID_NUMERICO \
  --member="serviceAccount:terraform-bootstrap@dp-proj-00-02-seed.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.projectCreator"
```

## Primer uso

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars   # editar valores

terraform init \
  -backend-config="bucket=TU_BUCKET_SEED" \
  -backend-config="prefix=terraform/env/dev"

export GOOGLE_APPLICATION_CREDENTIALS=/ruta/terraform-bootstrap-key.json
terraform plan
terraform apply
```

Repetir con `qa` y `prd` (prefijos de estado distintos).

## Outputs y CI

Tras `apply`, usar `terraform output -json` o el script [terraform/scripts/sync-github-env.sh](terraform/scripts/sync-github-env.sh) (desde `terraform/environments/<stack>`: `bash ../../scripts/sync-github-env.sh`) para propagar `project_id`, SAs, `firebase_hosting_site_id_admin`, etc. a **GitHub Environments** (`gh` CLI autenticado).

- Formato: [.github/workflows/terraform-fmt.yml](.github/workflows/terraform-fmt.yml) (fmt en PR) y [.github/workflows/terraform.yml](.github/workflows/terraform.yml) (plan/apply manual; secret `TF_STACK_TFVARS` = contenido de `terraform.tfvars` del stack).

## Relación con otros repos

- **Backend**: el workflow de deploy ya **no** ejecuta Terraform; solo build + Cloud Run usando variables del Environment.
- **Web / Admin**: `firebase deploy --project "$GCP_PROJECT_ID"` y secrets del Environment (sin IDs fijos en YAML).
