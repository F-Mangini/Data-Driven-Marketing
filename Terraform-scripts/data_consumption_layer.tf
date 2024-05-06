# TERRAFORM SCRIPT FOR CONSUMPTION LAYER

# Define locals
locals {
  consumption_project_api = [
    "iam.googleapis.com",
    "stackdriver.googleapis.com",
    "containers.googleapis.com",
    "compute.googleapis.com",
  ]
}

# Activate necessary Google Cloud services for the Consumption Layer project
resource "google_project_service" "consumption_project_api" {
  for_each = toset(local.consumption_project_api)
  project  = google_project.consumption_project.project_id
  service  = each.key
}

# Define project
resource "google_project" "consumption_project" {
  name            = "Consumption Layer"
  project_id      = "consumption-layer"
  org_id          = var.organization.id
  billing_account = var.billing_account_id
}

# Create GKE cluster
resource "google_container_cluster" "consumption_gke_cluster" {
  name     = "consumption-gke-cluster"
  location = var.location.region
  project  = google_project.consumption_project.project_id

  # To create a cluster, we require at least one node pool defined.
  # However, our preference is to utilize independently managed node pools exclusively.
  # Therefore, we initiate the creation of the smallest default node pool and promptly remove it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

# Create node pool for GKE cluster
resource "google_container_node_pool" "consumption_gke_node_pool" {
  name       = "consumption-gke-node-pool"
  location   = var.location.region
  cluster    = google_container_cluster.consumption_gke_cluster.name
  node_count = 1
  project    = google_project.consumption_project.project_id

  node_config {
    machine_type = "e2-medium"

    # Google advises using custom service accounts with cloud-platform scope,
    # along with permissions assigned through IAM Roles.
    service_account = google_service_account.consumption_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Create service account for Consumption Layer
resource "google_service_account" "consumption_service_account" {
  account_id = "consumption-service-account"
  project    = google_project.consumption_project.project_id
}
