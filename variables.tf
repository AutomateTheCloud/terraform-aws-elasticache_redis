# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "additional_security_group_ids" {
  description = <<-EOT
    More security groups to attach to the cache nodes, beside the one the module creates, such as `["sg-0123456789abcdef0"]`. The module's group allows no outbound traffic; add a group here if the nodes must open connections themselves.
  EOT
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for id in var.additional_security_group_ids : startswith(id, "sg-")])
    error_message = "Each entry in additional_security_group_ids must be a security group ID, such as sg-0123456789abcdef0."
  }
}

variable "auth_token" {
  description = <<-EOT
    A password that clients must send with the `AUTH` command before any other command: 16 to 128 printable ASCII characters, without spaces, `"`, `/` or `@`. It needs `transit_encryption.enabled`. Without it, and without `user_group_ids`, any client that can reach the port can use the cache, so keep `security_group_ingress` narrow.

    The token is stored in the Terraform state, so protect the state. To change it on an existing cache, see `auth_token_update_strategy`. The AWS provider cannot remove a token from an existing cache: AWS refuses the empty token it sends.
  EOT
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.auth_token == null || can(regex("^[!#-.0-?A-~]{16,128}$", coalesce(var.auth_token, "-")))
    error_message = "auth_token must be 16 to 128 printable ASCII characters, without spaces, \", / or @."
  }

  validation {
    condition     = var.auth_token == null || var.transit_encryption.enabled
    error_message = "auth_token needs transit_encryption.enabled = true: AWS accepts a token only over TLS."
  }

  validation {
    condition     = var.auth_token == null || length(var.user_group_ids) == 0
    error_message = "Set auth_token or user_group_ids, not both: the AWS provider refuses them together."
  }
}

variable "auth_token_update_strategy" {
  description = <<-EOT
    How a change to `auth_token` is applied to an existing cache: `ROTATE`, the default, accepts both the old and the new token, so clients can move to the new one; then apply the same token with `SET` to accept only the new one. AWS refuses `SET` with a token other than the one given with `ROTATE`. Not used when the cache is created, or without `auth_token`.
  EOT
  type        = string
  default     = "ROTATE"
  nullable    = false

  validation {
    condition     = contains(["ROTATE", "SET"], var.auth_token_update_strategy)
    error_message = "auth_token_update_strategy must be ROTATE or SET."
  }
}

variable "cloudwatch_logs" {
  description = <<-EOT
    Logs to publish to Amazon CloudWatch Logs. The module creates one log group per log type, `/aws/elasticache/<name>/<log type>`, before the cache starts writing to it.

    - `log_types` - (Optional) `slow-log` (commands that took longer than the `slowlog-log-slower-than` parameter), `engine-log` (the engine's own log), both, or `[]` for none. Defaults to both.
    - `log_format` - (Optional) `text` or `json`. Defaults to `text`.
    - `retention_in_days` - (Optional) Days to keep log events. Defaults to `7`. One of `1`, `3`, `5`, `7`, `14`, `30`, `60`, `90`, `120`, `150`, `180`, `365`, `400`, `545`, `731`, `1096`, `1827`, `2192`, `2557`, `2922`, `3288` or `3653`, or `0` to keep them forever.
    - `kms_key_id` - (Optional) ARN of a KMS key to encrypt the log groups with. Its key policy must let the CloudWatch Logs service principal for the Region use it. Without it, CloudWatch Logs encrypts them with its own key.
  EOT
  type = object({
    log_types         = optional(list(string), ["slow-log", "engine-log"])
    log_format        = optional(string, "text")
    retention_in_days = optional(number, 7)
    kms_key_id        = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for t in var.cloudwatch_logs.log_types : contains(["slow-log", "engine-log"], t)])
    error_message = "cloudwatch_logs.log_types may contain only slow-log and engine-log."
  }

  validation {
    condition     = length(distinct(var.cloudwatch_logs.log_types)) == length(var.cloudwatch_logs.log_types)
    error_message = "cloudwatch_logs.log_types lists a log type twice."
  }

  validation {
    condition     = contains(["text", "json"], var.cloudwatch_logs.log_format)
    error_message = "cloudwatch_logs.log_format must be text or json."
  }

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_logs.retention_in_days)
    error_message = "cloudwatch_logs.retention_in_days must be 0 (forever) or one of 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288 or 3653."
  }

  validation {
    condition     = var.cloudwatch_logs.kms_key_id == null || startswith(coalesce(var.cloudwatch_logs.kms_key_id, "-"), "arn:")
    error_message = "cloudwatch_logs.kms_key_id must be the ARN of a KMS key."
  }
}

variable "cluster_mode" {
  description = <<-EOT
    Whether the data is split into shards. `disabled`, the default, keeps all data in one shard (`num_node_groups` must be `1`); clients connect to the primary endpoint. `enabled` spreads the keys over `num_node_groups` shards; clients must support cluster mode and connect to the configuration endpoint. `compatible` is the step between them: AWS changes a cache from `disabled` to `enabled` only through `compatible`, applied once each, and only from `disabled` to `enabled`.
  EOT
  type        = string
  default     = "disabled"
  nullable    = false

  validation {
    condition     = contains(["disabled", "enabled", "compatible"], var.cluster_mode)
    error_message = "cluster_mode must be disabled, enabled or compatible."
  }
}

variable "data_tiering_enabled" {
  description = <<-EOT
    Keep less-used data on the nodes' local SSDs instead of in memory. Only for node types with SSDs, such as `cache.r6gd.xlarge`, which require it. Defaults to `false`. Changing it later replaces the cache and deletes its data.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "engine" {
  description = <<-EOT
    The engine: `redis` (Redis OSS) or `valkey`. Defaults to `redis`. Valkey is a fork of Redis OSS that accepts the same commands, and AWS prices its nodes lower. Changing `redis` to `valkey` later upgrades the cache in place (with `engine_version` `7.2` or higher); AWS cannot change `valkey` back to `redis`.
  EOT
  type        = string
  default     = "redis"
  nullable    = false

  validation {
    condition     = contains(["redis", "valkey"], var.engine)
    error_message = "engine must be redis or valkey."
  }
}

variable "engine_version" {
  description = <<-EOT
    The engine version, as major and minor version only, such as `7.1` for Redis OSS or `8.2` for Valkey: AWS applies patch versions on its own (see `maintenance.auto_minor_version_upgrade`), and `metadata` shows the running one as `engine_version_actual`. `aws elasticache describe-cache-engine-versions --engine <engine>` lists them. Without a value, AWS uses the engine's default version. A higher version upgrades the cache in place. AWS cannot downgrade a cache, so a lower version replaces it and deletes its data.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.engine_version == null || can(regex("^[0-9]+\\.[0-9]+$", coalesce(var.engine_version, "-")))
    error_message = "engine_version must be a major and minor version, such as 7.1 or 8.2."
  }
}

variable "ip_discovery" {
  description = <<-EOT
    Whether the cluster discovery commands, such as `CLUSTER SLOTS`, return IPv4 or IPv6 addresses: `ipv4`, the default, or `ipv6`. `ipv6` needs `network_type` `ipv6` or `dual_stack`.
  EOT
  type        = string
  default     = "ipv4"
  nullable    = false

  validation {
    condition     = contains(["ipv4", "ipv6"], var.ip_discovery)
    error_message = "ip_discovery must be ipv4 or ipv6."
  }

  validation {
    condition     = var.ip_discovery == "ipv4" || var.network_type != "ipv4"
    error_message = "ip_discovery = ipv6 needs network_type ipv6 or dual_stack."
  }
}

variable "kms_key_id" {
  description = <<-EOT
    ARN of the AWS Key Management Service (KMS) key that encrypts the cache's data at rest, on disk and in snapshots. The data is always encrypted at rest; without a key, ElastiCache uses a key it owns. Changing the key later, including setting one, replaces the cache and deletes its data.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || startswith(coalesce(var.kms_key_id, "-"), "arn:")
    error_message = "kms_key_id must be the ARN of a KMS key, such as arn:aws:kms:us-east-1:123456789012:key/<key id>."
  }
}

variable "maintenance" {
  description = <<-EOT
    When and how the cache is changed.

    - `window` - (Optional) The weekly time range, in UTC, for maintenance, such as `sun:05:00-sun:06:00`; at least 60 minutes. Without it, AWS picks one.
    - `auto_minor_version_upgrade` - (Optional) Let AWS apply patch versions of the engine during the maintenance window. Defaults to `true`.
    - `apply_immediately` - (Optional) Apply changes such as a new `node_type` or `engine_version` as soon as they are made instead of in the next maintenance window. Defaults to `false`. Some changes, such as the number of shards or replicas, are always applied at once.
  EOT
  type = object({
    window                     = optional(string)
    auto_minor_version_upgrade = optional(bool, true)
    apply_immediately          = optional(bool, false)
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.maintenance.window == null || can(regex("^(mon|tue|wed|thu|fri|sat|sun):([01][0-9]|2[0-3]):[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):([01][0-9]|2[0-3]):[0-5][0-9]$", coalesce(var.maintenance.window, "-")))
    error_message = "maintenance.window must be a lowercase UTC range such as sun:05:00-sun:06:00."
  }
}

variable "multi_az_enabled" {
  description = <<-EOT
    Keep each shard's replicas in other Availability Zones than its primary, and fail over to one of them when the primary or its zone fails. Defaults to `true`. Needs `replicas_per_node_group` of `1` or more, and subnets in at least two Availability Zones in `subnet_group_name`.
  EOT
  type        = bool
  default     = true
  nullable    = false

  validation {
    condition     = !var.multi_az_enabled || var.replicas_per_node_group >= 1
    error_message = "multi_az_enabled needs replicas_per_node_group of 1 or more."
  }
}

variable "name" {
  description = <<-EOT
    The name of the cache (its replication group ID), such as `app-sessions`: 1 to 40 lowercase letters, digits and hyphens, starting with a letter, with no two hyphens in a row and no hyphen at the end. It must be unique among the account's caches in the Region. The security group and log groups are named after it. Changing it later replaces the cache and deletes its data.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,39}$", var.name)) && !strcontains(var.name, "--") && !endswith(var.name, "-")
    error_message = "name must be 1 to 40 lowercase letters, digits and hyphens, start with a letter, and have no two hyphens in a row and no hyphen at the end."
  }
}

variable "network_type" {
  description = <<-EOT
    The IP versions the nodes use: `ipv4`, the default, `ipv6` or `dual_stack`. `ipv6` and `dual_stack` need subnets with IPv6 ranges, and a Nitro node type. Changing it later replaces the cache and deletes its data.
  EOT
  type        = string
  default     = "ipv4"
  nullable    = false

  validation {
    condition     = contains(["ipv4", "ipv6", "dual_stack"], var.network_type)
    error_message = "network_type must be ipv4, ipv6 or dual_stack."
  }
}

variable "node_type" {
  description = <<-EOT
    The node type, which sets each node's memory and CPU, such as `cache.t4g.micro` or `cache.r7g.large`. Not every type is offered in every Region. Changing it later resizes the cache in place.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.node_type, "cache.")
    error_message = "node_type must be an ElastiCache node type, such as cache.t4g.micro."
  }
}

variable "num_node_groups" {
  description = <<-EOT
    The number of shards, from `1` to `500`. Defaults to `1`, which `cluster_mode = "disabled"` requires. With cluster mode enabled, changing it later adds or removes shards in place, moving keys between them.
  EOT
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = try(var.num_node_groups >= 1 && var.num_node_groups <= 500 && floor(var.num_node_groups) == var.num_node_groups, false)
    error_message = "num_node_groups must be a whole number from 1 to 500."
  }

  validation {
    condition     = var.cluster_mode != "disabled" || var.num_node_groups == 1
    error_message = "With cluster_mode = \"disabled\", num_node_groups must be 1."
  }
}

variable "parameter_group_name" {
  description = <<-EOT
    The name of a parameter group for engine settings, such as `maxmemory-policy`. It must be for the engine version's family, such as `redis7` or `valkey8`, and for cluster mode it must have `cluster-enabled` set to `yes` (such as `default.redis7.cluster.on`). Without it, AWS uses the family's default parameter group for the cluster mode.
  EOT
  type        = string
  default     = null
}

variable "port" {
  description = <<-EOT
    The port the nodes listen on. Defaults to `6379`. The security group allows this port. Changing it later replaces the cache and deletes its data.
  EOT
  type        = number
  default     = 6379
  nullable    = false

  validation {
    condition     = try(var.port >= 1 && var.port <= 65535 && floor(var.port) == var.port, false)
    error_message = "port must be a whole number from 1 to 65535."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the cache and everything else in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.
  EOT
  type        = string
  default     = null
}

variable "replicas_per_node_group" {
  description = <<-EOT
    The number of read replicas in each shard, from `0` to `5`. Defaults to `1`, so each shard has two nodes. Replicas serve reads through the reader endpoint and take over when a primary fails: with `1` or more, or with cluster mode on, the module turns on automatic failover, which AWS requires for both. Changing it later adds or removes replicas in place.
  EOT
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = try(var.replicas_per_node_group >= 0 && var.replicas_per_node_group <= 5 && floor(var.replicas_per_node_group) == var.replicas_per_node_group, false)
    error_message = "replicas_per_node_group must be a whole number from 0 to 5."
  }
}

variable "security_group_ingress" {
  description = <<-EOT
    Who can reach the cache over the network. The module creates a security group for the nodes that allows `port` (TCP) from each source listed here, and from nothing else. It allows no outbound traffic: the nodes only answer connections, and security groups let replies out on their own. With the default, `{}`, no client can connect. The keys are names you choose; they only identify each rule, so a security group created in the same configuration can be used.

    Each source takes exactly one of:

    - `cidr_ipv4` - An IPv4 range, such as `10.0.0.0/16`.
    - `cidr_ipv6` - An IPv6 range, such as `2600:1f18:1234:5600::/56`.
    - `security_group_id` - A security group whose members may connect, such as the group of your application servers.
    - `prefix_list_id` - A managed prefix list of ranges.

    and optionally:

    - `description` - (Optional) What the source is. Defaults to the key.
  EOT
  type = map(object({
    cidr_ipv4         = optional(string)
    cidr_ipv6         = optional(string)
    security_group_id = optional(string)
    prefix_list_id    = optional(string)
    description       = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for s in values(var.security_group_ingress) :
      length([for v in [s.cidr_ipv4, s.cidr_ipv6, s.security_group_id, s.prefix_list_id] : v if v != null]) == 1
    ])
    error_message = "Each security_group_ingress entry needs exactly one of cidr_ipv4, cidr_ipv6, security_group_id or prefix_list_id."
  }

  validation {
    condition = alltrue([
      for s in values(var.security_group_ingress) :
      (s.cidr_ipv4 == null || can(cidrnetmask(s.cidr_ipv4))) && (s.cidr_ipv6 == null || (can(cidrhost(s.cidr_ipv6, 0)) && strcontains(coalesce(s.cidr_ipv6, "-"), ":")))
    ])
    error_message = "security_group_ingress: cidr_ipv4 must be an IPv4 range such as 10.0.0.0/16, and cidr_ipv6 an IPv6 range such as 2600:1f18:1234:5600::/56."
  }
}

variable "snapshot" {
  description = <<-EOT
    Automatic snapshots, the snapshot taken when the cache is deleted, and restoring from a snapshot.

    - `retention_limit` - (Optional) Days to keep automatic snapshots, from `0` to `35`. Defaults to `7`. `0` turns them off.
    - `window` - (Optional) The daily time range, in UTC, when AWS takes the snapshot, such as `03:00-04:00`; at least 60 minutes, and not overlapping `maintenance.window`. Without it, AWS picks one.
    - `final_snapshot` - (Optional) Take a snapshot named `<name>-final-<8 hex digits>` when the cache is deleted, and keep it until you delete it. Defaults to `true`.
    - `restore_from` - (Optional) The name of an ElastiCache snapshot to create the cache from. Only read when the cache is created; changing it later has no effect.
  EOT
  type = object({
    retention_limit = optional(number, 7)
    window          = optional(string)
    final_snapshot  = optional(bool, true)
    restore_from    = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition     = try(var.snapshot.retention_limit >= 0 && var.snapshot.retention_limit <= 35 && floor(var.snapshot.retention_limit) == var.snapshot.retention_limit, false)
    error_message = "snapshot.retention_limit must be a whole number from 0 to 35."
  }

  validation {
    condition     = var.snapshot.window == null || can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]-([01][0-9]|2[0-3]):[0-5][0-9]$", coalesce(var.snapshot.window, "-")))
    error_message = "snapshot.window must be a UTC time range such as 03:00-04:00."
  }
}

variable "subnet_group_name" {
  description = <<-EOT
    The name of the ElastiCache subnet group that places the nodes in subnets of `vpc_id`. Use private subnets in at least two Availability Zones. Changing it later replaces the cache and deletes its data.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.subnet_group_name) != ""
    error_message = "subnet_group_name must not be empty."
  }
}

variable "timeouts" {
  description = <<-EOT
    How long Terraform waits for the cache.

    - `create` - (Optional) Defaults to `60m`.
    - `update` - (Optional) Defaults to `120m`. Adding shards to a large cache can take hours.
    - `delete` - (Optional) Defaults to `60m`.
  EOT
  type = object({
    create = optional(string, "60m")
    update = optional(string, "120m")
    delete = optional(string, "60m")
  })
  default  = {}
  nullable = false
}

variable "transit_encryption" {
  description = <<-EOT
    Encryption of the connections between clients and nodes (TLS).

    - `enabled` - (Optional) Defaults to `true`. Clients must then connect with TLS.
    - `mode` - (Optional) `required`, the default, refuses connections without TLS. `preferred` accepts both, so that clients of an existing cache can move to TLS one by one.

    To turn it on for an existing cache without TLS, apply `enabled = true` with `mode = "preferred"`, move every client to TLS, then apply `mode = "required"`. To turn it off, apply `mode = "preferred"` first, then `enabled = false`. Both need Redis OSS 7 or Valkey, and AWS refuses either on a cache with `auth_token` or `user_group_ids`.
  EOT
  type = object({
    enabled = optional(bool, true)
    mode    = optional(string, "required")
  })
  default  = {}
  nullable = false

  validation {
    condition     = contains(["required", "preferred"], var.transit_encryption.mode)
    error_message = "transit_encryption.mode must be required or preferred."
  }
}

variable "user_group_ids" {
  description = <<-EOT
    IDs of ElastiCache user groups for role-based access control: clients sign in as a user of one of the groups, with that user's password and command permissions. Create the users and groups with the `aws_elasticache_user` and `aws_elasticache_user_group` resources. Needs `transit_encryption.enabled`, and cannot be combined with `auth_token` (the AWS provider refuses both together). At most one group. Defaults to `[]`, no user groups.
  EOT
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = length(var.user_group_ids) <= 1
    error_message = "user_group_ids can have at most one user group."
  }

  validation {
    condition     = length(var.user_group_ids) == 0 || var.transit_encryption.enabled
    error_message = "user_group_ids needs transit_encryption.enabled = true."
  }
}

variable "vpc_id" {
  description = <<-EOT
    The ID of the VPC the cache is in, such as `vpc-0123456789abcdef0`: the VPC of `subnet_group_name`. The module creates the cache's security group in it.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "vpc_id must be a VPC ID, such as vpc-0123456789abcdef0."
  }
}
