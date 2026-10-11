output "workloads" {
  value = {
    for key, m in module.workload : key => {
      id    = m.id
      name  = m.name
      cloud = var.workloads[key].cloud
    }
  }
}
