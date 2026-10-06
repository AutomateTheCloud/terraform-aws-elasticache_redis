# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.0] - 2026-10-05

Initial release.

### Added

- An Amazon ElastiCache replication group running Redis OSS or Valkey, with secure defaults: encrypted at rest and in transit (TLS required), automatic snapshots kept 7 days, a final snapshot when it is deleted, and no network access until you allow a source.
- One shard with a replica in another Availability Zone and automatic failover by default; cluster mode with up to 500 shards and up to 5 replicas each.
- A security group that allows the cache port from IPv4 and IPv6 ranges, security groups and prefix lists, and nothing else.
- Access control with an `AUTH` token or with ElastiCache user groups, including users that sign in with IAM.
- Slow and engine logs published to CloudWatch Logs, as text or JSON, in log groups the module creates with your retention and optional KMS key.
- A customer managed KMS key for data at rest, a parameter group, IPv6 and dual-stack networking, data tiering, and restores from a snapshot.
- `region`, to create the cache in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and examples for a basic cache and most options together.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-elasticache_redis/releases/tag/v1.0.0
