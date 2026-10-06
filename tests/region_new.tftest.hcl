# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "ap-southeast-7", description = "Asia Pacific (Thailand)" }
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

# Any Region plans, including ones added after this module was written.
run "region_not_in_old_tables" {
  command = plan
  variables { region = "ap-southeast-7" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7" && aws_elasticache_replication_group.this.description == "Test - App Cache [test] (ap-southeast-7): ElastiCache app-cache"
    error_message = "Unexpected abbreviation."
  }
}
