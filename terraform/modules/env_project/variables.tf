variable "environment_name" {
  type        = string
  description = "Nombre corto del ambiente: dev, qa o prd."
  validation {
    condition     = contains(["dev", "qa", "prd"], var.environment_name)
    error_message = "environment_name debe ser dev, qa o prd."
  }
}

variable "billing_account_id" {
  type        = string
  description = "ID de cuenta de facturación (formato XXXXXX-XXXXXX-XXXXXX)."
  validation {
    condition     = length(trimspace(var.billing_account_id)) > 0
    error_message = "billing_account_id es obligatorio."
  }
}

variable "folder_id" {
  type        = string
  default     = null
  description = "ID numérico de carpeta GCP bajo la que crear el proyecto (sin prefijo folders/)."
}

variable "org_id" {
  type        = string
  default     = null
  description = "ID numérico de organización. Usar si no hay folder_id."
}

variable "region" {
  type        = string
  description = "Región para Artifact Registry y recursos regionales."
  default     = "us-central1"
}

variable "firestore_location_id" {
  type        = string
  description = "Ubicación de Firestore nativo (p. ej. us-central1 o nam5)."
  default     = "us-central1"
}

variable "artifact_repository_id" {
  type        = string
  description = "Id del repositorio Artifact Registry (formato DOCKER)."
  default     = "dp-repo"
}

variable "runtime_service_account_id" {
  type        = string
  description = "account_id de la SA que ejecutará Cloud Run."
  default     = "dp-backend-runtime"
}

variable "github_deploy_backend_id" {
  type        = string
  default     = "github-deploy-backend"
}

variable "github_deploy_web_id" {
  type        = string
  default     = "github-deploy-web"
}

variable "github_deploy_admin_id" {
  type        = string
  default     = "github-deploy-admin"
}
