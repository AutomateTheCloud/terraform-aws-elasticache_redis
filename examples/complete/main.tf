# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A Valkey cache for production use: cluster mode with two shards, each with a replica
# in another Availability Zone, a customer managed KMS key, a parameter group, logs in
# CloudWatch as JSON, access only from the application's security group, and sign-in
# with AWS Identity and Access Management (IAM) instead of a password.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC to create the cache in"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of private subnets for the cache, in at least two Availability Zones"
  type        = list(string)
}

locals {
  name = "example-complete"
}

# The key that encrypts the cache's data at rest and its snapshots. Its default key
# policy lets IAM principals in this account use it, which ElastiCache needs.
resource "aws_kms_key" "this" {
  description             = "${local.name} cache"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_elasticache_subnet_group" "this" {
  name        = local.name
  description = "Private subnets for the ${local.name} cache"
  subnet_ids  = var.subnet_ids
}

# Engine settings. A cache in cluster mode needs a parameter group with
# cluster-enabled set to yes.
resource "aws_elasticache_parameter_group" "this" {
  name   = "${local.name}-valkey8"
  family = "valkey8"

  parameter {
    name  = "cluster-enabled"
    value = "yes"
  }

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
}

# Who may sign in. The application signs in as this user with an IAM authentication
# token, so no password is stored anywhere; its IAM role needs elasticache:Connect on
# the cache and on this user. AWS requires the user ID and name to be the same for IAM
# users. A Valkey user group needs no "default" user, so clients that do not sign in
# get no access.
resource "aws_elasticache_user" "app" {
  user_id       = "${local.name}-app"
  user_name     = "${local.name}-app"
  engine        = "valkey"
  access_string = "on ~* +@all -@dangerous"

  authentication_mode {
    type = "iam"
  }
}

resource "aws_elasticache_user_group" "this" {
  user_group_id = local.name
  engine        = "valkey"
  user_ids      = [aws_elasticache_user.app.user_id]
}

# The application servers' group. Only its members may connect to the cache.
resource "aws_security_group" "app" {
  name_prefix = "${local.name}-app-"
  description = "Application servers for ${local.name}"
  vpc_id      = var.vpc_id
}

module "elasticache_redis" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "App Cache"
    environment = "Production"
  }

  name                 = local.name
  engine               = "valkey"
  engine_version       = "8.2"
  node_type            = "cache.t4g.small"
  vpc_id               = var.vpc_id
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  parameter_group_name = aws_elasticache_parameter_group.this.name
  kms_key_id           = aws_kms_key.this.arn
  user_group_ids       = [aws_elasticache_user_group.this.user_group_id]

  cluster_mode            = "enabled"
  num_node_groups         = 2
  replicas_per_node_group = 1

  snapshot = {
    retention_limit = 14
    window          = "03:00-04:00"
  }

  maintenance = {
    window = "sun:05:00-sun:06:00"
  }

  cloudwatch_logs = {
    log_format        = "json"
    retention_in_days = 30
  }

  security_group_ingress = {
    app = { security_group_id = aws_security_group.app.id, description = "Application servers" }
  }
}

output "cache" {
  description = "Where to connect: the configuration endpoint, which cluster-mode clients use to find every shard, the port, and the IAM user name"
  value = {
    configuration_endpoint = module.elasticache_redis.metadata.elasticache_replication_group.configuration_endpoint_address
    port                   = module.elasticache_redis.metadata.elasticache_replication_group.port
    user_name              = aws_elasticache_user.app.user_name
  }
}

output "app_security_group_id" {
  description = "The security group to attach to the application servers"
  value       = aws_security_group.app.id
}
