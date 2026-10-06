# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
    - `elasticache_replication_group` - The cache: the endpoints clients connect to (`primary_endpoint_address` and `reader_endpoint_address` with cluster mode disabled, `configuration_endpoint_address` with cluster mode enabled or compatible), `port`, `arn`, `id`, `engine_version_actual` (the running version), `member_clusters` (the node IDs), and the rest of its attributes. The `auth_token` is left out.
    - `security_group` - The cache's security group, with its `id`, `arn` and `name`.
    - `vpc_security_group_ingress_rule` - The ingress rules, keyed like `security_group_ingress`, or `null` when there are none.
    - `cloudwatch_log_group` - The log groups, keyed by log type (`slow-log`, `engine-log`), each with its `name`, `arn` and `retention_in_days`, or `null` when no logs are published.
  EOT
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

    # One entry per resource. Resources that are not created are null.
    cloudwatch_log_group            = local.output_resources.cloudwatch_log_group
    elasticache_replication_group   = local.output_resources.elasticache_replication_group
    security_group                  = local.output_resources.security_group
    vpc_security_group_ingress_rule = local.output_resources.vpc_security_group_ingress_rule
  }
}

locals {
  # Each resource's attributes are listed one by one. Referencing a whole resource, or
  # iterating over it, would also reference its deprecated and sensitive attributes, and
  # every caller's plan would print deprecation warnings or the output would become
  # sensitive. Keyed resources are indexed from the inputs for the same reason.
  # user_group_ids is left out: with no user groups, provider 6.0.0 saves it as null and
  # reads it back as [], so the first plan after a create showed the output changing
  # (seen in AWS). The IDs are in var.user_group_ids.
  output_resources = {
    elasticache_replication_group = {
      apply_immediately              = aws_elasticache_replication_group.this.apply_immediately
      arn                            = aws_elasticache_replication_group.this.arn
      at_rest_encryption_enabled     = aws_elasticache_replication_group.this.at_rest_encryption_enabled
      auth_token_update_strategy     = aws_elasticache_replication_group.this.auth_token_update_strategy
      auto_minor_version_upgrade     = aws_elasticache_replication_group.this.auto_minor_version_upgrade
      automatic_failover_enabled     = aws_elasticache_replication_group.this.automatic_failover_enabled
      cluster_enabled                = aws_elasticache_replication_group.this.cluster_enabled
      cluster_mode                   = aws_elasticache_replication_group.this.cluster_mode
      configuration_endpoint_address = aws_elasticache_replication_group.this.configuration_endpoint_address
      data_tiering_enabled           = aws_elasticache_replication_group.this.data_tiering_enabled
      description                    = aws_elasticache_replication_group.this.description
      engine                         = aws_elasticache_replication_group.this.engine
      engine_version                 = aws_elasticache_replication_group.this.engine_version
      engine_version_actual          = aws_elasticache_replication_group.this.engine_version_actual
      final_snapshot_identifier      = aws_elasticache_replication_group.this.final_snapshot_identifier
      global_replication_group_id    = aws_elasticache_replication_group.this.global_replication_group_id
      id                             = aws_elasticache_replication_group.this.id
      ip_discovery                   = aws_elasticache_replication_group.this.ip_discovery
      kms_key_id                     = aws_elasticache_replication_group.this.kms_key_id
      log_delivery_configuration     = aws_elasticache_replication_group.this.log_delivery_configuration
      maintenance_window             = aws_elasticache_replication_group.this.maintenance_window
      member_clusters                = aws_elasticache_replication_group.this.member_clusters
      multi_az_enabled               = aws_elasticache_replication_group.this.multi_az_enabled
      network_type                   = aws_elasticache_replication_group.this.network_type
      node_type                      = aws_elasticache_replication_group.this.node_type
      notification_topic_arn         = aws_elasticache_replication_group.this.notification_topic_arn
      num_cache_clusters             = aws_elasticache_replication_group.this.num_cache_clusters
      num_node_groups                = aws_elasticache_replication_group.this.num_node_groups
      parameter_group_name           = aws_elasticache_replication_group.this.parameter_group_name
      port                           = aws_elasticache_replication_group.this.port
      preferred_cache_cluster_azs    = aws_elasticache_replication_group.this.preferred_cache_cluster_azs
      primary_endpoint_address       = aws_elasticache_replication_group.this.primary_endpoint_address
      reader_endpoint_address        = aws_elasticache_replication_group.this.reader_endpoint_address
      region                         = aws_elasticache_replication_group.this.region
      replicas_per_node_group        = aws_elasticache_replication_group.this.replicas_per_node_group
      replication_group_id           = aws_elasticache_replication_group.this.replication_group_id
      security_group_ids             = aws_elasticache_replication_group.this.security_group_ids
      security_group_names           = aws_elasticache_replication_group.this.security_group_names
      snapshot_arns                  = aws_elasticache_replication_group.this.snapshot_arns
      snapshot_name                  = aws_elasticache_replication_group.this.snapshot_name
      snapshot_retention_limit       = aws_elasticache_replication_group.this.snapshot_retention_limit
      snapshot_window                = aws_elasticache_replication_group.this.snapshot_window
      subnet_group_name              = aws_elasticache_replication_group.this.subnet_group_name
      tags                           = aws_elasticache_replication_group.this.tags
      tags_all                       = aws_elasticache_replication_group.this.tags_all
      transit_encryption_enabled     = aws_elasticache_replication_group.this.transit_encryption_enabled
      transit_encryption_mode        = aws_elasticache_replication_group.this.transit_encryption_mode
    }
    security_group = {
      arn                    = aws_security_group.this.arn
      description            = aws_security_group.this.description
      id                     = aws_security_group.this.id
      name                   = aws_security_group.this.name
      name_prefix            = aws_security_group.this.name_prefix
      owner_id               = aws_security_group.this.owner_id
      region                 = aws_security_group.this.region
      revoke_rules_on_delete = aws_security_group.this.revoke_rules_on_delete
      tags                   = aws_security_group.this.tags
      tags_all               = aws_security_group.this.tags_all
      vpc_id                 = aws_security_group.this.vpc_id
    }
    vpc_security_group_ingress_rule = length(var.security_group_ingress) == 0 ? null : {
      for k in keys(var.security_group_ingress) : k => {
        arn                          = aws_vpc_security_group_ingress_rule.this[k].arn
        cidr_ipv4                    = aws_vpc_security_group_ingress_rule.this[k].cidr_ipv4
        cidr_ipv6                    = aws_vpc_security_group_ingress_rule.this[k].cidr_ipv6
        description                  = aws_vpc_security_group_ingress_rule.this[k].description
        from_port                    = aws_vpc_security_group_ingress_rule.this[k].from_port
        id                           = aws_vpc_security_group_ingress_rule.this[k].id
        ip_protocol                  = aws_vpc_security_group_ingress_rule.this[k].ip_protocol
        prefix_list_id               = aws_vpc_security_group_ingress_rule.this[k].prefix_list_id
        referenced_security_group_id = aws_vpc_security_group_ingress_rule.this[k].referenced_security_group_id
        region                       = aws_vpc_security_group_ingress_rule.this[k].region
        security_group_id            = aws_vpc_security_group_ingress_rule.this[k].security_group_id
        security_group_rule_id       = aws_vpc_security_group_ingress_rule.this[k].security_group_rule_id
        tags                         = aws_vpc_security_group_ingress_rule.this[k].tags
        tags_all                     = aws_vpc_security_group_ingress_rule.this[k].tags_all
        to_port                      = aws_vpc_security_group_ingress_rule.this[k].to_port
      }
    }
    cloudwatch_log_group = length(local.cloudwatch_log_groups) == 0 ? null : {
      for k in keys(local.cloudwatch_log_groups) : k => {
        arn               = aws_cloudwatch_log_group.this[k].arn
        id                = aws_cloudwatch_log_group.this[k].id
        kms_key_id        = aws_cloudwatch_log_group.this[k].kms_key_id
        log_group_class   = aws_cloudwatch_log_group.this[k].log_group_class
        name              = aws_cloudwatch_log_group.this[k].name
        name_prefix       = aws_cloudwatch_log_group.this[k].name_prefix
        region            = aws_cloudwatch_log_group.this[k].region
        retention_in_days = aws_cloudwatch_log_group.this[k].retention_in_days
        skip_destroy      = aws_cloudwatch_log_group.this[k].skip_destroy
        tags              = aws_cloudwatch_log_group.this[k].tags
        tags_all          = aws_cloudwatch_log_group.this[k].tags_all
      }
    }
  }
}
