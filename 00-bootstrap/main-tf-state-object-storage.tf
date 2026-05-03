
# ====== Bucket ===========
### Required Variables ###
variable "tf_state_bucket_name" {
  type        = string
  description = "The user-friendly name of the bucket. Avoid entering confidential information."
}

### Optional Bucket Configuration ###
variable "tf_state_bucket_access_type" {
  type        = string
  default     = "NoPublicAccess"
  description = "The type of public access enabled on this bucket. Valid values: NoPublicAccess, ObjectRead, ObjectReadWrite."
}

variable "tf_state_bucket_auto_tiering" {
  type        = string
  default     = "Disabled"
  description = "Specifies whether to enable or disable auto-tiering for the tf_state_bucket. Valid values: Disabled, InfrequentAccess."
}

variable "tf_state_bucket_object_events_enabled" {
  type        = bool
  default     = false
  description = "Whether or not this tf_state_bucket emits object state change events to Oracle Cloud Events."
}

variable "tf_state_bucket_storage_tier" {
  type        = string
  default     = "Standard"
  description = "The type of storage tier of this tf_state_bucket. Valid values: Standard, Archive."
}

variable "tf_state_bucket_versioning" {
  type        = string
  default     = "Disabled"
  description = "The status of versioning on this tf_state_bucket. Valid values: Enabled, Disabled."
}

# Fetch the namespace automatically
data "oci_objectstorage_namespace" "user_namespace" {
    compartment_id = var.tenancy_ocid
}

resource "oci_objectstorage_bucket" "tf_state_bucket" {
    #Required
    compartment_id = oci_identity_compartment.bootstrap_compartment.id
    name = var.tf_state_bucket_name
    namespace = data.oci_objectstorage_namespace.user_namespace.namespace

    #Optional
    access_type = var.tf_state_bucket_access_type
    auto_tiering = var.tf_state_bucket_auto_tiering
    # defined_tags = {"Operations.CostCenter"= "42"}
    # freeform_tags = {"Department"= "Finance"}
    
    kms_key_id = oci_kms_key.main_kms_key.id
    # metadata = var.bucket_metadata
    object_events_enabled = var.tf_state_bucket_object_events_enabled
    storage_tier = var.tf_state_bucket_storage_tier

    versioning = var.tf_state_bucket_versioning

    # we will not use retention rules here because we will use a lifecycle policy to manage the versions and prevent them from overgrowing
    # retention_rules {
    #     display_name = var.retention_rule_display_name
    #     duration {
    #         #Required
    #         time_amount = var.retention_rule_duration_time_amount
    #         time_unit = var.retention_rule_duration_time_unit
    #     }
    #     time_rule_locked = var.retention_rule_time_rule_locked
    # }

    depends_on = [  oci_identity_policy.objectstorage_kms_policy]
}


# ====== Object Storage Object Lifecycle Policy ===========
variable "tf_state_bucket_lifecycle_time_amount" {
  type        = string
  default     = "30"
  description = "The number of time units (days or years) after which the lifecycle action is taken. For example, '30' with a unit of 'DAYS' deletes versions older than 30 days."
}

variable "tf_state_bucket_lifecycle_time_unit" {
  type        = string
  default     = "DAYS"
  description = "The unit of time for the lifecycle policy delay. Valid values: DAYS, YEARS."
}

resource "oci_objectstorage_object_lifecycle_policy" "tf_state_bucket_limit_versions" {
  bucket    = oci_objectstorage_bucket.tf_state_bucket.name
  namespace = data.oci_objectstorage_namespace.user_namespace.namespace

  rules {
    action      = "DELETE"
    name        = "DeleteOldVersions"
    target      = "previous-object-versions" # Specifically targets the backups
    is_enabled  = true
    
    # Delete any version that isn't the current one after 30 days
    time_amount = var.tf_state_bucket_lifecycle_time_amount
    time_unit   = var.tf_state_bucket_lifecycle_time_unit
  }

  depends_on = [  oci_objectstorage_bucket.tf_state_bucket]
}