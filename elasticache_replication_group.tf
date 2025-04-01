resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.name
  description          = "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): ElastiCache - ${var.name}"
  engine               = var.engine
  engine_version       = var.engine_version
  port                 = var.port

  node_type               = var.node_type
  num_cache_clusters      = var.num_cache_clusters
  num_node_groups         = var.num_node_groups
  replicas_per_node_group = var.replicas_per_node_group

  parameter_group_name = var.parameter_group_name

  subnet_group_name = var.subnet_group_name

  cluster_mode               = var.cluster_mode
  multi_az_enabled           = var.multi_az_enabled
  automatic_failover_enabled = var.automatic_failover_enabled
  network_type               = var.network_type
  ip_discovery               = var.ip_discovery

  security_group_ids = concat([aws_security_group.this.id], var.security_groups_additional)

  data_tiering_enabled = var.data_tiering_enabled

  at_rest_encryption_enabled = try(var.encryption.kms_key_id, null) != null ? true : false
  kms_key_id                 = try(var.encryption.kms_key_id, null)

  transit_encryption_enabled = try(var.encryption.transit.encryption_enabled, false)
  transit_encryption_mode    = try(var.encryption.transit.encryption_mode, null)

  maintenance_window         = try(var.maintenance.window, null)
  auto_minor_version_upgrade = try(var.maintenance.auto_minor_version_upgrade, null)
  apply_immediately          = try(var.maintenance.apply_immediately, false)

  snapshot_name             = try(var.snapshot.name, null)
  snapshot_retention_limit  = try(var.snapshot.retention_limit, null)
  snapshot_window           = try(var.snapshot.window, null)
  final_snapshot_identifier = "${var.name}-${random_id.snapshot_identifier.hex}-FINAL"

  auth_token                 = var.auth_token
  auth_token_update_strategy = var.auth_token_update_strategy
  user_group_ids             = try(var.user_group_id, null) != null ? toset([var.user_group_id]) : null

  log_delivery_configuration {
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.engine.name
    log_format       = try(var.cloudwatch.log_format, "text")
    log_type         = "engine-log"
  }
  log_delivery_configuration {
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.slow.name
    log_format       = try(var.cloudwatch.log_format, "text")
    log_type         = "slow-log"
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    ignore_changes = [
      snapshot_name,
      engine_version
    ]
  }

  tags = local.tags

  provider = aws.this
}
