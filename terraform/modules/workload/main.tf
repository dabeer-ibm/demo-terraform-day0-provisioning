resource "docker_image" "workload" {
  name         = var.image
  keep_locally = true
}

resource "docker_container" "workload" {
  name     = var.name
  image    = docker_image.workload.image_id
  must_run = true

  # Docker Desktop injects a default log-rotation config (log_opts) on every
  # container it creates. Terraform doesn't manage that attribute here, so
  # without ignore_changes every plan would see it as drift and want to
  # replace the container — defeating the "no changes if nothing changed"
  # story this demo is built around.
  lifecycle {
    ignore_changes = [log_opts]
  }

  networks_advanced {
    name = "terraform-day0-net"
  }

  labels {
    label = "cloud"
    value = var.cloud
  }
  labels {
    label = "environment"
    value = var.environment
  }
  labels {
    label = "size"
    value = var.size
  }
  labels {
    label = "owner"
    value = var.owner
  }
  labels {
    label = "region"
    value = var.region
  }
  labels {
    label = "managed-by"
    value = "terraform-day0-demo"
  }
}
