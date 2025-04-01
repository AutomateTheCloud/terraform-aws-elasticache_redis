variable "apply_immediately" {
  description = "Specifies whether any modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

variable "auth_token" {
  description = "Password used to access a password protected server"
  type        = string
  default     = null
}

variable "auth_token_update_strategy" {
  description = "Strategy to use when updating the auth_token (SET, ROTATE, DELETE)"
  type        = string
  default     = null
}

variable "automatic_failover_enabled" {
  description = "Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails"
  type        = bool
  default     = true
}

variable "cloudwatch" {
  description = "Cloudwatch"
  type        = any
  default     = null
}

variable "cluster_mode" {
  description = "Cluster Mode"
  type        = string
  default     = "disabled"
  validation {
    condition     = contains(["enabled", "disabled", "compatible"], var.cluster_mode)
    error_message = "Valid values for cluster_mode are (enabled, disabled, compatible)"
  }
}

variable "data_tiering_enabled" {
  description = "Data Tiering Enabled"
  type        = bool
  default     = false
}

variable "encryption" {
  # kms_key_id
  # transit.encryption_enabled
  # transit.transit_encryption_mode
  description = "Encryption"
  type        = any
  default     = null
}

variable "engine" {
  description = "Engine"
  type        = string
  default     = "redis"
  validation {
    condition     = contains(["redis", "valkey"], var.engine)
    error_message = "Valid values for engine are (redis, valkey)"
  }
}

variable "engine_version" {
  # aws --region us-east-1 elasticache describe-cache-engine-versions --engine valkey
  # aws --region us-east-1 elasticache describe-cache-engine-versions --engine redis
  description = "Engine Version"
  type        = string
  default     = null
}

variable "ip_discovery" {
  description = "IP version to advertise in the discovery protocol"
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "ipv6"], var.ip_discovery)
    error_message = "Valid values for ip_discovery are (ipv4, ipv6)"
  }
}

variable "maintenance" {
  # auto_minor_version_upgrade
  # window
  # apply_immediately
  description = "Maintenance"
  type        = any
  default     = null
}

variable "multi_az_enabled" {
  description = "Multi-AZ Support Enabled"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name"
  type        = string
  default     = null
}

variable "network_type" {
  description = "The IP versions for cache cluster connections"
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "ipv6", "dual_stack"], var.network_type)
    error_message = "Valid values for network_type are (ipv4, ipv6, dual_stack)"
  }
}

variable "node_type" {
  description = "Node Type"
  type        = string
  default     = ""
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (primary and replicas) this replication group will have"
  type        = number
  default     = null
}

variable "num_node_groups" {
  description = "Number of node groups (shards) for this Redis replication group"
  type        = number
  default     = null
}

variable "parameter_group_name" {
  description = "Parameter Group Name"
  type        = string
  default     = null
}

variable "port" {
  description = "Port"
  type        = number
  default     = 6379
}

variable "replicas_per_node_group" {
  description = "Number of replica nodes in each node group"
  type        = number
  default     = null
}

variable "security_groups_additional" {
  description = "Security Groups (Additional)"
  type        = list(any)
  default     = []
}

variable "security_group_rules" {
  description = "Security Group Rules"
  type        = any
  default     = null
}

variable "snapshot" {
  # name
  # retention_limit
  # window
  description = "Snapshot"
  type        = any
  default     = null
}

variable "subnet_group_name" {
  description = "Subnet Group Name"
  type        = string
  default     = ""
}

variable "timeouts" {
  description = "Timeouts"
  type        = any
  default = {
    create = "180m"
    delete = "120m"
    update = "120m"
  }
}

variable "transit_encryption_enabled" {
  description = "Transit Encryption Enabled"
  type        = bool
  default     = true
}

variable "transit_encryption_mode" {
  description = "Transit Encryption Mode"
  type        = string
  default     = "preferred"
  validation {
    condition     = contains(["preferred", "required"], var.transit_encryption_mode)
    error_message = "Valid values for transit_encryption_mode  are (preferred, required)"
  }
}

variable "user_group_id" {
  description = "User Group ID"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}
