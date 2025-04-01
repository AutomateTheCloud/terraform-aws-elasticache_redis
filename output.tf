output "metadata" {
  description = "Metadata"
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    cloudwatch = {
      log_group = {
        engine = try(aws_cloudwatch_log_group.engine, null)
        slow   = try(aws_cloudwatch_log_group.slow, null)
      }
    }

    elasticache = {
      replication_group = {
        apply_immediately              = try(aws_elasticache_replication_group.this.apply_immediately, null)
        arn                            = try(aws_elasticache_replication_group.this.arn, null)
        at_rest_encryption_enabled     = try(aws_elasticache_replication_group.this.at_rest_encryption_enabled, null)
        auth_token_update_strategy     = try(aws_elasticache_replication_group.this.auth_token_update_strategy, null)
        auto_minor_version_upgrade     = try(aws_elasticache_replication_group.this.auto_minor_version_upgrade, null)
        automatic_failover_enabled     = try(aws_elasticache_replication_group.this.automatic_failover_enabled, null)
        cluster_enabled                = try(aws_elasticache_replication_group.this.cluster_enabled, null)
        cluster_mode                   = try(aws_elasticache_replication_group.this.cluster_mode, null)
        configuration_endpoint_address = try(aws_elasticache_replication_group.this.configuration_endpoint_address, null)
        data_tiering_enabled           = try(aws_elasticache_replication_group.this.data_tiering_enabled, null)
        description                    = try(aws_elasticache_replication_group.this.description, null)
        engine                         = try(aws_elasticache_replication_group.this.engine, null)
        engine_version                 = try(aws_elasticache_replication_group.this.engine_version, null)
        engine_version_actual          = try(aws_elasticache_replication_group.this.engine_version_actual, null)
        global_replication_group_id    = try(aws_elasticache_replication_group.this.global_replication_group_id, null)
        id                             = try(aws_elasticache_replication_group.this.id, null)
        ip_discovery                   = try(aws_elasticache_replication_group.this.ip_discovery, null)
        kms_key_id                     = try(aws_elasticache_replication_group.this.kms_key_id, null)
        log_delivery_configuration     = try(aws_elasticache_replication_group.this.log_delivery_configuration, null)
        maintenance_window             = try(aws_elasticache_replication_group.this.maintenance_window, null)
        member_clusters                = try(aws_elasticache_replication_group.this.member_clusters, null)
        multi_az_enabled               = try(aws_elasticache_replication_group.this.multi_az_enabled, null)
        network_type                   = try(aws_elasticache_replication_group.this.network_type, null)
        node_type                      = try(aws_elasticache_replication_group.this.node_type, null)
        notification_topic_arn         = try(aws_elasticache_replication_group.this.notification_topic_arn, null)
        num_cache_clusters             = try(aws_elasticache_replication_group.this.num_cache_clusters, null)
        num_node_groups                = try(aws_elasticache_replication_group.this.num_node_groups, null)
        parameter_group_name           = try(aws_elasticache_replication_group.this.parameter_group_name, null)
        port                           = try(aws_elasticache_replication_group.this.port, null)
        preferred_cache_cluster_azs    = try(aws_elasticache_replication_group.this.preferred_cache_cluster_azs, null)
        primary_endpoint_address       = try(aws_elasticache_replication_group.this.primary_endpoint_address, null)
        reader_endpoint_address        = try(aws_elasticache_replication_group.this.reader_endpoint_address, null)
        replicas_per_node_group        = try(aws_elasticache_replication_group.this.replicas_per_node_group, null)
        replication_group_id           = try(aws_elasticache_replication_group.this.replication_group_id, null)
        security_group_ids             = try(aws_elasticache_replication_group.this.security_group_ids, null)
        security_group_names           = try(aws_elasticache_replication_group.this.security_group_names, null)
        snapshot_retention_limit       = try(aws_elasticache_replication_group.this.snapshot_retention_limit, null)
        snapshot_window                = try(aws_elasticache_replication_group.this.snapshot_window, null)
        subnet_group_name              = try(aws_elasticache_replication_group.this.subnet_group_name, null)
        tags                           = try(aws_elasticache_replication_group.this.tags, null)
        tags_all                       = try(aws_elasticache_replication_group.this.tags_all, null)
        transit_encryption_enabled     = try(aws_elasticache_replication_group.this.transit_encryption_enabled, null)
        transit_encryption_mode        = try(aws_elasticache_replication_group.this.transit_encryption_mode, null)
        user_group_ids                 = try(aws_elasticache_replication_group.this.user_group_ids, null)
      }
    }
    security_group = try(aws_security_group.this, null)
  }
}
