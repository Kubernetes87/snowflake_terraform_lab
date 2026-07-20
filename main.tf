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
  statement_queued_timeout_in_seconds = 5
  statement_timeout_in_seconds        = 3600
}