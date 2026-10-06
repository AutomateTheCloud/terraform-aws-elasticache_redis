# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The log groups ElastiCache publishes to, created before the cache so that their
# retention and encryption apply from the first log event.
resource "aws_cloudwatch_log_group" "this" {
  for_each = local.cloudwatch_log_groups

  region            = var.region
  name              = each.value
  retention_in_days = var.cloudwatch_logs.retention_in_days
  kms_key_id        = var.cloudwatch_logs.kms_key_id

  tags = local.tags
}
