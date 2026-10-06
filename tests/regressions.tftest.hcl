# Copyright 2026 Automate the Cloud Inc.
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

# Bugs in the module before 1.0.0, each with the input that showed it.

# security_group_rules defaulted to null, and every plan without rules failed with
# "Iteration over null value".
run "plans_with_no_ingress" {
  command = plan
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 0
    error_message = "A plan with no ingress must succeed and create no rules."
  }
}

# The transit_encryption_enabled, transit_encryption_mode and apply_immediately inputs
# were never read, so TLS was off unless set under another name, and at-rest encryption
# was on only with a customer key.
run "encryption_on_without_extra_inputs" {
  command = plan
  assert {
    condition     = aws_elasticache_replication_group.this.transit_encryption_enabled == true && aws_elasticache_replication_group.this.at_rest_encryption_enabled == "true"
    error_message = "Encryption at rest and in transit must be on by default."
  }
}

# An IPv6 source was sent as a security group ID.
run "ipv6_source_is_a_cidr" {
  command = plan
  variables {
    security_group_ingress = { v6 = { cidr_ipv6 = "2600:1f18:1234:5600::/56" } }
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["v6"].cidr_ipv6 == "2600:1f18:1234:5600::/56" && aws_vpc_security_group_ingress_rule.this["v6"].referenced_security_group_id == null
    error_message = "An IPv6 range must be sent as cidr_ipv6."
  }
}

# Every ingress rule had a matching egress rule to the client, which the cache never needs.
run "no_egress_rules" {
  command = plan
  variables {
    security_group_ingress = { vpc = { cidr_ipv4 = "10.0.0.0/16" } }
  }
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 1
    error_message = "Only the ingress rule is created."
  }
}

# The log group names contained the engine, so moving from Redis OSS to Valkey would
# have replaced them and deleted their log events.
run "log_group_names_do_not_depend_on_engine" {
  command = plan
  variables {
    engine = "valkey"
  }
  assert {
    condition     = aws_cloudwatch_log_group.this["engine-log"].name == "/aws/elasticache/app-cache/engine-log"
    error_message = "Log group names must not contain the engine."
  }
}

run "create_with_old_version" {
  command = apply
  variables {
    engine_version = "7.0"
  }
}

# engine_version was in ignore_changes, so an upgrade planned no change.
run "engine_version_change_is_planned" {
  command = plan
  variables {
    engine_version = "7.1"
  }
  assert {
    condition     = aws_elasticache_replication_group.this.engine_version == "7.1"
    error_message = "A new engine_version must be planned."
  }
}

# The final snapshot's suffix changed only with the name, so a cache replaced by another
# change (here the port) kept it, and deleting the replacement failed with
# SnapshotAlreadyExistsFault: the old cache's final snapshot already had that name.
run "replacement_gets_a_new_final_snapshot_name" {
  command = plan
  variables {
    engine_version = "7.1"
    port           = 6380
  }
  assert {
    condition     = random_id.final_snapshot.keepers["port"] == "6380"
    error_message = "A replacing input must change the final snapshot's suffix."
  }
}
