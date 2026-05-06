locals {
  folder_id_trim = trimspace(var.folder_id == null ? "" : var.folder_id)
  org_id_trim    = trimspace(var.org_id == null ? "" : var.org_id)
}

check "parent_required_for_google_project" {
  assert {
    condition = (
      length(local.folder_id_trim) > 0 ||
      length(local.org_id_trim) > 0
    )
    error_message = "Define folder_id o org_id (al menos uno no vacío) para crear el proyecto GCP."
  }
}

resource "random_id" "project_suffix" {
  keepers = {
    environment = var.environment_name
  }
  byte_length = 2
}

locals {
  project_id = "dp-proj-00-02-${var.environment_name}-${random_id.project_suffix.hex}"
}

resource "google_project" "env" {
  name            = "dp-proj-00-02-${var.environment_name}"
  project_id      = local.project_id
  billing_account = var.billing_account_id
  folder_id       = length(local.folder_id_trim) > 0 ? local.folder_id_trim : null
  org_id          = length(local.folder_id_trim) > 0 ? null : local.org_id_trim
}

resource "time_sleep" "wait_project_init" {
  depends_on      = [google_project.env]
  create_duration = "20s"
}

locals {
  env_apis = [
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "firebase.googleapis.com",
    "firestore.googleapis.com",
    "storage.googleapis.com",
    "identitytoolkit.googleapis.com",
    "securetoken.googleapis.com",
    "firebasehosting.googleapis.com",
  ]
}

resource "google_project_service" "env" {
  for_each = toset(local.env_apis)

  project    = google_project.env.project_id
  service    = each.value
  depends_on = [time_sleep.wait_project_init]

  disable_on_destroy = false
}

resource "google_service_account" "runtime" {
  project      = google_project.env.project_id
  account_id   = var.runtime_service_account_id
  display_name = "Backend runtime (Cloud Run)"
  depends_on   = [google_project_service.env]
}

resource "google_service_account" "github_deploy_backend" {
  project      = google_project.env.project_id
  account_id   = var.github_deploy_backend_id
  display_name = "GitHub Actions — deploy Cloud Run backend"
  depends_on   = [google_project_service.env]
}

resource "google_service_account" "github_deploy_web" {
  project      = google_project.env.project_id
  account_id   = var.github_deploy_web_id
  display_name = "GitHub Actions — deploy Firebase (web + reglas)"
  depends_on   = [google_project_service.env]
}

resource "google_service_account" "github_deploy_admin" {
  project      = google_project.env.project_id
  account_id   = var.github_deploy_admin_id
  display_name = "GitHub Actions — deploy Firebase Hosting (admin)"
  depends_on   = [google_project_service.env]
}

resource "google_project_iam_member" "runtime_firestore" {
  project = google_project.env.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_project_iam_member" "runtime_storage" {
  project = google_project.env.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_project_iam_member" "runtime_firebaseauth" {
  project = google_project.env.project_id
  role    = "roles/firebaseauth.admin"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

locals {
  github_deploy_backend_roles = toset([
    "roles/run.admin",
    "roles/cloudbuild.builds.editor",
    "roles/storage.admin",
    "roles/artifactregistry.writer",
    "roles/serviceusage.serviceUsageConsumer",
  ])
}

resource "google_project_iam_member" "github_deploy_backend_roles" {
  for_each = local.github_deploy_backend_roles

  project = google_project.env.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_deploy_backend.email}"
}

resource "google_service_account_iam_member" "github_deploy_backend_act_as_runtime" {
  service_account_id = google_service_account.runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_deploy_backend.email}"
}

# `gcloud run deploy --source` usa Cloud Build. En GCP, muy a menudo el build se ejecuta con la
# Compute default SA (`${project_number}-compute@developer.gserviceaccount.com`). En proyectos nuevos,
# la SA `${project_number}@cloudbuild.gserviceaccount.com` puede no existir inmediatamente; por eso
# evitamos hardcodearla en Terraform y otorgamos permisos al compute default.
locals {
  compute_default_service_account = "${google_project.env.number}-compute@developer.gserviceaccount.com"
}

resource "google_service_account_iam_member" "compute_default_act_as_runtime" {
  service_account_id = google_service_account.runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.compute_default_service_account}"
}

resource "google_service_account_iam_member" "github_deploy_backend_act_as_compute_default_sa" {
  service_account_id = "projects/${google_project.env.project_id}/serviceAccounts/${local.compute_default_service_account}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_deploy_backend.email}"
}

locals {
  github_deploy_web_roles = toset([
    "roles/firebase.admin",
    "roles/serviceusage.serviceUsageConsumer",
  ])
}

resource "google_project_iam_member" "github_deploy_web_roles" {
  for_each = local.github_deploy_web_roles

  project = google_project.env.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_deploy_web.email}"
}

locals {
  github_deploy_admin_roles = toset([
    "roles/firebase.admin",
    "roles/serviceusage.serviceUsageConsumer",
  ])
}

resource "google_project_iam_member" "github_deploy_admin_roles" {
  for_each = local.github_deploy_admin_roles

  project = google_project.env.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_deploy_admin.email}"
}

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = google_project.env.project_id

  depends_on = [google_project_service.env]
}

resource "google_firestore_database" "default" {
  provider    = google-beta
  project     = google_project.env.project_id
  name        = "(default)"
  location_id = var.firestore_location_id
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_firebase_project.default]
}

resource "google_firebase_hosting_site" "admin" {
  provider = google-beta
  project  = google_project.env.project_id
  site_id  = "${local.project_id}-adm"

  depends_on = [google_firebase_project.default]
}

resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  project       = google_project.env.project_id
  repository_id = var.artifact_repository_id
  description   = "Imágenes Docker del backend"
  format        = "DOCKER"

  depends_on = [google_project_service.env]
}

# Cloud Run `gcloud run deploy --source` usa un repo AR administrado (por defecto `cloud-run-source-deploy`)
# y lo intenta crear si no existe. Pre-crearlo evita requerir `artifactregistry.repositories.create` en CI.
resource "google_artifact_registry_repository" "cloud_run_source_deploy" {
  location      = var.region
  project       = google_project.env.project_id
  repository_id = "cloud-run-source-deploy"
  description   = "Repo usado por Cloud Run para despliegues desde código fuente"
  format        = "DOCKER"

  depends_on = [google_project_service.env]
}
