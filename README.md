## How this was built

1. Set up key-pair (JWT-based) authentication between Terraform and Snowflake,
   including generating an RSA key pair, converting it to the PKCS#8 format
   Snowflake requires, and registering the public key with `ALTER USER`.
2. Wrote the provider configuration and variable declarations, keeping all
   account-specific values out of version control via `terraform.tfvars` and
   `.gitignore`.
3. Provisioned a warehouse, database, and schema as Terraform resources,
   running the full `init` / `plan` / `apply` / `destroy` lifecycle locally
   to confirm each step actually worked against the real Snowflake account.
4. Created a second, dedicated Snowflake account and configured cross-account
   database replication and failover between the two, for hands-on
   disaster recovery practice.
5. Built a GitHub Actions CI/CD pipeline: `terraform plan` runs automatically
   on every pull request, `terraform apply` runs automatically on merge to
   `main`, using GitHub Secrets and key-pair authentication rather than
   storing any credential in the repository.
6. Tested the full pipeline end to end: opened a pull request, confirmed the
   plan output was correct, merged it, confirmed the apply ran automatically,
   and verified the resulting change against the real Snowflake account.

## Considerations

- **Secrets never touch the repository.** Account details, the private key,
  and the key's passphrase are all stored as GitHub Secrets and injected as
  environment variables at runtime, not committed anywhere, not even in
  gitignored local files that could accidentally get swept into a commit.
- **Plan and apply are deliberately separated.** Pull requests only ever run
  `plan`, a review step with no side effects. Only a merge to `main` runs
  `apply`. This mirrors how a real production pipeline gates infrastructure
  changes behind review, not behind whoever has the credentials on their
  laptop.
- **Replication was chosen deliberately, not copied from a template.** After
  finding a cross-account replication example in the provider documentation,
  I set up a genuine second Snowflake account to configure and test it for
  real, rather than leaving unused example configuration in the code.

## Challenges and how I resolved them

- **Windows file paths broke Terraform's string parsing.** HCL treats
  backslashes as escape characters, so a Windows path like `C:\Users\...`
  produced an "invalid escape sequence" error. Resolved by using forward
  slashes in all paths, which Windows also accepts.
- **Terraform's `file()` function doesn't expand `~`.** That's shell
  behavior, not Terraform's. Resolved using `pathexpand()` to expand the
  home directory reference explicitly.
- **Snowflake requires the private key to be in PKCS#8 format** (not the
  PKCS#1 format `openssl genrsa` produces by default), and requires the key
  to be passphrase-protected. Resolved by converting the key format with
  `openssl pkcs8` and wiring the passphrase through as a Terraform variable.
- **A declared variable had no effect until it was referenced.** Declaring
  `private_key_passphrase` and giving it a value in `terraform.tfvars`
  wasn't enough, it had to be explicitly referenced inside the `provider`
  block to actually be used. A reminder that declaring a variable and using
  it are two separate steps in Terraform.
- **The CI/CD pipeline initially ran `apply` prematurely**, on a pull
  request being opened rather than gating it strictly to a post-merge push.
  Diagnosed and fixed by correcting the trigger and `if:` conditions
  controlling which step runs for which GitHub event.
- **A `.gitignore` gap let a local Terraform plan file show up as
  trackable.** Caught before it was committed, and added `*.tfplan` to
  `.gitignore`.

## Skills this project strengthened

- Terraform fundamentals: providers, resources, variables, state, and the
  full plan/apply/destroy lifecycle
- Snowflake infrastructure as code: warehouse, database, and schema
  provisioning
- Key-pair (JWT-based) authentication setup and troubleshooting
- Cross-account database replication and disaster recovery configuration
- GitHub Actions: workflow triggers, conditional job execution, environment
  variables, and secrets management
- CI/CD pipeline design: separating a review step (plan) from a deploy step
  (apply), gated behind a merge rather than direct access
- Git fundamentals: staging, committing, branching, and pull-request-driven
  workflows
- Methodical debugging of infrastructure and pipeline configuration issues

## How I used AI on this project

I used Claude as a technical mentor throughout this project, not as a code
generator. It explained the underlying concepts (declarative infrastructure,
JWT-based key-pair authentication, HCL escape sequence handling, GitHub
Actions trigger and context semantics), pointed me to the authoritative
provider and GitHub Actions documentation for exact syntax rather than
writing configuration for me, and reviewed my actual code for correctness
and security practices. I wrote, debugged, and tested every line of Terraform 
and YAML in this repository myself, including independently diagnosing and 
fixing a real pipeline bug where `apply` was running before a pull request
had even been merged.