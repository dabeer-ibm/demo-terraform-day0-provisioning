variable "workloads" {
  description = <<-EOT
    The one source of truth for everything this demo provisions — the six
    pre-approved "every cloud" workloads plus any self-service requests a
    visitor submits from the dashboard. One map, one terraform apply,
    regardless of how many clouds/platforms are represented.
  EOT
  type = map(object({
    cloud       = string
    environment = string
    size        = string
    owner       = string
    region      = string
    image       = optional(string, "nginx:alpine")
  }))
  default = {}
}
