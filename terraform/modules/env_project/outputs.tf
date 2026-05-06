output "project_id" {
  description = "ID del proyecto GCP del ambiente."
  value       = google_project.env.project_id
}

output "project_number" {
  description = "Número del proyecto GCP."
  value       = google_project.env.number
}

output "random_suffix_hex" {
  description = "Sufijo aleatorio fijado por keepers (4 hex)."
  value       = random_id.project_suffix.hex
}

output "runtime_service_account_email" {
  value = google_service_account.runtime.email
}

output "github_deploy_backend_email" {
  value = google_service_account.github_deploy_backend.email
}

output "github_deploy_web_email" {
  value = google_service_account.github_deploy_web.email
}

output "github_deploy_admin_email" {
  value = google_service_account.github_deploy_admin.email
}

output "artifact_registry_url" {
  description = "Prefijo para tags de imagen Docker."
  value       = "${var.region}-docker.pkg.dev/${google_project.env.project_id}/${var.artifact_repository_id}"
}

output "firebase_hosting_site_id_admin" {
  description = "Site ID de Firebase Hosting para la SPA admin (segundo sitio)."
  value       = google_firebase_hosting_site.admin.site_id
}

output "firebase_default_hosting_site_id" {
  description = "El sitio por defecto de Hosting suele coincidir con project_id."
  value       = google_project.env.project_id
}

output "cloud_run_service_hint" {
  description = "Nombre lógico del servicio Cloud Run usado por los pipelines de backend."
  value       = "dp-proj-00-02-backend"
}
