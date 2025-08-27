variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "enable_slot_reservations" {
  description = "Enable BigQuery slot reservations"
  type        = bool
  default     = true
}

variable "slot_capacity" {
  description = "Number of BigQuery slots to reserve"
  type        = number
  default     = 100
}

variable "enable_bi_engine" {
  description = "Enable BI Engine"
  type        = bool
  default     = true
}

variable "bi_engine_memory_size_gb" {
  description = "BI Engine memory size in GB"
  type        = number
  default     = 1
}

variable "enable_ml" {
  description = "Enable BigQuery ML features"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}