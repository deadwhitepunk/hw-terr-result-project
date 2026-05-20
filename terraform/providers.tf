terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    shared_credentials_files = [ "~/.aws/credentials" ]
    profile = "default"
    region = "ru-central1"
    bucket = "dev-tfstate"
    key    = "project-web/terraform.tfstate"
    encrypt = false

    use_lockfile = true

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
  }
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  service_account_key_file = file("~/.authorized_key.json")
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}