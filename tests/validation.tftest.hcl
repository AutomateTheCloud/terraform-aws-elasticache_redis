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

# Each invalid value fails the plan with the variable's own message.

run "name_uppercase" {
  command = plan
  variables {
    name = "App-Cache"
  }
  expect_failures = [var.name]
}

run "name_too_long" {
  command = plan
  variables {
    name = "a23456789012345678901234567890123456789012"
  }
  expect_failures = [var.name]
}

run "name_double_hyphen" {
  command = plan
  variables {
    name = "app--cache"
  }
  expect_failures = [var.name]
}

run "name_trailing_hyphen" {
  command = plan
  variables {
    name = "app-"
  }
  expect_failures = [var.name]
}

run "name_leading_digit" {
  command = plan
  variables {
    name = "1app"
  }
  expect_failures = [var.name]
}

run "node_type" {
  command = plan
  variables {
    node_type = "t4g.micro"
  }
  expect_failures = [var.node_type]
}

run "vpc_id" {
  command = plan
  variables {
    vpc_id = "0123456789abcdef0"
  }
  expect_failures = [var.vpc_id]
}

run "subnet_group_empty" {
  command = plan
  variables {
    subnet_group_name = " "
  }
  expect_failures = [var.subnet_group_name]
}

run "details_scope_empty" {
  command = plan
  variables {
    details = { scope = "", purpose = "P", environment = "E" }
  }
  expect_failures = [var.details]
}

run "details_purpose_empty" {
  command = plan
  variables {
    details = { scope = "S", purpose = " ", environment = "E" }
  }
  expect_failures = [var.details]
}

run "details_environment_empty" {
  command = plan
  variables {
    details = { scope = "S", purpose = "P", environment = "" }
  }
  expect_failures = [var.details]
}

run "engine" {
  command = plan
  variables {
    engine = "memcached"
  }
  expect_failures = [var.engine]
}

run "engine_version_patch" {
  command = plan
  variables {
    engine_version = "7.1.0"
  }
  expect_failures = [var.engine_version]
}

run "cluster_mode" {
  command = plan
  variables {
    cluster_mode = "on"
  }
  expect_failures = [var.cluster_mode]
}

run "disabled_needs_one_shard" {
  command = plan
  variables {
    num_node_groups = 2
  }
  expect_failures = [var.num_node_groups]
}

run "num_node_groups_zero" {
  command = plan
  variables {
    num_node_groups = 0
    cluster_mode    = "enabled"
  }
  expect_failures = [var.num_node_groups]
}

run "num_node_groups_fraction" {
  command = plan
  variables {
    num_node_groups = 1.5
    cluster_mode    = "enabled"
  }
  expect_failures = [var.num_node_groups]
}

run "replicas_six" {
  command = plan
  variables {
    replicas_per_node_group = 6
  }
  expect_failures = [var.replicas_per_node_group]
}

run "multi_az_needs_replica" {
  command = plan
  variables {
    replicas_per_node_group = 0
  }
  expect_failures = [var.multi_az_enabled]
}

run "port_zero" {
  command = plan
  variables {
    port = 0
  }
  expect_failures = [var.port]
}

run "port_too_high" {
  command = plan
  variables {
    port = 65536
  }
  expect_failures = [var.port]
}

run "network_type" {
  command = plan
  variables {
    network_type = "ipv4_ipv6"
  }
  expect_failures = [var.network_type]
}

run "ip_discovery_value" {
  command = plan
  variables {
    ip_discovery = "dual"
  }
  expect_failures = [var.ip_discovery]
}

run "ip_discovery_needs_ipv6_network" {
  command = plan
  variables {
    ip_discovery = "ipv6"
  }
  expect_failures = [var.ip_discovery]
}

run "kms_key_not_arn" {
  command = plan
  variables {
    kms_key_id = "1234abcd-12ab-34cd-56ef-1234567890ab"
  }
  expect_failures = [var.kms_key_id]
}

run "auth_token_short" {
  command = plan
  variables {
    auth_token = "too-short"
  }
  expect_failures = [var.auth_token]
}

run "auth_token_at_sign" {
  command = plan
  variables {
    auth_token = "correct-horse@battery-staple"
  }
  expect_failures = [var.auth_token]
}

run "auth_token_space" {
  command = plan
  variables {
    auth_token = "correct horse battery staple"
  }
  expect_failures = [var.auth_token]
}

run "auth_token_needs_tls" {
  command = plan
  variables {
    auth_token         = "correct-horse-battery-staple"
    transit_encryption = { enabled = false }
  }
  expect_failures = [var.auth_token]
}

run "auth_token_and_user_groups" {
  command = plan
  variables {
    auth_token     = "correct-horse-battery-staple"
    user_group_ids = ["app-users"]
  }
  expect_failures = [var.auth_token]
}

run "auth_token_update_strategy" {
  command = plan
  variables {
    auth_token_update_strategy = "DELETE"
  }
  expect_failures = [var.auth_token_update_strategy]
}

run "user_groups_two" {
  command = plan
  variables {
    user_group_ids = ["a", "b"]
  }
  expect_failures = [var.user_group_ids]
}

run "user_groups_need_tls" {
  command = plan
  variables {
    user_group_ids     = ["a"]
    transit_encryption = { enabled = false }
  }
  expect_failures = [var.user_group_ids]
}

run "transit_mode" {
  command = plan
  variables {
    transit_encryption = { mode = "optional" }
  }
  expect_failures = [var.transit_encryption]
}

run "additional_sg" {
  command = plan
  variables {
    additional_security_group_ids = ["default"]
  }
  expect_failures = [var.additional_security_group_ids]
}

run "ingress_two_sources" {
  command = plan
  variables {
    security_group_ingress = { x = { cidr_ipv4 = "10.0.0.0/8", prefix_list_id = "pl-0123456789abcdef0" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_no_source" {
  command = plan
  variables {
    security_group_ingress = { x = { description = "nothing" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_bad_ipv4" {
  command = plan
  variables {
    security_group_ingress = { x = { cidr_ipv4 = "10.0.0.0" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_ipv6_in_ipv4" {
  command = plan
  variables {
    security_group_ingress = { x = { cidr_ipv4 = "2600:1f18::/56" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_ipv4_in_ipv6" {
  command = plan
  variables {
    security_group_ingress = { x = { cidr_ipv6 = "10.0.0.0/8" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "logs_type" {
  command = plan
  variables {
    cloudwatch_logs = { log_types = ["audit-log"] }
  }
  expect_failures = [var.cloudwatch_logs]
}

run "logs_duplicate" {
  command = plan
  variables {
    cloudwatch_logs = { log_types = ["slow-log", "slow-log"] }
  }
  expect_failures = [var.cloudwatch_logs]
}

run "logs_format" {
  command = plan
  variables {
    cloudwatch_logs = { log_format = "yaml" }
  }
  expect_failures = [var.cloudwatch_logs]
}

run "logs_retention" {
  command = plan
  variables {
    cloudwatch_logs = { retention_in_days = 10 }
  }
  expect_failures = [var.cloudwatch_logs]
}

run "logs_kms" {
  command = plan
  variables {
    cloudwatch_logs = { kms_key_id = "alias/logs" }
  }
  expect_failures = [var.cloudwatch_logs]
}

run "maintenance_window" {
  command = plan
  variables {
    maintenance = { window = "Sun:05:00-Sun:06:00" }
  }
  expect_failures = [var.maintenance]
}

run "snapshot_retention" {
  command = plan
  variables {
    snapshot = { retention_limit = 36 }
  }
  expect_failures = [var.snapshot]
}

run "snapshot_window" {
  command = plan
  variables {
    snapshot = { window = "3:00-4:00" }
  }
  expect_failures = [var.snapshot]
}

run "auth_token_too_long" {
  command = plan
  variables {
    auth_token = "!#$%&'()*+,-.0123456789:;<=>?ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~!#$%&'()*+,-.0123456789:;<=>?ABCDEFGHA"
  }
  expect_failures = [var.auth_token]
}

# The limits themselves are accepted.
run "boundaries_accepted" {
  command = plan
  variables {
    name                    = "a234567890123456789012345678901234567890"
    port                    = 1
    replicas_per_node_group = 5
    auth_token              = "!#$%&'()*+,-.0123456789:;<=>?ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~!#$%&'()*+,-.0123456789:;<=>?ABCDEFGH"
    snapshot                = { retention_limit = 35 }
    cloudwatch_logs         = { retention_in_days = 0 }
  }
  assert {
    condition     = length(aws_elasticache_replication_group.this.replication_group_id) == 40
    error_message = "A 40-character name must be accepted."
  }
}

run "cluster_mode_many_shards_accepted" {
  command = plan
  variables {
    cluster_mode            = "enabled"
    num_node_groups         = 500
    replicas_per_node_group = 0
    multi_az_enabled        = false
  }
}
