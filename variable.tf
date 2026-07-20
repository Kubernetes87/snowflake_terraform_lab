variable "organization_name" {
  type        = string
  description = "organization_name"
  sensitive   = true   
}

variable "account_name" {
  type        = string
  description = "account_name"
  sensitive   = true   
}

variable "user" {
  type        = string
  description = "user"
  sensitive   = true   
}

variable "private_key_path" {
  type        = string
  description = "Path to the Snowflake private key (PKCS#8 format)"
  sensitive   = true
}