terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "project-10094705-9153-43d5-bb8"
  region  = "us-central1"
}

# Only this is needed now
resource "google_artifact_registry_repository" "my_app_repo" {
  location      = "us-central1"
  repository_id = "my-app-repo"
  description   = "Go app docker images"
  format        = "DOCKER"
}