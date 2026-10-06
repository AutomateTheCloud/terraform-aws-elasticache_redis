# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # The Name tag of the security group, and the start of its name.
  security_group_name = "elasticache-${var.name}"

  description = "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): ElastiCache ${var.name}"

  # A group description may contain only these characters, so anything else in the
  # details names is dropped rather than failing the create.
  security_group_description = substr(replace(local.description, "/[^A-Za-z0-9 ._:/()#,@\\[\\]+=&;{}!$*-]/", ""), 0, 255)

  # AWS requires automatic failover for cluster mode, and for Multi-AZ. Without replicas
  # in cluster mode disabled there is nothing to fail over to, and AWS refuses it.
  automatic_failover_enabled = var.cluster_mode != "disabled" || var.replicas_per_node_group > 0

  # One log group per log type, keyed by the log type.
  cloudwatch_log_groups = { for t in var.cloudwatch_logs.log_types : t => "/aws/elasticache/${var.name}/${t}" }
}
