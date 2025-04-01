# AWS - ElastiCache - Redis - Terraform Module
Terraform module for creating ElastiCache Redis compatible resources (AutomateTheCloud model)

***

## Usage
```hcl
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
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `apply_immediately` | Specifies whether any modifications are applied immediately, or during the next maintenance window | `bool` | `true` |
| `auth_token` | Password used to access a password protected server | `string` | |
| `auth_token_update_strategy` | Strategy to use when updating the auth_token (SET, ROTATE, DELETE) | `string` | |
| `automatic_failover_enabled` | Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails | `bool` | `true` |
| `cloudwatch` | Cloudwatch (TODO - Info) | `any` | |
| `cluster_mode` | Cluster Mode (enabled, disabled, compatible) | `string` | `disabled` |
| `data_tiering_enabled` | Data Tiering Enabled | `bool` | `false` |
| `encryption` | Encryption (TODO - Info) | `any` | |
| `engine` | Engine | `string` | |
| `engine_version` | Engine Version | `string` | |
| `ip_discovery` | IP version to advertise in the discovery protocol | `string` | `ipv4` |
| `maintenance` | Maintenance (TODO - Info) | `any` | |
| `multi_az_enabled` | Multi-AZ Support Enabled | `bool` | `true` |
| `name` | Name | `string` | |
| `network_type` | The IP versions for cache cluster connections | `string` | `ipv4` |
| `node_type` | Node Type | `string` | |
| `num_cache_clusters` | Number of cache clusters (primary and replicas) this replication group will have | `number` | |
| `num_node_groups` | Number of node groups (shards) for this Redis replication group | `number` | |
| `parameter_group_name` | Parameter Group Name | `string` | |
| `port` | Port | `number` | `6379` |
| `replicas_per_node_group` | Number of replica nodes in each node group | `number` | |
| `security_groups_additional` | Security Groups (Additional) | `list(any)` | `[]` |
| `security_group_rules` | Security Group Rules (TODO - Info) | `any` | |
| `snapshot` | Snapshot (TODO - Info) | `any` | |
| `subnet_group_name` | Subnet Group Name | `string` | |
| `timeouts` | Timeouts (TODO - Info) | `any` | |
| `transit_encryption_enabled` | Transit Encryption Enabled | `bool` | `true` |
| `transit_encryption_mode` | Transit Encryption Mode (preferred, required) | `string` | `preferred` |
| `user_group_id` | User Group ID | `string` | |
| `vpc_id` | VPC: ID | `string` | |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object serve? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `cloudwatch.log_group` | Cloudwatch - LogGroup |
| `elasticache.replication_group` | ElastiCache - Replication Group |
| `security_group` | Security Group |

```
metadata = {
  "aws" = {
    "account" = {
      "id" = "012345678901"
    }
    "region" = {
      "abbr" = "use1"
      "description" = "US East (N. Virginia)"
      "name" = "us-east-1"
    }
  }
  "cloudwatch" = {
    "log_group" = {
      "engine" = {
        "arn" = "arn:aws:logs:us-east-1:012345678901:log-group:/aws/elasticache/valkey/test-dev/engine"
        "id" = "/aws/elasticache/valkey/test-dev/engine"
        "kms_key_id" = ""
        "log_group_class" = "STANDARD"
        "name" = "/aws/elasticache/valkey/test-dev/engine"
        "name_prefix" = ""
        "retention_in_days" = 7
        "skip_destroy" = false
        "tags" = tomap({
          "Contact" = "David Singer - david.singer@example.com"
          "Environment" = "dev"
          "Project" = "Project Name"
          "ProjectID" = "123456789"
          "Purpose" = "ElastiCache - Redis"
          "Scope" = "Demo"
        })
        "tags_all" = tomap({
          "Contact" = "David Singer - david.singer@example.com"
          "Environment" = "dev"
          "Project" = "Project Name"
          "ProjectID" = "123456789"
          "Purpose" = "ElastiCache - Redis"
          "Scope" = "Demo"
        })
      }
      "slow" = {
        "arn" = "arn:aws:logs:us-east-1:012345678901:log-group:/aws/elasticache/valkey/test-dev/slow"
        "id" = "/aws/elasticache/valkey/test-dev/slow"
        "kms_key_id" = ""
        "log_group_class" = "STANDARD"
        "name" = "/aws/elasticache/valkey/test-dev/slow"
        "name_prefix" = ""
        "retention_in_days" = 7
        "skip_destroy" = false
        "tags" = tomap({
          "Contact" = "David Singer - david.singer@example.com"
          "Environment" = "dev"
          "Project" = "Project Name"
          "ProjectID" = "123456789"
          "Purpose" = "ElastiCache - Redis"
          "Scope" = "Demo"
        })
        "tags_all" = tomap({
          "Contact" = "David Singer - david.singer@example.com"
          "Environment" = "dev"
          "Project" = "Project Name"
          "ProjectID" = "123456789"
          "Purpose" = "ElastiCache - Redis"
          "Scope" = "Demo"
        })
      }
    }
  }
  "details" = {
    "environment" = {
      "abbr" = "dev"
      "machine" = "dev"
      "name" = "dev"
    }
    "purpose" = {
      "abbr" = "elasticache_redis"
      "machine" = "elasticacheredis"
      "name" = "ElastiCache - Redis"
    }
    "scope" = {
      "abbr" = "demo"
      "machine" = "demo"
      "name" = "Demo"
    }
    "tags" = {
      "Contact" = "David Singer - david.singer@example.com"
      "Environment" = "dev"
      "Project" = "Project Name"
      "ProjectID" = "123456789"
      "Purpose" = "ElastiCache - Redis"
      "Scope" = "Demo"
    }
  }
  "elasticache" = {
    "replication_group" = {
      "apply_immediately" = true
      "arn" = "arn:aws:elasticache:us-east-1:012345678901:replicationgroup:test-dev"
      "at_rest_encryption_enabled" = "true"
      "auth_token_update_strategy" = "ROTATE"
      "auto_minor_version_upgrade" = "true"
      "automatic_failover_enabled" = true
      "cluster_enabled" = false
      "cluster_mode" = "disabled"
      "configuration_endpoint_address" = tostring(null)
      "data_tiering_enabled" = false
      "description" = "Demo - ElastiCache - Redis [dev] (us-east-1): ElastiCache - test-dev"
      "engine" = "valkey"
      "engine_version" = "8.0"
      "engine_version_actual" = "8.0.1"
      "global_replication_group_id" = tostring(null)
      "id" = "test-dev"
      "ip_discovery" = "ipv4"
      "kms_key_id" = "arn:aws:kms:us-east-1:012345678901:key/01234567-2fc2-4ed5-b884-287af36b7df5"
      "log_delivery_configuration" = toset([
        {
          "destination" = "/aws/elasticache/valkey/test-dev/engine"
          "destination_type" = "cloudwatch-logs"
          "log_format" = "text"
          "log_type" = "engine-log"
        },
        {
          "destination" = "/aws/elasticache/valkey/test-dev/slow"
          "destination_type" = "cloudwatch-logs"
          "log_format" = "text"
          "log_type" = "slow-log"
        },
      ])
      "maintenance_window" = "tue:06:00-tue:08:00"
      "member_clusters" = toset([
        "test-dev-001",
        "test-dev-002",
        "test-dev-004",
        "test-dev-005",
      ])
      "multi_az_enabled" = true
      "network_type" = "ipv4"
      "node_type" = "cache.t4g.medium"
      "notification_topic_arn" = tostring(null)
      "num_cache_clusters" = 4
      "num_node_groups" = 1
      "parameter_group_name" = "default.valkey8"
      "port" = 6379
      "preferred_cache_cluster_azs" = tolist(null) /* of string */
      "primary_endpoint_address" = "test-dev.1psf1o.ng.0001.use1.cache.amazonaws.com"
      "reader_endpoint_address" = "test-dev-ro.1psf1o.ng.0001.use1.cache.amazonaws.com"
      "replicas_per_node_group" = 3
      "replication_group_id" = "test-dev"
      "security_group_ids" = toset([
        "sg-00000000000000001",
      ])
      "security_group_names" = toset([])
      "snapshot_retention_limit" = 7
      "snapshot_window" = "04:00-05:30"
      "subnet_group_name" = "vpc-elasticache-restricted-use1"
      "tags" = tomap({
        "Contact" = "David Singer - david.singer@example.com"
        "Environment" = "dev"
        "Project" = "Project Name"
        "ProjectID" = "123456789"
        "Purpose" = "ElastiCache - Redis"
        "Scope" = "Demo"
      })
      "tags_all" = tomap({
        "Contact" = "David Singer - david.singer@example.com"
        "Environment" = "dev"
        "Project" = "Project Name"
        "ProjectID" = "123456789"
        "Purpose" = "ElastiCache - Redis"
        "Scope" = "Demo"
      })
      "transit_encryption_enabled" = false
      "transit_encryption_mode" = ""
      "user_group_ids" = toset([])
    }
  }
  "security_group" = {
    "arn" = "arn:aws:ec2:us-east-1:012345678901:security-group/sg-00000000000000001"
    "description" = "Demo - ElastiCache - Redis [dev] (us-east-1): ElastiCache - test-dev"
    "egress" = toset([
      {
        "cidr_blocks" = tolist([
          "10.0.0.0/8",
        ])
        "description" = "CIDR Test"
        "from_port" = 6379
        "ipv6_cidr_blocks" = tolist([])
        "prefix_list_ids" = tolist([])
        "protocol" = "tcp"
        "security_groups" = toset([])
        "self" = false
        "to_port" = 6379
      },
    ])
    "id" = "sg-00000000000000001"
    "ingress" = toset([
      {
        "cidr_blocks" = tolist([
          "10.0.0.0/8",
        ])
        "description" = "CIDR Test"
        "from_port" = 6379
        "ipv6_cidr_blocks" = tolist([])
        "prefix_list_ids" = tolist([])
        "protocol" = "tcp"
        "security_groups" = toset([])
        "self" = false
        "to_port" = 6379
      },
    ])
    "name" = "elasticache-test-dev"
    "name_prefix" = ""
    "owner_id" = "012345678901"
    "revoke_rules_on_delete" = true
    "tags" = tomap({
      "Contact" = "David Singer - david.singer@example.com"
      "Environment" = "dev"
      "Name" = "elasticache-test-dev"
      "Project" = "Project Name"
      "ProjectID" = "123456789"
      "Purpose" = "ElastiCache - Redis"
      "Scope" = "Demo"
    })
    "tags_all" = tomap({
      "Contact" = "David Singer - david.singer@example.com"
      "Environment" = "dev"
      "Name" = "elasticache-test-dev"
      "Project" = "Project Name"
      "ProjectID" = "123456789"
      "Purpose" = "ElastiCache - Redis"
      "Scope" = "Demo"
    })
    "timeouts" = null /* object */
    "vpc_id" = "vpc-00000000000000001"
  }
}
```

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
