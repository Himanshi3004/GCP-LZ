resource "google_bigquery_reservation" "warehouse" {
  count           = var.enable_slot_reservations ? 1 : 0
  name            = "warehouse-reservation"
  project         = var.project_id
  location        = var.region
  slot_capacity   = var.slot_capacity
  ignore_idle_slots = false
}

resource "google_bigquery_capacity_commitment" "warehouse" {
  count                = var.enable_slot_reservations ? 1 : 0
  capacity_commitment_id = "warehouse-commitment"
  project              = var.project_id
  location             = var.region
  slot_count           = var.slot_capacity
  plan                 = "MONTHLY"
  renewal_plan         = "MONTHLY"
}

resource "google_bigquery_reservation_assignment" "warehouse" {
  count       = var.enable_slot_reservations ? 1 : 0
  project     = var.project_id
  location    = var.region
  reservation = google_bigquery_reservation.warehouse[0].name
  job_type    = "QUERY"
  assignee    = "projects/${var.project_id}"
}