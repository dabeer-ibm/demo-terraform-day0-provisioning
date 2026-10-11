# =============================================================================
# Sentinel policy set — consumed by HCP Terraform (real policy enforcement,
# not a local mock). In the HCP Terraform UI:
#   Settings → Policy Sets → Connect a new policy set
#     • VCS provider:  GitHub (same connection as the workspace)
#     • Repository:    <your-user>/demo-terraform-day0-provisioning
#     • Policies path: sentinel
#     • Scope:         workspaces in project 'dabs-demos'
#     • Name:          day0-guardrails
# =============================================================================

policy "restrict-size" {
  source            = "./restrict-size.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "require-tags" {
  source            = "./require-tags.sentinel"
  enforcement_level = "soft-mandatory"
}

policy "restrict-region" {
  source            = "./restrict-region.sentinel"
  enforcement_level = "advisory"
}
