# TERRAFORM SCRIPT FOR LAKEHOUSE LAYER

# Define locals
locals {
  lakehouse_project_api = [
    "iam.googleapis.com",
    "stackdriver.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
  ]
}

# Activate necessary Google Cloud services for the Lakehouse Layer project
resource "google_project_service" "lakehouse_project_api" {
  for_each = toset(local.lakehouse_project_api)
  project  = google_project.lakehouse_project.project_id
  service  = each.key
}

# Define project
resource "google_project" "lakehouse_project" {
  name            = "Lakehouse Layer"
  project_id      = "lakehouse-layer"
  org_id          = var.organization.id
  billing_account = var.billing_account_id
}

# L0 - Raw Storage: Google Cloud Storage
resource "google_storage_bucket" "lakehouse_l0_bucket" {
  name     = "lakehouse-l0-bucket"
  location = var.location.multi_region
  project  = google_project.lakehouse_project.project_id
  uniform_bucket_level_access = true
}

# L1 - Curated: Google BigQuery
resource "google_bigquery_dataset" "lakehouse_l1_curated_dataset" {
  dataset_id = "lakehouse_l1_curated_dataset"
  location   = var.location.multi_region
  project    = google_project.lakehouse_project.project_id

  # Grant OWNER access to the manipulation service account
  access {
    role          = "OWNER"
    user_by_email = google_service_account.manipulation_service_account.email
  }
}

# L2 - Ready:  Google BigQuery
resource "google_bigquery_dataset" "lakehouse_l2_ready_dataset" {
  dataset_id = "lakehouse_l2_ready_dataset"
  location   = var.location.multi_region
  project    = google_project.lakehouse_project.project_id

  # Provide OWNER access to the manipulation service account
  access {
    role          = "OWNER"
    user_by_email = google_service_account.manipulation_service_account.email
  }

  # Provide READER access to the consumption service account
  access {
    role          = "READER"
    user_by_email = google_service_account.consumption_service_account.email
  }

  # Provide READER access to the Power BI service account
  access {
    role = "READER"
    user_by_email = google_service_account.exposure_service_account_pbi.email
  }
}

# Provide necessary permissions for L0 - Raw Storage bucket
resource "google_storage_bucket_iam_binding" "lake_bucket_iam_binding_0" {
  bucket = google_storage_bucket.lakehouse_l0_bucket.name
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${google_service_account.manipulation_service_account.email}",
  ]
}
