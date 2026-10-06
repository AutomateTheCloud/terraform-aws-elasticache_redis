# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_elasticache_replication_group" {
    defaults = {
      arn                      = "arn:aws:elasticache:us-east-1:111111111111:replicationgroup:app-cache"
      primary_endpoint_address = "master.app-cache.abcdef.use1.cache.amazonaws.com"
      reader_endpoint_address  = "replica.app-cache.abcdef.use1.cache.amazonaws.com"
    }
  }
  mock_resource "aws_security_group" {
    defaults = { id = "sg-0000000000000000d" }
  }
}

mock_provider "random" {}

variables {
  details           = { scope = "Test", purpose = "App Cache", environment = "test" }
  name              = "app-cache"
  node_type         = "cache.t4g.micro"
  vpc_id            = "vpc-0123456789abcdef0"
  subnet_group_name = "private"
}

run "cluster_mode_enabled" {
  command = plan
  variables {
    cluster_mode            = "enabled"
    num_node_groups         = 3
    replicas_per_node_group = 2
  }
  assert {
    condition     = aws_elasticache_replication_group.this.cluster_mode == "enabled" && aws_elasticache_replication_group.this.num_node_groups == 3 && aws_elasticache_replication_group.this.replicas_per_node_group == 2
    error_message = "Cluster mode settings must reach the cache."
  }
}

run "no_replicas_no_failover" {
  command = plan
  variables {
    replicas_per_node_group = 0
    multi_az_enabled        = false
  }
  assert {
    condition     = aws_elasticache_replication_group.this.automatic_failover_enabled == false && aws_elasticache_replication_group.this.multi_az_enabled == false
    error_message = "A single node cannot fail over."
  }
}

run "cluster_mode_without_replicas_keeps_failover" {
  command = plan
  variables {
    cluster_mode            = "enabled"
    num_node_groups         = 2
    replicas_per_node_group = 0
    multi_az_enabled        = false
  }
  assert {
    condition     = aws_elasticache_replication_group.this.automatic_failover_enabled == true
    error_message = "Cluster mode requires automatic failover."
  }
}

run "valkey_customer_key_and_options" {
  command = apply
  variables {
    engine                        = "valkey"
    engine_version                = "8.2"
    port                          = 6380
    parameter_group_name          = "default.valkey8"
    kms_key_id                    = "arn:aws:kms:us-east-1:111111111111:key/1111"
    network_type                  = "dual_stack"
    ip_discovery                  = "ipv6"
    maintenance                   = { window = "sun:05:00-sun:06:00", auto_minor_version_upgrade = false, apply_immediately = true }
    snapshot                      = { retention_limit = 0, window = "03:00-04:00", final_snapshot = false, restore_from = "old-cache-snapshot" }
    additional_security_group_ids = ["sg-0123456789abcdef0"]
    timeouts                      = { create = "90m" }
  }
  assert {
    condition = alltrue([
      aws_elasticache_replication_group.this.engine == "valkey",
      aws_elasticache_replication_group.this.engine_version == "8.2",
      aws_elasticache_replication_group.this.port == 6380,
      aws_elasticache_replication_group.this.parameter_group_name == "default.valkey8",
      aws_elasticache_replication_group.this.kms_key_id == "arn:aws:kms:us-east-1:111111111111:key/1111",
      aws_elasticache_replication_group.this.at_rest_encryption_enabled == "true",
      aws_elasticache_replication_group.this.network_type == "dual_stack",
      aws_elasticache_replication_group.this.ip_discovery == "ipv6",
      aws_elasticache_replication_group.this.maintenance_window == "sun:05:00-sun:06:00",
      aws_elasticache_replication_group.this.auto_minor_version_upgrade == "false",
      aws_elasticache_replication_group.this.apply_immediately == true,
      aws_elasticache_replication_group.this.snapshot_retention_limit == 0,
      aws_elasticache_replication_group.this.snapshot_window == "03:00-04:00",
      aws_elasticache_replication_group.this.final_snapshot_identifier == null,
      aws_elasticache_replication_group.this.snapshot_name == "old-cache-snapshot",
      aws_elasticache_replication_group.this.timeouts.create == "90m",
      aws_elasticache_replication_group.this.timeouts.update == "120m",
    ])
    error_message = "An option did not reach the cache."
  }
  assert {
    condition     = length(aws_elasticache_replication_group.this.security_group_ids) == 2 && contains(aws_elasticache_replication_group.this.security_group_ids, "sg-0123456789abcdef0")
    error_message = "The additional security group must be attached."
  }
}

run "ingress_rules_on_the_port" {
  command = plan
  variables {
    port = 6380
    security_group_ingress = {
      app    = { security_group_id = "sg-0aaaaaaaaaaaaaaaa", description = "Application servers" }
      vpc    = { cidr_ipv4 = "10.0.0.0/16" }
      vpc6   = { cidr_ipv6 = "2600:1f18:1234:5600::/56" }
      office = { prefix_list_id = "pl-0123456789abcdef0" }
    }
  }
  assert {
    condition     = alltrue([for r in aws_vpc_security_group_ingress_rule.this : r.from_port == 6380 && r.to_port == 6380 && r.ip_protocol == "tcp"])
    error_message = "Rules must allow only the cache port over TCP."
  }
  assert {
    condition = alltrue([
      aws_vpc_security_group_ingress_rule.this["app"].referenced_security_group_id == "sg-0aaaaaaaaaaaaaaaa",
      aws_vpc_security_group_ingress_rule.this["app"].description == "Application servers",
      aws_vpc_security_group_ingress_rule.this["vpc"].cidr_ipv4 == "10.0.0.0/16",
      aws_vpc_security_group_ingress_rule.this["vpc"].description == "vpc",
      aws_vpc_security_group_ingress_rule.this["vpc6"].cidr_ipv6 == "2600:1f18:1234:5600::/56",
      aws_vpc_security_group_ingress_rule.this["office"].prefix_list_id == "pl-0123456789abcdef0",
    ])
    error_message = "Each source must reach its own argument."
  }
}

run "logs_options" {
  command = plan
  variables {
    cloudwatch_logs = { log_types = ["slow-log"], log_format = "json", retention_in_days = 30, kms_key_id = "arn:aws:kms:us-east-1:111111111111:key/2222" }
  }
  assert {
    condition     = keys(aws_cloudwatch_log_group.this) == ["slow-log"] && aws_cloudwatch_log_group.this["slow-log"].retention_in_days == 30 && aws_cloudwatch_log_group.this["slow-log"].kms_key_id == "arn:aws:kms:us-east-1:111111111111:key/2222"
    error_message = "Log group options must be applied."
  }
  assert {
    condition     = [for c in aws_elasticache_replication_group.this.log_delivery_configuration : "${c.log_type}|${c.log_format}"] == ["slow-log|json"]
    error_message = "Only the slow log, as JSON, must be delivered."
  }
}

run "no_logs" {
  command = apply
  variables {
    cloudwatch_logs = { log_types = [] }
  }
  assert {
    condition     = length(aws_cloudwatch_log_group.this) == 0 && length(aws_elasticache_replication_group.this.log_delivery_configuration) == 0 && output.metadata.cloudwatch_log_group == null
    error_message = "No log groups or delivery without log types."
  }
}

run "transit_preferred" {
  command = plan
  variables {
    transit_encryption = { mode = "preferred" }
  }
  assert {
    condition     = aws_elasticache_replication_group.this.transit_encryption_enabled == true && aws_elasticache_replication_group.this.transit_encryption_mode == "preferred"
    error_message = "Preferred mode must reach the cache."
  }
}

run "transit_off" {
  command = plan
  variables {
    transit_encryption = { enabled = false }
  }
  assert {
    condition     = aws_elasticache_replication_group.this.transit_encryption_enabled == false
    error_message = "Transit encryption must be off."
  }
}

run "user_groups" {
  command = plan
  variables {
    user_group_ids = ["app-users"]
  }
  assert {
    condition     = aws_elasticache_replication_group.this.user_group_ids == toset(["app-users"])
    error_message = "The user group must reach the cache."
  }
}

# The token is sensitive. metadata must stay non-sensitive, or every caller's plan
# would fail with "Output refers to sensitive values"; this run would fail the same way.
run "auth_token_keeps_metadata_non_sensitive" {
  command = apply
  variables {
    auth_token                 = "correct-horse-battery-staple"
    auth_token_update_strategy = "SET"
  }
  assert {
    condition     = aws_elasticache_replication_group.this.auth_token == "correct-horse-battery-staple" && aws_elasticache_replication_group.this.auth_token_update_strategy == "SET"
    error_message = "The token and strategy must reach the cache."
  }
  assert {
    condition     = !issensitive(output.metadata.elasticache_replication_group.id)
    error_message = "metadata must not be sensitive."
  }
}
