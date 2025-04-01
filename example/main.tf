terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: ElastiCache - Redis
module "elasticache-redis" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope               = "Demo"
    purpose             = "ElastiCache - Redis"
    environment         = "dev"
    additional_tags = {
      "Project"         = "Project Name"
      "ProjectID"       = "123456789"
      "Contact"         = "David Singer - david.singer@example.com"
    }
  }

  name           = "test-dev"
  engine         = "valkey"
  engine_version = "8.0"
  port    = 6379

  node_type = "cache.t4g.medium"

  cluster_mode = "disabled"
  multi_az_enabled = true
  automatic_failover_enabled = true
  network_type = "ipv4"
  ip_discovery = "ipv4"

  # num_cache_clusters = 2
  num_node_groups = 1
  replicas_per_node_group = 3

  data_tiering_enabled = false

  encryption = {
    kms_key_id = "arn:aws:kms:us-east-1:012345678901:key/01234567-2fc2-4ed5-b884-287af36b7df5"
    transit = {
      encryption_enabled = false
      # encryption_mode = "preferred"
    }
  }

  security_group_rules = [
    # {
      # source      = "sg-00000000000000001"
      # description = "Security Group Test"
    # },
    {
      source      = "10.0.0.0/8"
      description = "CIDR Test"
    }
  ]
  cloudwatch = {
    retention  = 7
    log_format = "text"
  }

  snapshot = {
    retention_limit  = 7
    window           = "04:00-05:30"
  }

  maintenance = {
    window                     = "tue:06:00-tue:08:00"
    auto_minor_version_upgrade = true
    apply_immediately          = true
  }

  parameter_group_name = "default.valkey8"

  vpc_id            = "vpc-00000000000000001"
  subnet_group_name = "vpc-elasticache-restricted-use1"
}

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value = module.elasticache-redis.metadata
}
