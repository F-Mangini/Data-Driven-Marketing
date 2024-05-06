# TERRAFORM SCRIPT FOR DATA LANDING LAYER

# Define locals
locals {
    landing_project_api = [
        "iam.googleapis.com",
        "stackdriver.googleapis.com",
        "storage.googleapis.com",
        "pubsub.googleapis.com"
    ]
}

# Define project services
resource "google_project_service" "landing_project_api" {
    for_each = toset(local.landing_project_api)
    project  = google_project.landing_project.project_id
    service  = each.key
}

# Define project
resource "google_project" "landing_project" {
    name            = "Landing Layer"
    project_id      = "landing-layer"
    org_id          = var.organization.id
    billing_account = var.billing_account_id
}

# Create a storage bucket
resource "google_storage_bucket" "landing_bucket" {
    name     = "landing-bucket"
    location = var.location.multi_region
    project  = google_project.landing_project.project_id
    uniform_bucket_level_access = true
}

# Create a service account for the E-commerce System
resource "google_service_account" "e-commerce_service_account" {
    account_id = var.e-commerce_service_account_id
    project    = google_project.landing_project.project_id
}

# Create a service account for the SFTP Server
resource "google_service_account" "sftp_server_account" {
    account_id = var.sftp_server_account_id
    project    = google_project.landing_project.project_id
}

# Provide storage write access to the SFTP Server account
resource "google_storage_bucket_iam_binding" "landing_bucket_sftp_binding" {
    bucket = google_storage_bucket.landing_bucket.name
    role   = "roles/storage.objectCreator"
    members = [
        "serviceAccount:${google_service_account.sftp_server_account.email}",
    ]
}

# Provide storage read access to the service account used by the manipulation layer
resource "google_storage_bucket_iam_binding" "landing_bucket_manipulation_binding" {
    bucket = google_storage_bucket.landing_bucket.name
    role   = "roles/storage.objectViewer"
    members = [
        "serviceAccount:${google_service_account.manipulation_service_account.email}",
    ]
}

# PUB/SUB
# Topic definition
resource "google_pubsub_topic" "landing_pubsub_topic" {
    name = "customers-event-topic"
}

# Subscription to the topic
resource "google_pubsub_subscription" "landing_pubsub_subscription" {
    name  = "customers-event-subscription"
    topic = google_pubsub_topic.landing_pubsub_topic.name

    # Configure the Pub/Sub subscription to write messages to the Cloud Storage bucket
    cloud_storage_config {
        bucket = google_storage_bucket.landing_bucket.name
    }

    # Set-up dependencies so that Terraform creates the resources in the right order.
    depends_on = [
        google_storage_bucket.landing_bucket,
        google_storage_bucket_iam_binding.landing_bucket_sftp_binding,
    ]
}

# Provide Pub/Sub publisher role to the E-commerce service account
resource "google_pubsub_topic_iam_binding" "landing_pubsub_topic_iam_binding" {
    provider = google-beta
    topic    = google_pubsub_topic.landing_pubsub_topic.name
    role     = "roles/pubsub.publisher"
    members  = ["serviceAccount:${google_service_account.e-commerce_service_account.email}"]
}
