# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_elasticache_replication_group" "this" {
  region               = var.region
  replication_group_id = var.name
  description          = local.description
  engine               = var.engine
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = var.port
  parameter_group_name = var.parameter_group_name
  data_tiering_enabled = var.data_tiering_enabled

  cluster_mode               = var.cluster_mode
  num_node_groups            = var.num_node_groups
  replicas_per_node_group    = var.replicas_per_node_group
  automatic_failover_enabled = local.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  subnet_group_name  = var.subnet_group_name
  security_group_ids = concat([aws_security_group.this.id], var.additional_security_group_ids)
  network_type       = var.network_type
  ip_discovery       = var.ip_discovery

  # Data at rest is always encrypted; AWS cannot turn it on for an existing cache.
  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_id
  transit_encryption_enabled = var.transit_encryption.enabled
  transit_encryption_mode    = var.transit_encryption.enabled ? var.transit_encryption.mode : null

  # The provider refuses user_group_ids beside auth_token, even when it is empty, and
  # auth_token_update_strategy without auth_token. Whether a token is set is not a
  # secret; without nonsensitive(), the strategy, and so metadata, would be sensitive.
  auth_token                 = var.auth_token
  auth_token_update_strategy = nonsensitive(var.auth_token != null) ? var.auth_token_update_strategy : null
  user_group_ids             = length(var.user_group_ids) > 0 ? var.user_group_ids : null

  snapshot_name             = var.snapshot.restore_from
  snapshot_retention_limit  = var.snapshot.retention_limit
  snapshot_window           = var.snapshot.window
  final_snapshot_identifier = var.snapshot.final_snapshot ? "${var.name}-final-${random_id.final_snapshot.hex}" : null

  maintenance_window         = var.maintenance.window
  auto_minor_version_upgrade = var.maintenance.auto_minor_version_upgrade
  apply_immediately          = var.maintenance.apply_immediately

  dynamic "log_delivery_configuration" {
    for_each = local.cloudwatch_log_groups

    content {
      destination_type = "cloudwatch-logs"
      destination      = aws_cloudwatch_log_group.this[log_delivery_configuration.key].name
      log_format       = var.cloudwatch_logs.log_format
      log_type         = log_delivery_configuration.key
    }
  }

  tags = local.tags

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  # The snapshot a cache was created from can be changed only by replacing the cache.
  lifecycle {
    ignore_changes = [snapshot_name]
  }

  # Ingress rules first, and, when the security group is replaced, the old rules are
  # deleted only after the cache has moved to the new group.
  depends_on = [aws_vpc_security_group_ingress_rule.this]
}
