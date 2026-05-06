variable "billing_account_id" {
  type        = string
  description = "Facturación del proyecto (XXXXXX-XXXXXX-XXXXXX)."
}

variable "folder_id" {
  type        = string
  default     = null
  description = "Carpeta GCP (solo dígitos). Alternativa a org_id."
}

variable "org_id" {
  type        = string
  default     = null
  description = "Organización GCP (solo dígitos). Ignorado si folder_id tiene valor."
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "firestore_location_id" {
  type    = string
  default = "us-central1"
}
