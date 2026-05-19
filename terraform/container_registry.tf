resource "yandex_container_registry" "docker_registry" {
  name      = var.registry_name
  folder_id = var.folder_id

  labels = {
    class = "docker"
  }
}

resource "yandex_container_repository" "app_docker" {
  name = "${yandex_container_registry.docker_registry.id}/test-repository"
}