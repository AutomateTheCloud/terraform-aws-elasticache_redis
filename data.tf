data "aws_kms_key" "elasticache" {
  count    = try(var.encryption.kms_key_id, null) != null ? 1 : 0
  key_id   = var.encryption.kms_key_id
  provider = aws.this
}

data "aws_vpc" "this" {
  id       = var.vpc_id
  provider = aws.this
}
