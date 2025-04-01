resource "aws_security_group" "this" {
  name                   = "elasticache-${var.name}"
  description            = "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): ElastiCache - ${var.name}"
  vpc_id                 = data.aws_vpc.this.id
  revoke_rules_on_delete = true
  tags = merge(
    local.tags,
    tomap({
      "Name" = "elasticache-${var.name}"
    })
  )
  provider = aws.this
}
