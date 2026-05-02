
variable "teraform_state_bucket_name" {
  type = string
}
variable "teraform_state_bucket_namespace" {
  type = string
}


resource "oci_objectstorage_bucket" "terraform_state_bucket" {
    #Required
    compartment_id = oci_identity_compartment.bootstrap_compartment.id
    name = var.teraform_state_bucket_name
    namespace = var.teraform_state_bucket_namespace

    #Optional
    access_type = var.bucket_access_type
    auto_tiering = var.bucket_auto_tiering
    bucket_scope = var.bucket_bucket_scope
    # defined_tags = {"Operations.CostCenter"= "42"}
    # freeform_tags = {"Department"= "Finance"}
    kms_key_id = oci_kms_key.main_kms_key.id
    metadata = var.bucket_metadata
    object_events_enabled = var.bucket_object_events_enabled
    storage_tier = var.bucket_storage_tier
    retention_rules {
        display_name = var.retention_rule_display_name
        duration {
            #Required
            time_amount = var.retention_rule_duration_time_amount
            time_unit = var.retention_rule_duration_time_unit
        }
        time_rule_locked = var.retention_rule_time_rule_locked
    }
    versioning = var.bucket_versioning
}