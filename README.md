# terraform-demo-shared-state-topology

A minimal, standalone demo of the org's
[multi-environment (`devops`/`dev`/`prod`) shared-state topology](https://github.com/vln-devsecops/guidance/blob/main/standards/terraform-infrastructure-organization.md#multi-environment-state-topology-devopsdevprod),
following the operational
[shared-state discovery runbook](https://github.com/vln-devsecops/guidance/blob/main/runbooks/infra-shared-state-discovery.md).

**This repo is ephemeral.** It exists to show the topology working end-to-end, not to run
persistently. Deploy it locally when you want to see the pattern, then tear it down (see
[Teardown](#teardown)). There is no CI/CD pipeline that applies infrastructure — CI only validates
(`fmt`, `validate`, the offline ownership test, a Trivy config scan, SAST).

## What it demonstrates

One Terraform root (`infra/`), applied three times against three separate states:

- **`devops`** owns a shared, account-wide S3 bucket for centralized access logs
  (`rg_logging.tf`) — the kind of singleton scaffolding every environment needs but only one
  environment should own.
- **`dev`** and **`prod`** each own their own S3 static-website bucket serving a "hello world" page
  (`fn_site.tf`), and read the shared logs bucket's name back via `terraform_remote_state` instead
  of creating their own — the shared-state contract.

Ownership routing is asserted by `infra/tests/ownership.tftest.hcl`, run fully offline via
`mock_provider "aws"` — no AWS credentials needed to verify the pattern is correctly wired.

## Running it

```bash
source ./bootstrap devops   # one-time: creates the shared logs bucket
cd infra
terraform plan -var-file=environments/devops/terraform.tfvars
terraform apply -var-file=environments/devops/terraform.tfvars
cd ..

source ./bootstrap dev
cd infra
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
terraform output site_endpoint
```

Open (or `curl`) the printed `site_endpoint` — it serves `Hello world from dev`.

`source ./bootstrap prod` works the same way if you want to see both app environments side by side.

## Teardown

Since this is ephemeral, tear it down after you're done testing. Destroy app environments before
`devops` (they depend on its shared state):

```bash
source ./bootstrap dev
terraform destroy -var-file=environments/dev/terraform.tfvars

source ./bootstrap prod   # only if you applied it
terraform destroy -var-file=environments/prod/terraform.tfvars

source ./bootstrap devops
terraform destroy -var-file=environments/devops/terraform.tfvars
```

## Testing

```bash
cd infra
terraform init -backend=false
terraform test
```

Runs the ownership assertions for all three environments offline, no AWS credentials required.
