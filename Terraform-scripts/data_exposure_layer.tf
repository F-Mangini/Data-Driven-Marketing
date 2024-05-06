# TERRAFORM SCRIPT FOR EXPOSURE LAYER

# Define locals
locals {
  exposure_project_api = [
    "iam.googleapis.com",
    "stackdriver.googleapis.com",
    "cloudsql.googleapis.com",
    "storage.googleapis.com",
  ]
}

# Activate necessary Google Cloud services for the Exposure Layer project
resource "google_project_service" "exposure_project_api" {
  for_each = toset(local.exposure_project_api)
  project  = google_project.exposure_project.project_id
  service  = each.key
}

# Define project
resource "google_project" "exposure_project" {
  name            = "Exposure Layer"
  project_id      = "exposure-layer"
  org_id          = var.organization.id
  billing_account = var.billing_account_id
}

# Cloud SQL instance where the model results are stored.
resource "google_sql_database" "exposure_cloudsql" {
  name     = "exposure-cloudsql"
  instance = google_sql_database_instance.exposure_cloudsql_instance.name
}

# Cloud SQL instance settings
resource "google_sql_database_instance" "exposure_cloudsql_instance" {
  name             = "exposure-cloudsql-instance"
  region           = var.location.region
  database_version = "POSTGRES_15"
  settings {
    tier = "db-f1-micro"

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }

  deletion_protection = "true"
}

# Cloud SQL user for consumption service account
resource "google_sql_user" "exposure_cloudsql_iam_user_0" {
  # Note: When using Postgres on GCP, it's necessary to exclude the ".gserviceaccount.com"
  # suffix from the service account email. This is because of length restrictions on database usernames.
  name     = trimsuffix(google_service_account.consumption_service_account.email, ".gserviceaccount.com")  # provide access to consumption layer (GKE)
  instance = google_sql_database_instance.exposure_cloudsql_instance.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

# Cloud SQL user for Power BI service account
resource "google_sql_user" "exposure_cloudsql_iam_user_1" {
  # Note: When using Postgres on GCP, it's necessary to exclude the ".gserviceaccount.com"
  # suffix from the service account email. This is because of length restrictions on database usernames.
  name     = trimsuffix(google_service_account.exposure_service_account_pbi.email, ".gserviceaccount.com")  # provide access to power bi
  instance = google_sql_database_instance.exposure_cloudsql_instance.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

# Service account for Power BI
resource "google_service_account" "exposure_service_account_pbi" {
  account_id = "exposure-service-account-pbi"
  project    = google_project.exposure_project.project_id
}
