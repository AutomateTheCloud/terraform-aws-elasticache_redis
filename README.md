# Terraform module for Amazon ElastiCache for Redis OSS and Valkey

Creates an Amazon ElastiCache replication group running Redis OSS or Valkey, with a security group that controls which clients can reach it. Optional settings cover cluster mode with up to 500 shards, replicas and automatic failover across Availability Zones, access control with a token or with ElastiCache users (including IAM authentication), a customer managed encryption key, snapshots, maintenance, and logs in Amazon CloudWatch.

The defaults are the settings most caches should have. A cache created with only the required inputs is encrypted at rest and in transit, has a replica in a second Availability Zone that takes over if the primary fails, keeps automatic snapshots for 7 days, takes a final snapshot when it is deleted, and cannot be reached over the network until you allow a source.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Encryption at rest | Always on, with a key ElastiCache owns | `kms_key_id` |
| Encryption in transit (TLS) | On, and required | `transit_encryption` |
| Network access | None: no client can connect | `security_group_ingress` |
| Outbound traffic | None | `additional_security_group_ids` |
| Authentication | None beyond the network; see [Authentication](https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis#authentication) | `auth_token`, `user_group_ids` |
| Engine | Redis OSS, the Region's default version | `engine`, `engine_version` |
| Shards and replicas | One shard, one replica | `cluster_mode`, `num_node_groups`, `replicas_per_node_group` |
| Multi-AZ and automatic failover | On | `multi_az_enabled` |
| Automatic snapshots | Kept 7 days | `snapshot` |
| Final snapshot when deleted | Taken | `snapshot.final_snapshot` |
| Patch version upgrades | Applied by AWS in the maintenance window | `maintenance` |
| Logs in CloudWatch | Slow log and engine log, kept 7 days | `cloudwatch_logs` |

## Usage

```hcl
module "elasticache_redis" {
  source  = "AutomateTheCloud/elasticache_redis/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "App Cache"
    environment = "Production"
  }

  name              = "app-cache"
  node_type         = "cache.t4g.small"
  vpc_id            = "vpc-0123456789abcdef0"
  subnet_group_name = "app-private"

  security_group_ingress = {
    app = { security_group_id = "sg-0123456789abcdef0", description = "Application servers" }
  }
}
```

`details`, `name`, `node_type`, `vpc_id` and `subnet_group_name` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on every resource.

Clients connect with TLS to `module.elasticache_redis.metadata.elasticache_replication_group.primary_endpoint_address` for reads and writes, or to `reader_endpoint_address` for reads, on `module.elasticache_redis.metadata.elasticache_replication_group.port`. In cluster mode, they connect to `configuration_endpoint_address` instead.

The module uses your default `aws` provider and creates everything in that provider's Region. To create the cache somewhere else without configuring another provider, set `region`:

```hcl
module "elasticache_redis_us_west_2" {
  source  = "AutomateTheCloud/elasticache_redis/aws"
  version = "~> 1.0"

  region            = "us-west-2"
  details           = { scope = "Automate the Cloud", purpose = "App Cache", environment = "Production" }
  name              = "app-cache"
  node_type         = "cache.t4g.small"
  vpc_id            = "vpc-0abcdef0123456789"
  subnet_group_name = "app-private"
}
```

The VPC and subnet group must be in that Region too.

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the cache belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "App Cache"          # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a cache in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the cache, its key, its network and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "App Cache"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "app_cache" {
  source  = "AutomateTheCloud/elasticache_redis/aws"
  version = "~> 1.0"

  details           = local.details
  name              = "app-cache"
  node_type         = "cache.t4g.small"
  vpc_id            = "vpc-0123456789abcdef0"
  subnet_group_name = "app-private"
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`App Cache` becomes `app_cache`), and `machine`, lowercase letters and numbers only (`appcache`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.app_cache.metadata.elasticache_replication_group.primary_endpoint_address` for the host name clients connect to, or `module.app_cache.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`, given a VPC and private subnets.

- [Basic cache](https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis/tree/main/examples/basic): a private, encrypted Redis OSS cache with a replica, that anything in the VPC can reach.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis/tree/main/examples/complete): most of the module's options, with Valkey in cluster mode, a customer managed key, IAM authentication, and access from one security group.

## Things to know

### Authentication

By default, any client that can reach the cache's port can use it: the security group is the only control. Keep `security_group_ingress` narrow, and for anything beyond a development cache, add one of these:

- **ElastiCache users and user groups** (`user_group_ids`), the option AWS recommends. Each user has its own password, or signs in with an IAM authentication token, and its own command and key permissions. The [complete example](https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis/tree/main/examples/complete) creates a user that signs in with IAM, so no password is stored anywhere. AWS requires a user named `default` in a Redis OSS user group; give it the access string `off -@all` so that clients must sign in. A Valkey user group needs no `default` user, and refuses users without a password.
- **An `AUTH` token** (`auth_token`), one shared password. It is stored in the Terraform state, so keep the state in an encrypted backend that only administrators can read. A token can be added to an existing cache. To change it, apply the new token with `auth_token_update_strategy = "ROTATE"`, the default: the cache accepts both the old and the new token while clients move. Then apply the same token again with `"SET"`, and the cache accepts only the new one.

Both need encryption in transit, and the AWS provider refuses them together.

Two traps with tokens, both seen in AWS with AWS provider 6.0.0:

- AWS refuses a new token with `"SET"` while it still holds the old one; it accepts `"SET"` only with the token given with `"ROTATE"`. Use the two steps above.
- The AWS provider cannot remove a token: with `auth_token` unset, it sends an empty token, which AWS refuses.

After either failed apply, the provider has already saved the refused value in the state, so the next plan shows no change while the cache still uses the old token. Apply a correct value, such as the token the cache actually uses, to bring them back in line.

### Encryption in transit

Clients must connect with TLS; `redis-cli` takes `--tls`, and most client libraries have a TLS or `rediss://` option. In `required` mode, ElastiCache accepts no other connections.

To turn TLS on for an existing cache that does not use it, apply `transit_encryption = { enabled = true, mode = "preferred" }`, which accepts both kinds of connection, move every client to TLS, then apply `mode = "required"`. Turning it off goes the other way: `preferred` first, then `enabled = false`. Both changes need Redis OSS 7 or later, or Valkey. AWS refuses any change to encryption in transit on a cache with access control ("not supported for access control enabled clusters", seen with an `AUTH` token; user groups are access control too), so decide on it before adding either.

### Settings that replace the cache

AWS cannot change some settings of an existing cache. Changing `name`, `port`, `kms_key_id` (including setting one later), `subnet_group_name`, `network_type` or `data_tiering_enabled`, or lowering `engine_version`, replaces the cache and deletes its data, after a final snapshot unless `snapshot.final_snapshot` is `false`. Clients must then use the new cache's endpoints. Most other settings, including `node_type`, `engine_version`, the number of shards and replicas, `multi_az_enabled`, snapshots and the security group's sources, change in place.

### Shards, replicas and failover

With `cluster_mode = "disabled"`, the default, the cache has one shard: a primary that takes writes, and `replicas_per_node_group` replicas that serve reads through the reader endpoint. With `cluster_mode = "enabled"`, keys are spread over `num_node_groups` shards, each with its own primary and replicas, and clients must support cluster mode. AWS changes a cache from `disabled` to `enabled` only through `compatible`, and not back; see [Modifying cluster mode](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/modify-cluster-mode.html) in the ElastiCache documentation.

Whenever there are replicas, or cluster mode is on, the module turns on automatic failover: if a primary fails, ElastiCache promotes one of its replicas. `multi_az_enabled`, on by default, also places replicas in other Availability Zones than their primary. Both need at least one replica per shard; `replicas_per_node_group = 0` with `multi_az_enabled = false` gives a single node, which loses its data if it fails.

### Engine versions and upgrades

Give `engine_version` as major and minor version, such as `7.1` for Redis OSS or `8.2` for Valkey. AWS applies patch versions in the maintenance window (`maintenance.auto_minor_version_upgrade`), and the running version is in `metadata.elasticache_replication_group.engine_version_actual`; the plan stays clean.

A higher `engine_version` upgrades the cache in place. Changing `engine` from `redis` to `valkey`, with a Valkey version such as `8.2`, also upgrades it in place. AWS cannot downgrade a cache, so the AWS provider plans a lower `engine_version` as a replacement: the cache is deleted, after a final snapshot, and created again empty. Check the plan before applying a version change. AWS cannot move a cache from Valkey back to Redis OSS. If you use your own parameter group, pass one for the new version's family with the change; without one, AWS moves the cache to the new family's default group. AWS reports the new running version and parameter group only after the apply has saved the cache, so the first plan afterwards shows `metadata` changing; applying that plan, which changes no resources, clears it. An upgrade from Redis OSS 7.1 to Valkey 8.2 took 18 minutes.

### Changes that wait for the maintenance window

With `maintenance.apply_immediately = false`, the default, ElastiCache applies some changes, such as a new node type or engine version, in the next maintenance window. The apply finishes at once, but AWS does not list the change as pending and still reports the old value, so every plan shows the change again until the window has passed. Set `apply_immediately = true` to apply changes at once. Changes to the number of shards or replicas are always applied at once. Right after such a change, the next plan can show it again, because the provider saved the cache before AWS reported the new nodes; plan again a few minutes later.

### Deleting a cache

When the cache is deleted, ElastiCache takes a final snapshot named `<name>-final-<8 hex digits>`, unless `snapshot.final_snapshot` is `false`. The snapshot is kept, and billed, until you delete it; create a new cache from it with `snapshot.restore_from`.

### Network access

The module's security group allows the cache port, over TCP, from the sources in `security_group_ingress`, and nothing else. It has no outbound rules: the nodes only answer connections. ElastiCache gives the nodes private IP addresses in the subnet group's subnets; clients reach them from inside the VPC, or from networks connected to it.

### Logs

For each log type in `cloudwatch_logs.log_types`, the module creates the log group `/aws/elasticache/<name>/<log type>`, with the retention you choose, before the cache starts writing to it. The slow log lists commands that took longer than the parameter group's `slowlog-log-slower-than`; the engine log holds the engine's own messages. Destroying the module deletes those log groups and their events.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

- <a name="requirement_random"></a> [random](#requirement_random) (>= 3.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_name"></a> [name](#input_name)

Description: The name of the cache (its replication group ID), such as `app-sessions`: 1 to 40 lowercase letters, digits and hyphens, starting with a letter, with no two hyphens in a row and no hyphen at the end. It must be unique among the account's caches in the Region. The security group and log groups are named after it. Changing it later replaces the cache and deletes its data.

Type: `string`

#### <a name="input_node_type"></a> [node_type](#input_node_type)

Description: The node type, which sets each node's memory and CPU, such as `cache.t4g.micro` or `cache.r7g.large`. Not every type is offered in every Region. Changing it later resizes the cache in place.

Type: `string`

#### <a name="input_subnet_group_name"></a> [subnet_group_name](#input_subnet_group_name)

Description: The name of the ElastiCache subnet group that places the nodes in subnets of `vpc_id`. Use private subnets in at least two Availability Zones. Changing it later replaces the cache and deletes its data.

Type: `string`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: The ID of the VPC the cache is in, such as `vpc-0123456789abcdef0`: the VPC of `subnet_group_name`. The module creates the cache's security group in it.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_additional_security_group_ids"></a> [additional_security_group_ids](#input_additional_security_group_ids)

Description: More security groups to attach to the cache nodes, beside the one the module creates, such as `["sg-0123456789abcdef0"]`. The module's group allows no outbound traffic; add a group here if the nodes must open connections themselves.

Type: `list(string)`

Default: `[]`

#### <a name="input_auth_token"></a> [auth_token](#input_auth_token)

Description: A password that clients must send with the `AUTH` command before any other command: 16 to 128 printable ASCII characters, without spaces, `"`, `/` or `@`. It needs `transit_encryption.enabled`. Without it, and without `user_group_ids`, any client that can reach the port can use the cache, so keep `security_group_ingress` narrow.

The token is stored in the Terraform state, so protect the state. To change it on an existing cache, see `auth_token_update_strategy`. The AWS provider cannot remove a token from an existing cache: AWS refuses the empty token it sends.

Type: `string`

Default: `null`

#### <a name="input_auth_token_update_strategy"></a> [auth_token_update_strategy](#input_auth_token_update_strategy)

Description: How a change to `auth_token` is applied to an existing cache: `ROTATE`, the default, accepts both the old and the new token, so clients can move to the new one; then apply the same token with `SET` to accept only the new one. AWS refuses `SET` with a token other than the one given with `ROTATE`. Not used when the cache is created, or without `auth_token`.

Type: `string`

Default: `"ROTATE"`

#### <a name="input_cloudwatch_logs"></a> [cloudwatch_logs](#input_cloudwatch_logs)

Description: Logs to publish to Amazon CloudWatch Logs. The module creates one log group per log type, `/aws/elasticache/<name>/<log type>`, before the cache starts writing to it.

- `log_types` - (Optional) `slow-log` (commands that took longer than the `slowlog-log-slower-than` parameter), `engine-log` (the engine's own log), both, or `[]` for none. Defaults to both.
- `log_format` - (Optional) `text` or `json`. Defaults to `text`.
- `retention_in_days` - (Optional) Days to keep log events. Defaults to `7`. One of `1`, `3`, `5`, `7`, `14`, `30`, `60`, `90`, `120`, `150`, `180`, `365`, `400`, `545`, `731`, `1096`, `1827`, `2192`, `2557`, `2922`, `3288` or `3653`, or `0` to keep them forever.
- `kms_key_id` - (Optional) ARN of a KMS key to encrypt the log groups with. Its key policy must let the CloudWatch Logs service principal for the Region use it. Without it, CloudWatch Logs encrypts them with its own key.

Type:

```hcl
object({
    log_types         = optional(list(string), ["slow-log", "engine-log"])
    log_format        = optional(string, "text")
    retention_in_days = optional(number, 7)
    kms_key_id        = optional(string)
  })
```

Default: `{}`

#### <a name="input_cluster_mode"></a> [cluster_mode](#input_cluster_mode)

Description: Whether the data is split into shards. `disabled`, the default, keeps all data in one shard (`num_node_groups` must be `1`); clients connect to the primary endpoint. `enabled` spreads the keys over `num_node_groups` shards; clients must support cluster mode and connect to the configuration endpoint. `compatible` is the step between them: AWS changes a cache from `disabled` to `enabled` only through `compatible`, applied once each, and only from `disabled` to `enabled`.

Type: `string`

Default: `"disabled"`

#### <a name="input_data_tiering_enabled"></a> [data_tiering_enabled](#input_data_tiering_enabled)

Description: Keep less-used data on the nodes' local SSDs instead of in memory. Only for node types with SSDs, such as `cache.r6gd.xlarge`, which require it. Defaults to `false`. Changing it later replaces the cache and deletes its data.

Type: `bool`

Default: `false`

#### <a name="input_engine"></a> [engine](#input_engine)

Description: The engine: `redis` (Redis OSS) or `valkey`. Defaults to `redis`. Valkey is a fork of Redis OSS that accepts the same commands, and AWS prices its nodes lower. Changing `redis` to `valkey` later upgrades the cache in place (with `engine_version` `7.2` or higher); AWS cannot change `valkey` back to `redis`.

Type: `string`

Default: `"redis"`

#### <a name="input_engine_version"></a> [engine_version](#input_engine_version)

Description: The engine version, as major and minor version only, such as `7.1` for Redis OSS or `8.2` for Valkey: AWS applies patch versions on its own (see `maintenance.auto_minor_version_upgrade`), and `metadata` shows the running one as `engine_version_actual`. `aws elasticache describe-cache-engine-versions --engine <engine>` lists them. Without a value, AWS uses the engine's default version. A higher version upgrades the cache in place. AWS cannot downgrade a cache, so a lower version replaces it and deletes its data.

Type: `string`

Default: `null`

#### <a name="input_ip_discovery"></a> [ip_discovery](#input_ip_discovery)

Description: Whether the cluster discovery commands, such as `CLUSTER SLOTS`, return IPv4 or IPv6 addresses: `ipv4`, the default, or `ipv6`. `ipv6` needs `network_type` `ipv6` or `dual_stack`.

Type: `string`

Default: `"ipv4"`

#### <a name="input_kms_key_id"></a> [kms_key_id](#input_kms_key_id)

Description: ARN of the AWS Key Management Service (KMS) key that encrypts the cache's data at rest, on disk and in snapshots. The data is always encrypted at rest; without a key, ElastiCache uses a key it owns. Changing the key later, including setting one, replaces the cache and deletes its data.

Type: `string`

Default: `null`

#### <a name="input_maintenance"></a> [maintenance](#input_maintenance)

Description: When and how the cache is changed.

- `window` - (Optional) The weekly time range, in UTC, for maintenance, such as `sun:05:00-sun:06:00`; at least 60 minutes. Without it, AWS picks one.
- `auto_minor_version_upgrade` - (Optional) Let AWS apply patch versions of the engine during the maintenance window. Defaults to `true`.
- `apply_immediately` - (Optional) Apply changes such as a new `node_type` or `engine_version` as soon as they are made instead of in the next maintenance window. Defaults to `false`. Some changes, such as the number of shards or replicas, are always applied at once.

Type:

```hcl
object({
    window                     = optional(string)
    auto_minor_version_upgrade = optional(bool, true)
    apply_immediately          = optional(bool, false)
  })
```

Default: `{}`

#### <a name="input_multi_az_enabled"></a> [multi_az_enabled](#input_multi_az_enabled)

Description: Keep each shard's replicas in other Availability Zones than its primary, and fail over to one of them when the primary or its zone fails. Defaults to `true`. Needs `replicas_per_node_group` of `1` or more, and subnets in at least two Availability Zones in `subnet_group_name`.

Type: `bool`

Default: `true`

#### <a name="input_network_type"></a> [network_type](#input_network_type)

Description: The IP versions the nodes use: `ipv4`, the default, `ipv6` or `dual_stack`. `ipv6` and `dual_stack` need subnets with IPv6 ranges, and a Nitro node type. Changing it later replaces the cache and deletes its data.

Type: `string`

Default: `"ipv4"`

#### <a name="input_num_node_groups"></a> [num_node_groups](#input_num_node_groups)

Description: The number of shards, from `1` to `500`. Defaults to `1`, which `cluster_mode = "disabled"` requires. With cluster mode enabled, changing it later adds or removes shards in place, moving keys between them.

Type: `number`

Default: `1`

#### <a name="input_parameter_group_name"></a> [parameter_group_name](#input_parameter_group_name)

Description: The name of a parameter group for engine settings, such as `maxmemory-policy`. It must be for the engine version's family, such as `redis7` or `valkey8`, and for cluster mode it must have `cluster-enabled` set to `yes` (such as `default.redis7.cluster.on`). Without it, AWS uses the family's default parameter group for the cluster mode.

Type: `string`

Default: `null`

#### <a name="input_port"></a> [port](#input_port)

Description: The port the nodes listen on. Defaults to `6379`. The security group allows this port. Changing it later replaces the cache and deletes its data.

Type: `number`

Default: `6379`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the cache and everything else in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.

Type: `string`

Default: `null`

#### <a name="input_replicas_per_node_group"></a> [replicas_per_node_group](#input_replicas_per_node_group)

Description: The number of read replicas in each shard, from `0` to `5`. Defaults to `1`, so each shard has two nodes. Replicas serve reads through the reader endpoint and take over when a primary fails: with `1` or more, or with cluster mode on, the module turns on automatic failover, which AWS requires for both. Changing it later adds or removes replicas in place.

Type: `number`

Default: `1`

#### <a name="input_security_group_ingress"></a> [security_group_ingress](#input_security_group_ingress)

Description: Who can reach the cache over the network. The module creates a security group for the nodes that allows `port` (TCP) from each source listed here, and from nothing else. It allows no outbound traffic: the nodes only answer connections, and security groups let replies out on their own. With the default, `{}`, no client can connect. The keys are names you choose; they only identify each rule, so a security group created in the same configuration can be used.

Each source takes exactly one of:

- `cidr_ipv4` - An IPv4 range, such as `10.0.0.0/16`.
- `cidr_ipv6` - An IPv6 range, such as `2600:1f18:1234:5600::/56`.
- `security_group_id` - A security group whose members may connect, such as the group of your application servers.
- `prefix_list_id` - A managed prefix list of ranges.

and optionally:

- `description` - (Optional) What the source is. Defaults to the key.

Type:

```hcl
map(object({
    cidr_ipv4         = optional(string)
    cidr_ipv6         = optional(string)
    security_group_id = optional(string)
    prefix_list_id    = optional(string)
    description       = optional(string)
  }))
```

Default: `{}`

#### <a name="input_snapshot"></a> [snapshot](#input_snapshot)

Description: Automatic snapshots, the snapshot taken when the cache is deleted, and restoring from a snapshot.

- `retention_limit` - (Optional) Days to keep automatic snapshots, from `0` to `35`. Defaults to `7`. `0` turns them off.
- `window` - (Optional) The daily time range, in UTC, when AWS takes the snapshot, such as `03:00-04:00`; at least 60 minutes, and not overlapping `maintenance.window`. Without it, AWS picks one.
- `final_snapshot` - (Optional) Take a snapshot named `<name>-final-<8 hex digits>` when the cache is deleted, and keep it until you delete it. Defaults to `true`.
- `restore_from` - (Optional) The name of an ElastiCache snapshot to create the cache from. Only read when the cache is created; changing it later has no effect.

Type:

```hcl
object({
    retention_limit = optional(number, 7)
    window          = optional(string)
    final_snapshot  = optional(bool, true)
    restore_from    = optional(string)
  })
```

Default: `{}`

#### <a name="input_timeouts"></a> [timeouts](#input_timeouts)

Description: How long Terraform waits for the cache.

- `create` - (Optional) Defaults to `60m`.
- `update` - (Optional) Defaults to `120m`. Adding shards to a large cache can take hours.
- `delete` - (Optional) Defaults to `60m`.

Type:

```hcl
object({
    create = optional(string, "60m")
    update = optional(string, "120m")
    delete = optional(string, "60m")
  })
```

Default: `{}`

#### <a name="input_transit_encryption"></a> [transit_encryption](#input_transit_encryption)

Description: Encryption of the connections between clients and nodes (TLS).

- `enabled` - (Optional) Defaults to `true`. Clients must then connect with TLS.
- `mode` - (Optional) `required`, the default, refuses connections without TLS. `preferred` accepts both, so that clients of an existing cache can move to TLS one by one.

To turn it on for an existing cache without TLS, apply `enabled = true` with `mode = "preferred"`, move every client to TLS, then apply `mode = "required"`. To turn it off, apply `mode = "preferred"` first, then `enabled = false`. Both need Redis OSS 7 or Valkey, and AWS refuses either on a cache with `auth_token` or `user_group_ids`.

Type:

```hcl
object({
    enabled = optional(bool, true)
    mode    = optional(string, "required")
  })
```

Default: `{}`

#### <a name="input_user_group_ids"></a> [user_group_ids](#input_user_group_ids)

Description: IDs of ElastiCache user groups for role-based access control: clients sign in as a user of one of the groups, with that user's password and command permissions. Create the users and groups with the `aws_elasticache_user` and `aws_elasticache_user_group` resources. Needs `transit_encryption.enabled`, and cannot be combined with `auth_token` (the AWS provider refuses both together). At most one group. Defaults to `[]`, no user groups.

Type: `list(string)`

Default: `[]`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
- `elasticache_replication_group` - The cache: the endpoints clients connect to (`primary_endpoint_address` and `reader_endpoint_address` with cluster mode disabled, `configuration_endpoint_address` with cluster mode enabled or compatible), `port`, `arn`, `id`, `engine_version_actual` (the running version), `member_clusters` (the node IDs), and the rest of its attributes. The `auth_token` is left out.
- `security_group` - The cache's security group, with its `id`, `arn` and `name`.
- `vpc_security_group_ingress_rule` - The ingress rules, keyed like `security_group_ingress`, or `null` when there are none.
- `cloudwatch_log_group` - The log groups, keyed by log type (`slow-log`, `engine-log`), each with its `name`, `arn` and `retention_in_days`, or `null` when no logs are published.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
