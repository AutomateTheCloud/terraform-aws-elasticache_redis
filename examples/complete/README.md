# Complete

Most of the module's options together, for an application's production cache:

- Valkey 8.2 in cluster mode, with two shards, each with a replica in another Availability Zone, and automatic failover.
- A customer managed AWS Key Management Service (KMS) key encrypts the data at rest and the snapshots. Clients must connect with TLS.
- A parameter group for cluster mode that evicts the least recently used keys when memory is full.
- Sign-in with AWS Identity and Access Management (IAM): the application signs in as the user `example-complete-app` with a short-lived IAM authentication token, so no password is stored anywhere. The user group has no `default` user, which Valkey allows, so clients that do not sign in get no access.
- Automatic snapshots kept 14 days, taken at 03:00 UTC; maintenance on Sundays at 05:00 UTC.
- The slow and engine logs in CloudWatch Logs as JSON, kept 30 days.
- Only members of the application's security group can reach the cache.

The example creates the KMS key, the subnet group, the parameter group, the user and user group, and the application's security group. It does not create the application's servers: attach the `app_security_group_id` output's group to them, and give their IAM role `elasticache:Connect` on the cache and on the user.

## Run it

Choose a VPC and private subnets in at least two Availability Zones:

```shell
terraform init
terraform apply -var 'vpc_id=vpc-0123456789abcdef0' -var 'subnet_ids=["subnet-0123456789abcdef0","subnet-0fedcba9876543210"]'
```

Creating the cache takes about 15 to 20 minutes. Clients must support cluster mode and connect to the `cache` output's configuration endpoint.

To remove it, run `terraform destroy` with the same `-var` options. ElastiCache takes a final snapshot, `example-complete-final-<8 hex digits>`, encrypted with the example's key; it is kept, and billed, until you delete it. KMS deletes the key seven days after the destroy, after which that snapshot can no longer be restored, so delete the snapshot, or keep the key, first.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

- <a name="requirement_random"></a> [random](#requirement_random) (~> 3.0)

### Required Inputs

The following input variables are required:

#### <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)

Description: IDs of private subnets for the cache, in at least two Availability Zones

Type: `list(string)`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of the VPC to create the cache in

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_app_security_group_id"></a> [app_security_group_id](#output_app_security_group_id)

Description: The security group to attach to the application servers

#### <a name="output_cache"></a> [cache](#output_cache)

Description: Where to connect: the configuration endpoint, which cluster-mode clients use to find every shard, the port, and the IAM user name
<!-- END_TF_DOCS -->
