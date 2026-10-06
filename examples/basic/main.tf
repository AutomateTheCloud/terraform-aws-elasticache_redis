# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A private, encrypted Redis OSS cache in the subnets you give: one primary and one
# replica in another Availability Zone, TLS required, reachable on its port from
# anywhere in the VPC.

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

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_elasticache_subnet_group" "this" {
  name        = "example-basic"
  description = "Private subnets for the example-basic cache"
  subnet_ids  = var.subnet_ids
}

module "elasticache_redis" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "App Cache"
    environment = "Development"
  }

  name              = "example-basic"
  node_type         = "cache.t4g.micro"
  vpc_id            = var.vpc_id
  subnet_group_name = aws_elasticache_subnet_group.this.name

  security_group_ingress = {
    vpc = { cidr_ipv4 = data.aws_vpc.this.cidr_block, description = "Anything in the VPC" }
  }
}

output "cache" {
  description = "Where to connect: the primary endpoint for reads and writes, the reader endpoint for reads, and the port"
  value = {
    primary_endpoint = module.elasticache_redis.metadata.elasticache_replication_group.primary_endpoint_address
    reader_endpoint  = module.elasticache_redis.metadata.elasticache_replication_group.reader_endpoint_address
    port             = module.elasticache_redis.metadata.elasticache_replication_group.port
  }
}
