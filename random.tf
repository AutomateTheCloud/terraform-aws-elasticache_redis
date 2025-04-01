resource "random_id" "snapshot_identifier" {
  keepers = {
    id = var.name
  }
  byte_length = 4
}
