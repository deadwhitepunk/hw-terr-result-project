resource "yandex_container_registry" "docker_registry" {
  name      = var.registry_name
  folder_id = var.folder_id
  labels = {
    class       = "docker"
    managed_by  = "terraform"
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "yandex_container_repository" "app_docker" {
  name = "${yandex_container_registry.docker_registry.id}/${var.repository_name}"
  lifecycle {
    prevent_destroy = false
  }
}

resource "null_resource" "docker_build_and_push" {
  depends_on = [yandex_container_repository.app_docker]
  
  provisioner "local-exec" {
    command = <<-EOT
      chmod +x ../scripts/build_and_push.sh
      ../scripts/build_and_push.sh \
        "${yandex_container_registry.docker_registry.id}" \
        "${var.repository_name}"
    EOT
  }
  
  triggers = {

    dockerfile_hash = filemd5("../app/Dockerfile.python")
    script_hash = filemd5("../scripts/build_and_push.sh")
    registry_id     = yandex_container_registry.docker_registry.id
    repository_name = var.repository_name
    app_source_hash = filesha256("../app/main.py")
  }
}

resource "local_file" "image_info" {
  depends_on = [null_resource.docker_build_and_push]
  
  filename = "${path.module}/image_info.txt"
  content  = <<-EOT
    Registry ID: ${yandex_container_registry.docker_registry.id}
    Full Image Name: cr.yandex/${yandex_container_registry.docker_registry.id}/${var.repository_name}:latest
    Build Time: ${timestamp()}
  EOT
}