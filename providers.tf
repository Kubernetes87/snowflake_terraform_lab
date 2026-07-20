terraform {
  required_providers {
    snowflake = {
      source = "snowflakedb/snowflake"
    }
  }
}

provider "snowflake" {
  organization_name      = var.organization_name
  account_name           = var.account_name
  user                   = var.user 
  authenticator          = "SNOWFLAKE_JWT"
  private_key            = file(pathexpand(var.private_key_path))
  private_key_passphrase = var.private_key_passphrase
}
