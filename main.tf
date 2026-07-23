 resource "snowflake_warehouse" "warehouse" {
   name                                = "TERRAFORM_WH"
   warehouse_type                      = "STANDARD"
   warehouse_size                      = "X-SMALL"
   max_cluster_count                   = 4
   min_cluster_count                   = 2
   scaling_policy                      = "ECONOMY"
   auto_suspend                        = 500
   auto_resume                         = true
   initially_suspended                 = true
   comment                             = "terraform WH."
   max_concurrency_level               = 4
   statement_queued_timeout_in_seconds = 500
   statement_timeout_in_seconds        = 3600
 }
 
 ## Complete (with every optional set)
 resource "snowflake_database" "primary" {
   name         = "terraform_db"
   is_transient = false
   comment      = "Terraform Lab DB"
 
   data_retention_time_in_days                   = 3
   max_data_extension_time_in_days               = 7
   replication {
     enable_to_account {
       account_identifier = "VENZZML.HG28500"
       with_failover      = true
     }
     ignore_edition_check = true
   }
 }
 
 resource "snowflake_schema" "schema" {
   name                = "TF_SCH"
   database            = "terraform_db"
   comment             = "tf schema"
 
   data_retention_time_in_days                   = 3
   max_data_extension_time_in_days               = 7
 }