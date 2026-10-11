variable "name" {
  type        = string
  description = "Workload name — becomes the container name."
}

variable "cloud" {
  type        = string
  description = "Label only: which cloud/platform this workload represents (aws, azure, gcp, ibmcloud, vmware, onprem)."
}

variable "environment" {
  type        = string
  description = "dev, staging, or prod."
}

variable "size" {
  type        = string
  description = "small, medium, or large. Anything else is rejected by the hard-mandatory Sentinel policy."
}

variable "owner" {
  type        = string
  description = "Requester / owner tag, required by the soft-mandatory Sentinel policy."
}

variable "region" {
  type        = string
  description = "Region tag, checked by the advisory Sentinel policy."
}

variable "image" {
  type        = string
  default     = "nginx:alpine"
  description = "Container image standing in for the provisioned workload."
}
