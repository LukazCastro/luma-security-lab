
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

resource "docker_container" "web" {
  name      = "luma-security-web"
  image     = docker_image.nginx.image_id
  read_only = true
  tmpfs = {
    "/var/cache/nginx" = "rw,size=64m"
    "/var/run"         = "rw,size=16m"
    "/tmp"             = "rw,size=16m"
  }

  capabilities {
    drop = ["ALL"]
    add  = ["CAP_CHOWN", "CAP_SETUID", "CAP_SETGID", "CAP_NET_BIND_SERVICE"]
  }

  networks_advanced {
    name = docker_network.luma_private.name
  }

  networks_advanced {
    name = docker_network.luma_frontend.name
  }


  ports {
    internal = 80
    external = 8090
    ip       = "127.0.0.1"
  }
}

resource "docker_network" "luma_private" {
  name     = "luma-private-network"
  driver   = "bridge"
  internal = true
}

resource "docker_network" "luma_frontend" {
  name   = "luma-frontend-network"
  driver = "bridge"
}

resource "docker_image" "postgres" {
  name = "postgres:17-alpine"
}

resource "docker_volume" "postgres_data" {
  name = "luma-postgres-data"

  lifecycle {
    prevent_destroy = true
  }
}

variable "postgres_password" {
  description = "Senha do PostgreSQL do laboratório"
  type        = string
  sensitive   = true
}

resource "docker_container" "postgres" {
  name  = "luma-security-db"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_USER=luma",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=luma_security"
  ]

  networks_advanced {
    name = docker_network.luma_private.name
  }

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
}