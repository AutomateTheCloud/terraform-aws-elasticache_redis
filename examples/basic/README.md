# Basic cache

A private, encrypted Redis OSS cache in the subnets you give: one primary node and one replica in another Availability Zone, which ElastiCache fails over to if the primary fails. Clients must connect with TLS. Anything in the VPC can reach it on port 6379.

Everything else uses the module's defaults: the engine's default version, encryption at rest with a key ElastiCache owns, automatic snapshots kept 7 days, the slow and engine logs in CloudWatch Logs for 7 days, and a final snapshot when the cache is deleted.

## Run it

Choose a VPC and private subnets in at least two Availability Zones:

```shell
terraform init
terraform apply -var 'vpc_id=vpc-0123456789abcdef0' -var 'subnet_ids=["subnet-0123456789abcdef0","subnet-0fedcba9876543210"]'
```

Creating the cache takes about 10 to 15 minutes. The `cache` output gives the primary and reader endpoints. From an instance in the VPC, with `redis-cli` 6 or later:

```shell
redis-cli -h <primary endpoint> -p 6379 --tls PING
```

To remove it, run `terraform destroy` with the same `-var` options. ElastiCache takes a final snapshot, `example-basic-final-<8 hex digits>`, which is kept, and billed, until you delete it.

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

#### <a name="output_cache"></a> [cache](#output_cache)

Description: Where to connect: the primary endpoint for reads and writes, the reader endpoint for reads, and the port
<!-- END_TF_DOCS -->
