resource "aws_cloudwatch_log_group" "engine" {
  name              = "/aws/elasticache/${var.engine}/${var.name}/engine"
  retention_in_days = try(var.cloudwatch.retention, 7)
  tags              = local.tags
  provider          = aws.this
}

resource "aws_cloudwatch_log_group" "slow" {
  name              = "/aws/elasticache/${var.engine}/${var.name}/slow"
  retention_in_days = try(var.cloudwatch.retention, 7)
  tags              = local.tags
  provider          = aws.this
}
