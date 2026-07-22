# Snowflake Terraform Lab

This repo manages Snowflake infrastructure (warehouse, database, schema, and cross-account replication for disaster recovery) as code. Built as a self-directed project to gain hands-on Terraform experience.

## Why I built this

Modern DevOps and data engineering practice automates resource deployment through CI/CD pipelines and infrastructure as code (IaC), reducing manual operational toil, streamlining provisioning, and reducing human error. My
day-to-day work has used scripted automation (Python/SQL/PowerShell) rather than a dedicated IaC tool, so I built this to close that specific gap hands-on. I kept seeing CI/CD Management and Terraform required in "Data Platform Engineer" and "Platform Engineer" postings and wanted real hands-on experience instead of just reading about it.

## What it manages

- **Warehouse:** `TERRAFORM_WH`, a multi-cluster warehouse configured for auto-scaling and auto-suspend to control cost.
- **Database:** `TERRAFORM_DB`, with data retention set to 3 days to keep Time Travel storage cost minimal (can be increased depending on use case). Replication to the secondary account is enabled.
- **Schema:** `TF_SCH`, retention also set to 3 days for the same reason.
- **Replication / DR:** the database replicates to a second Snowflake account, so downstream processes depending on this data aren't affected by an outage or unavailability in the primary account. This is a critical pattern across healthcare, telecom, insurance, and finance, industries where data sits at the core of the business, and where lost data or downtime affects both end users and business continuity directly.

## Prerequisites

- Terraform v1.15.8
- Two Snowflake accounts, with key-pair authentication configured, and replication enabled
  (To enable replication follow instructions at https://docs.snowflake.com/en/user-guide/account-replication-config#label-enabling-accounts-for-replication
- create your own provider.tf, variable.tf, main.tf, output.tf and .gitignore files
- syntax on creating terraform resouces for Snowflake can be found at https://registry.terraform.io/providers/snowflakedb/snowflake/latest/docs/resources/
- Install openssl to generate encrypted keypair for passwordless account setup to establish secure connectivity

## Setup
1. clone the repo to your system by running
[Numbered steps: clone the repo, set up your own terraform.tfvars from an
example file (see note below), run terraform init/plan/apply. Write this as
if a stranger needs to follow it with zero other context from you.]

1. Clone the repo:
git clone https://github.com/Kubernetes87/snowflake_terraform_lab
cd snowflake-terraform-lab

2. Generate an encrypted RSA key pair (Required to authenticate to Snowflake) and convert it
	to PKCS#8 format, which Snowflake requires:
	With passphrase
	openssl rsa -in snf_private_rsa_key.p8 -pubout -out snf_rsa_key.pub
	openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 des3 -inform PEM -out snf_rsa_key.p8
	

3. Register the public key with your Snowflake user (run in Snowsight):
   sql: ALTER USER <your_username> SET RSA_PUBLIC_KEY='<contents of the .pub key, minus the BEGIN/END lines>';
   Copy the example variables file and fill in your own values:
   cp terraform.tfvars.example terraform.tfvars
   Edit terraform.tfvars with your organization name, account name, username, private key path, and private key passphrase. This file is
   gitignored and never committed.

   Initialize Terraform:
	terraform init
   Review the plan before applying anything:
	terraform plan
   Apply:
	terraform apply
   Review the plan shown, then type yes to confirm.

   Verify in Snowsight that the warehouse, database, and schema were created, and that replication shows as enabled on the secondary
   account.

## CI/CD pipeline

[Fill this in once Step 6 is built: what triggers a plan, what triggers an
apply, and why you structured it that way.]

1:  Store your secrets in GitHub (do this before writing any YAML)
	Go to your repo → Settings → Secrets and variables → Actions → New repository secret. Create one secret for each of these for the primary SNF account:
	
	SNOWFLAKE_ORG_NAME
	SNOWFLAKE_ACCOUNT_NAME
	SNOWFLAKE_USER
	SNOWFLAKE_PRIVATE_KEY (paste the entire contents of your .p8 file, including the -----BEGIN PRIVATE KEY----- / -----END----- lines)
	SNOWFLAKE_PRIVATE_KEY_PASSPHRASE
2:  Create the path and workflow file in your system repo: .github/workflows/terraform.yml
3: 	Define what triggers the workflow
	(Workflow: A workflow is a configurable automated process made up of one or more jobs. You must create a YAML file to define your workflow configuration.)
	Example:
name: Terraform CI/CD

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
	
	env:
	  TF_VAR_organization_name: ${{ secrets.SNOWFLAKE_ORG_NAME }}
      TF_VAR_account_name: ${{ secrets.SNOWFLAKE_ACCOUNT_NAME }}
      TF_VAR_user: ${{ secrets.SNOWFLAKE_USER }}
      TF_VAR_private_key_path: /tmp/snowflake_key.p8
      TF_VAR_private_key_passphrase: ${{ secrets.SNOWFLAKE_PRIVATE_KEY_PASSPHRASE }}
	
	steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Write private key to file
        run: echo "${{ secrets.SNOWFLAKE_PRIVATE_KEY }}" > /tmp/snowflake_key.p8

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        if: github.event_name == 'pull_request'
        run: terraform plan

      - name: Terraform Apply
        if: github.event_name == 'push'
        run: terraform apply -auto-approve

## Notes

[Honest scope notes: this is a personal lab environment, not production.
Any specific limitations or things you'd do differently at scale, this kind
of self-awareness reads well to a technical interviewer.]