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

run "defaults_are_secure" {
  command = apply

  assert {
    condition     = aws_elasticache_replication_group.this.at_rest_encryption_enabled == "true"
    error_message = "Data at rest must be encrypted."
  }
  assert {
    condition     = aws_elasticache_replication_group.this.transit_encryption_enabled == true && aws_elasticache_replication_group.this.transit_encryption_mode == "required"
    error_message = "TLS must be on and required."
  }
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 0
    error_message = "No client may connect until security_group_ingress names it."
  }
  assert {
    condition     = output.metadata.vpc_security_group_ingress_rule == null
    error_message = "metadata.vpc_security_group_ingress_rule must be null without rules."
  }
  assert {
    condition     = aws_elasticache_replication_group.this.security_group_ids == toset([aws_security_group.this.id])
    error_message = "Only the module's security group is attached by default."
  }
  assert {
    condition     = aws_elasticache_replication_group.this.snapshot_retention_limit == 7
    error_message = "Automatic snapshots must be kept 7 days by default."
  }
  assert {
    condition     = aws_elasticache_replication_group.this.final_snapshot_identifier == "app-cache-final-${random_id.final_snapshot.hex}"
    error_message = "A final snapshot must be taken by default."
  }
}

run "default_topology_is_multi_az_with_one_replica" {
  command = plan

  assert {
    condition = alltrue([
      aws_elasticache_replication_group.this.cluster_mode == "disabled",
      aws_elasticache_replication_group.this.num_node_groups == 1,
      aws_elasticache_replication_group.this.replicas_per_node_group == 1,
      aws_elasticache_replication_group.this.automatic_failover_enabled == true,
      aws_elasticache_replication_group.this.multi_az_enabled == true,
    ])
    error_message = "Expected one shard with one replica, Multi-AZ and automatic failover."
  }
  assert {
    condition     = aws_elasticache_replication_group.this.engine == "redis" && aws_elasticache_replication_group.this.port == 6379
    error_message = "Expected Redis OSS on port 6379."
  }
  assert {
    condition     = aws_elasticache_replication_group.this.auth_token == null && aws_elasticache_replication_group.this.auth_token_update_strategy == null && aws_elasticache_replication_group.this.kms_key_id == null
    error_message = "No auth token, no update strategy (the provider refuses one without a token) and no customer key by default."
  }
}

run "default_logs" {
  command = plan

  assert {
    condition     = toset(keys(aws_cloudwatch_log_group.this)) == toset(["slow-log", "engine-log"])
    error_message = "Both log types are published by default."
  }
  assert {
    condition     = aws_cloudwatch_log_group.this["slow-log"].name == "/aws/elasticache/app-cache/slow-log" && aws_cloudwatch_log_group.this["slow-log"].retention_in_days == 7
    error_message = "Unexpected log group name or retention."
  }
  assert {
    condition     = toset([for c in aws_elasticache_replication_group.this.log_delivery_configuration : "${c.log_type}|${c.destination}|${c.log_format}|${c.destination_type}"]) == toset(["slow-log|/aws/elasticache/app-cache/slow-log|text|cloudwatch-logs", "engine-log|/aws/elasticache/app-cache/engine-log|text|cloudwatch-logs"])
    error_message = "Log delivery must point at the module's log groups."
  }
}

run "names_and_tags" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.this.description == "Test - App Cache [test] (us-east-1): ElastiCache app-cache"
    error_message = "Unexpected description."
  }
  assert {
    condition     = aws_security_group.this.name_prefix == "elasticache-app-cache-" && aws_security_group.this.tags["Name"] == "elasticache-app-cache"
    error_message = "Unexpected security group name."
  }
  assert {
    condition     = aws_elasticache_replication_group.this.tags == tomap({ Scope = "Test", Purpose = "App Cache", Environment = "test" })
    error_message = "Unexpected tags."
  }
  assert {
    condition     = output.metadata.details.purpose.abbr == "app_cache" && output.metadata.details.purpose.machine == "appcache" && output.metadata.aws.region.abbr == "use1"
    error_message = "Unexpected details forms."
  }
}

run "metadata_after_apply" {
  command = apply

  assert {
    condition     = output.metadata.elasticache_replication_group.primary_endpoint_address == "master.app-cache.abcdef.use1.cache.amazonaws.com"
    error_message = "metadata must carry the endpoint."
  }
  assert {
    condition     = output.metadata.security_group.id == "sg-0000000000000000d" && output.metadata.aws.account.id == "111111111111"
    error_message = "metadata must carry the security group and the account."
  }
  assert {
    condition     = output.metadata.cloudwatch_log_group["engine-log"].name == "/aws/elasticache/app-cache/engine-log"
    error_message = "metadata must carry the log groups."
  }
}
