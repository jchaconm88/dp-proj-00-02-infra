module "env" {
  source = "../../modules/env_project"

  environment_name      = "qa"
  billing_account_id    = var.billing_account_id
  folder_id             = var.folder_id
  org_id                = var.org_id
  region                = var.region
  firestore_location_id = var.firestore_location_id
}

output "project_id" {
  value = module.env.project_id
}

output "runtime_service_account_email" {
  value = module.env.runtime_service_account_email
}

output "github_deploy_backend_email" {
  value = module.env.github_deploy_backend_email
}

output "github_deploy_web_email" {
  value = module.env.github_deploy_web_email
}

output "github_deploy_admin_email" {
  value = module.env.github_deploy_admin_email
}

output "artifact_registry_url" {
  value = module.env.artifact_registry_url
}

output "firebase_hosting_site_id_admin" {
  value = module.env.firebase_hosting_site_id_admin
}

output "firebase_default_hosting_site_id" {
  value = module.env.firebase_default_hosting_site_id
}

output "cloud_run_service_hint" {
  value = module.env.cloud_run_service_hint
}
