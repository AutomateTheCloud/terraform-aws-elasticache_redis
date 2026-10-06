# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A suffix for the final snapshot's name, so that a cache created again with the same
# name does not collide with the final snapshot of the one deleted before it. The
# suffix changes with every input that replaces the cache: otherwise the replacement
# kept the old suffix, and its own delete failed with SnapshotAlreadyExistsFault
# (seen in AWS). engine_version is here because lowering it replaces the cache; a new
# suffix on an upgrade only renames the future snapshot.
resource "random_id" "final_snapshot" {
  byte_length = 4

  keepers = {
    name                 = var.name
    port                 = var.port
    kms_key_id           = var.kms_key_id
    subnet_group_name    = var.subnet_group_name
    network_type         = var.network_type
    data_tiering_enabled = var.data_tiering_enabled
    engine_version       = var.engine_version
  }
}
