# Day 0 — Automated Infrastructure Provisioning (HCP Terraform)

Built for **IBM Think Mumbai 2026 — Automation Zone, Demo 1** ("Do Cloud Right
with Automated Infrastructure Provisioning," shown at the Verify booth before
the Vault + Verify demo). The SME drives the walkthrough entirely from the
**real HCP Terraform web UI** (app.terraform.io) — workspace Runs, the real
Plan output, the real Sentinel policy-check screen. There is no custom app in
front of it. That's a deliberate correction from an earlier version of this
demo that put a bespoke dashboard between the audience and the platform —
the whole point of a Terraform demo booth is to sell HCP Terraform, not to
look like it's trivially replaced by a weekend script on top of open-source
Terraform.

## What's real and what's a stand-in

- **Real**: the HCP Terraform workspace, Runs, Plan/Apply, the Sentinel
  policy-check screen, the `.tf` and `.sentinel` files, the VCS-driven
  workflow — everything the audience sees on screen is the actual platform.
- **Stand-in**: the provisioning target. Instead of live AWS/Azure/GCP
  (expensive and wifi-dependent for a trade-show floor with constant foot
  traffic), the workspace's execution mode is **Agent**, pointed at a
  self-hosted [HCP Terraform Agent](https://developer.hashicorp.com/terraform/cloud-docs/agents)
  running on the booth laptop. The agent gives the Terraform run access to
  the laptop's Docker socket, so `terraform apply` provisions real
  [kreuzwerker/docker](https://registry.terraform.io/providers/kreuzwerker/docker)
  containers instead — zero cloud cost, zero wifi dependency for the actual
  apply, resettable in seconds. The run itself, the plan, the policy check —
  all still happen for real, on the real platform. Swap the provider block
  for `aws`/`azurerm`/`google` and point the workspace back at HCP Terraform's
  own runners, and nothing else in this repo changes.
- This needs **Sentinel enabled on your HCP Terraform org** (Standard tier or
  above) and **Agent pools** (also Standard+, 10 agents included — 1 is all
  this needs). If the org used for `terraform-vault-sentinel-ec2` already has
  Sentinel working, it already qualifies.

## Narrative — the three takeaways this demo proves

1. **Infrastructure as Code, consistent across every cloud** — one
   `workloads` map, one `terraform apply`, provisioning tagged workloads
   across AWS, Azure, GCP, IBM Cloud, VMware, and on-prem. No snowflake
   environments.
2. **Speed with governance** — self-service requests go through the same
   workspace, and the real Sentinel policy-check screen enforces
   hard-mandatory, soft-mandatory, and advisory guardrails before anything
   applies.
3. **The foundation for everything else** — hand off to the Vault + Verify
   demo at the same booth: every workload above still needs identities,
   secrets, and access controls to actually run securely.

## Architecture

```
   GitHub repo (this folder)
          │ VCS-connected
          ▼
   HCP Terraform workspace "day0-provisioning"          ← the real UI the SME drives
   execution mode: Agent                                   (Runs, Plan, Apply)
          │                               │
          │ dispatches runs to            │ Sentinel policy set
          ▼                               ▼ (VCS-connected, sentinel/)
   Agent pool "day0-booth"            real tfplan/v2 data from every run
          │ polls for work                (hard-mandatory / soft-mandatory /
          ▼                                advisory — see sentinel/sentinel.hcl)
   tfc-agent container (agent/docker-compose.yml)
   running on the booth laptop, with
   /var/run/docker.sock mounted
          │
          ▼
   docker_container "workloads" — tagged cloud/environment/size/owner/region
   (aws-web-01, azure-web-01, gcp-web-01, ibmcloud-web-01, vmware-web-01,
    onprem-web-01, + self-service requests)
```

## One-time setup

### Prerequisites

| Thing | Notes |
|---|---|
| GitHub repo | Push this folder's contents to it. |
| HCP Terraform org | Standard tier or above (for Sentinel + Agent pools). |
| Booth laptop | Docker installed, Docker daemon running. |

### Step 1 — Push to GitHub

```bash
cd "Assets/demos/terraform-day0-provisioning-showcase"
gh repo create <your-user>/demo-terraform-day0-provisioning --public --confirm
git init -b main
git add .
git -c user.email=you@example.com commit -m "initial"
git remote add origin https://github.com/<your-user>/demo-terraform-day0-provisioning.git
git push -u origin main
```

### Step 2 — Agent pool

In [HCP Terraform](https://app.terraform.io) → **Settings (org level) → Agents → Create an agent pool**:

- Name: `day0-booth`
- Create an **agent token**, name it `booth-laptop`, copy it.

On the booth laptop:

```bash
cd agent
cp .env.example .env
# paste the agent token into TFC_AGENT_TOKEN in .env
docker compose up -d
docker compose logs -f
```

Wait for `agent: ... status=running` in the logs — the agent pool page in
HCP Terraform should now show it online.

### Step 3 — Workspace

**Projects** → create `dabs-demos` (reuse it if it already exists from the
sentinel-ec2 demo) → **Workspaces → New workspace → Version control workflow**:

- VCS provider: your existing GitHub connection
- Repository: `<your-user>/demo-terraform-day0-provisioning`
- Workspace name: `day0-provisioning`
- Project: `dabs-demos`
- **Advanced options → Terraform Working Directory: `terraform`**
- **Advanced options → Execution Mode: Agent** → Agent pool: `day0-booth`
- Auto-apply: **off** for now (turn it on later if you want pre-staging to
  apply automatically; the live walkthrough wants manual confirm anyway, so
  the SME can narrate the plan before clicking Apply)

No workspace variables are needed — the Docker provider needs no credentials.

### Step 4 — Sentinel policy set

**Settings (org level) → Policy Sets → Connect a new policy set**:

- Policy framework: **Sentinel**
- VCS provider: same GitHub connection
- Repository: `<your-user>/demo-terraform-day0-provisioning`
- **Policies path: `sentinel`**
- Scope: workspaces in project `dabs-demos`
- Name: `day0-guardrails`

Policies (defined in [sentinel/sentinel.hcl](sentinel/sentinel.hcl)):

| Policy | Enforcement | What it does |
|---|---|---|
| [restrict-size](sentinel/restrict-size.sentinel) | hard-mandatory | Only `small`/`medium`/`large` workloads are allowed — no override. |
| [require-tags](sentinel/require-tags.sentinel) | soft-mandatory | Every workload needs a non-empty `owner` and `environment` label — a workspace admin can override. |
| [restrict-region](sentinel/restrict-region.sentinel) | advisory | Warns if `region` isn't `us-east-1`/`eu-west-1`/`ap-south-1`, but never blocks. |

## Pre-stage the Runs history (do this before the show opens)

The goal is a workspace whose **Runs** tab already has real, clickable
history for every narrative beat, so the SME can scroll back and show a
finished Sentinel policy-check screen without re-running it live for every
single visitor. Push each scenario file in order, letting each run finish
(confirm Apply manually in the UI except where noted) before pushing the
next:

```bash
cp scenarios/01-fleet.auto.tfvars.json terraform/workloads.auto.tfvars.json
git add terraform/workloads.auto.tfvars.json && git commit -m "fleet: provision every cloud" && git push
# → in HCP Terraform: watch the plan (6 to add), confirm Apply.

cp scenarios/02-self-service-clean.auto.tfvars.json terraform/workloads.auto.tfvars.json
git add -A && git commit -m "self-service: checkout-service (compliant)" && git push
# → all 3 Sentinel policies pass, confirm Apply.

cp scenarios/03-self-service-hard-block.auto.tfvars.json terraform/workloads.auto.tfvars.json
git add -A && git commit -m "self-service: fraud-detector (size=xl, should block)" && git push
# → restrict-size FAILS (hard-mandatory). There is no Apply button to click —
#   this run is permanently blocked. That's the point; leave it in history.

cp scenarios/02-self-service-clean.auto.tfvars.json terraform/workloads.auto.tfvars.json
git add -A && git commit -m "revert: drop the blocked request" && git push
# → back to the known-good state, confirm Apply (no-op/clean).

cp scenarios/04-self-service-soft-override.auto.tfvars.json terraform/workloads.auto.tfvars.json
git add -A && git commit -m "self-service: loyalty-api (missing owner, should need override)" && git push
# → require-tags FAILS (soft-mandatory). Click "Override & Continue" in the
#   policy check screen as a workspace admin, then confirm Apply.

cp scenarios/05-self-service-advisory-warn.auto.tfvars.json terraform/workloads.auto.tfvars.json
git add -A && git commit -m "self-service: search-indexer (eu-west-2, advisory warning)" && git push
# → restrict-region FAILS (advisory) but the run proceeds straight to Apply
#   with a warning shown on the policy check screen. Confirm Apply.
```

Your workspace's Runs tab now has one real example of every outcome: clean
pass, hard block, soft override, and advisory warning — all genuine Sentinel
evaluations against genuine plans.

## The live walkthrough (one real run per visitor)

Narrate the three takeaways using the pre-staged Runs history — click into
each past run and show the real Plan and Sentinel screens, scrolling back
through the list. Then do exactly **one live thing** in front of this
particular visitor — drift, because it needs no file edits and takes
seconds:

1. On the booth laptop, pick a running workload and delete it directly,
   bypassing Terraform entirely:
   ```bash
   docker rm -f checkout-service
   ```
2. In the HCP Terraform workspace UI: **Actions ▾ → Start new plan**.
3. Narrate the real Plan output as it streams in — Terraform notices
   `checkout-service` is gone and plans to recreate it.
4. Click **Confirm & Apply**. The container comes back, matching the
   declared state again.
5. Close on the hand-off: "every workload we just provisioned still needs
   identities, secrets, and access controls to actually run securely — walk
   over to the Vault + Verify demo right here at this booth to see that
   part."

## Reset between demo days

```bash
# destroy everything the workspace manages
cp scenarios/00-reset-empty.auto.tfvars.json terraform/workloads.auto.tfvars.json
git add -A && git commit -m "reset: empty" && git push
# → confirm Apply (destroys all workloads)

# stop the agent
cd agent && docker compose down
```

Re-run the pre-staging sequence above the next morning.

## Notes / simplifications made for a demo

- The Docker provider stands in for AWS/Azure/GCP/IBM Cloud/VMware/on-prem —
  see "What's real and what's a stand-in" above. The `.tf` files are
  substrate-agnostic; only the provider block and the agent pool's execution
  target would change for a real cloud.
- `modules/workload/main.tf` sets `lifecycle { ignore_changes = [log_opts] }`
  — Docker Desktop injects a default log-rotation config on every container
  it creates, which otherwise shows up as permanent drift on every single
  plan (discovered by actually running this locally before shipping it).
- The six "every cloud" catalog workloads go through the exact same Sentinel
  policy set as self-service requests — they just always pass, because
  "pre-approved" means "already compliant," not "exempt."
- Auto-apply is left off on purpose, so the SME can narrate the plan output
  before confirming — flip it on if you'd rather the pre-staging sequence
  run unattended.

## File layout

```
terraform-day0-provisioning-showcase/
├── README.md
├── terraform/                      ← VCS working directory for the HCP Terraform workspace
│   ├── versions.tf
│   ├── variables.tf                 ← the single `workloads` map
│   ├── main.tf                      ← for_each over modules.workload
│   ├── outputs.tf
│   ├── workloads.auto.tfvars.json   ← tracked in git — the "current" desired state
│   └── modules/workload/            ← one workload = one docker_image + docker_container
├── sentinel/                        ← policies path for the HCP Terraform policy set
│   ├── sentinel.hcl                 ← policy blocks + enforcement levels
│   ├── restrict-size.sentinel       ← hard-mandatory
│   ├── require-tags.sentinel        ← soft-mandatory
│   └── restrict-region.sentinel     ← advisory
├── scenarios/                       ← pre-built tfvars snapshots, one per narrative beat
│   ├── 00-reset-empty.auto.tfvars.json
│   ├── 01-fleet.auto.tfvars.json
│   ├── 02-self-service-clean.auto.tfvars.json
│   ├── 03-self-service-hard-block.auto.tfvars.json
│   ├── 04-self-service-soft-override.auto.tfvars.json
│   └── 05-self-service-advisory-warn.auto.tfvars.json
└── agent/                           ← runs on the booth laptop
    ├── docker-compose.yml           ← hashicorp/tfc-agent, docker.sock mounted
    └── .env.example
```
