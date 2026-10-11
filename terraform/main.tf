module "workload" {
  source = "./modules/workload"

  for_each = var.workloads

  name        = each.key
  cloud       = each.value.cloud
  environment = each.value.environment
  size        = each.value.size
  owner       = each.value.owner
  region      = each.value.region
  image       = each.value.image
}
