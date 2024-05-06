# TERRAFORM SCRIPT FOR MANIPULATION LAYER

# Define locals
locals {
  manipulation_project_api = [
    "iam.googleapis.com",
    "stackdriver.googleapis.com",
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "storage.googleapis.com",
  ]
}

# Activate necessary Google Cloud services for the Manipulation Layer project
resource "google_project_service" "manipulation_project_api" {
  for_each = toset(local.manipulation_project_api)
  project  = google_project.manipulation_project.project_id
  service  = each.key
}

# Define project
resource "google_project" "manipulation_project" {
  name            = "Manipulation Layer"
  project_id      = "manipulation-layer"
  org_id          = var.organization.id
  billing_account = var.billing_account_id
}

# Create a Dataflow job
resource "google_dataflow_flex_template_job" "manipulation_dataflow" {
  provider = google-beta
  name     = "manipulation-dataflow"
  region   = var.location.region
  project  = google_project.manipulation_project.project_id
  container_spec_gcs_path = "${google_storage_bucket.manipulation_bucket.url}/templates/template.json"
  parameters = {
    inputBucket    = google_storage_bucket.landing_bucket.url
    serviceAccount = google_service_account.manipulation_service_account.email
  }
}

# Create a service account
resource "google_service_account" "manipulation_service_account" {
  account_id = "manipulation-service-account"
  project    = google_project.manipulation_project.project_id
}

# Create a GCS bucket to store Dataflow templates
resource "google_storage_bucket" "manipulation_bucket" {
  name     = "manipulation-bucket"
  project  = google_project.manipulation_project.project_id
  location = "EU"
}

# Provide the service account with read access to storage
resource "google_storage_bucket_iam_binding" "manipulation_bucket_iam_binding_0" {
  bucket = google_storage_bucket.manipulation_bucket.name
  role   = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${google_service_account.manipulation_service_account.email}",
  ]
}

