provider "google" {
  project = "project-10094705-9153-43d5-bb8"
  region  = "asia-south1"
}

resource "google_artifact_registry_repository" "my_app_repo" {
  location      = "asia-south1"
  repository_id = "my-app-repo"
  format        = "DOCKER"
}

resource "google_container_cluster" "primary" {
  name     = "my-go-cluster"
  location = "asia-south1-a"
  initial_node_count = 2
  deletion_protection = false
  node_config {
    machine_type    = "e2-medium"
    disk_size_gb    = 30
    service_account = "645491051550-compute@developer.gserviceaccount.com"
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

output "registry_url" {
  value = "${google_artifact_registry_repository.my_app_repo.location}-docker.pkg.dev/${google_artifact_registry_repository.my_app_repo.project}/${google_artifact_registry_repository.my_app_repo.name}"
}
