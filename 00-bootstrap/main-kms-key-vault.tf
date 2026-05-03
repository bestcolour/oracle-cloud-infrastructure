# This is the tf file that will provision the KMS oracle cloud resources (with the exclusion of kms secrets)
# this will need to be provisoned first before provisioning the rest of the cloud architecture's resources as it is the underlying security that it will make use of.
# 

# ==== Vault ======
variable "main_kms_vault_display_name" {
    type = string
    description = "The display name for the cloud vault resource."
}
variable "main_kms_vault_type" {
    type = string
    description = "The vault type that you want to provision. Value is DEFAULT or VIRTUAL_PRIVATE or EXTERNAL. The DEFAULT is free forever."
}

# Provision a kms vault
resource "oci_kms_vault" "main_kms_vault" {
    #Required
	compartment_id = oci_identity_compartment.bootstrap_compartment.id
	display_name = var.main_kms_vault_display_name
	vault_type = var.main_kms_vault_type
}



# ====== Keys =========
# ---- Variables -----
variable "main_kms_key_display_name" {
  type = string
  description = "The display name of the main KMS Key used in the vault"
}

variable "key_key_shape_algorithm" {
  type        = string
  description = "The algorithm used for the key (e.g., AES, RSA, ECDSA)."
}

variable "key_key_shape_length" {
  type        = number
  description = "The length of the key in bytes."
}

variable "key_protection_mode" {
  type        = string
  description = "The protection mode of the key (HSM or SOFTWARE)."
  default     = "SOFTWARE"
}

variable "key_desired_state" {
  type        = string
  description = "The state you want the key to be in. Valid: ENABLED, DISABLED. Set this to DISABLED before you try to terraform destroy it."
  default     = "ENABLED"
}

# Provision a kms key that uses the vault
resource "oci_kms_key" "main_kms_key" {
    #Required
    compartment_id = oci_identity_compartment.bootstrap_compartment.id
    display_name = var.main_kms_key_display_name
    key_shape {
        #Required
        algorithm = var.key_key_shape_algorithm
        length = var.key_key_shape_length

        #Optional
        # only use this if you are using ECDSA key
        # curve_id = oci_kms_curve.test_curve.id
    }

    # we are using the vault's own generated management_endpoint so that we can keep track of it under the vault object
    management_endpoint = oci_kms_vault.main_kms_vault.management_endpoint

    #Optional
    # freeform_tags = {"Department"= "Finance"}
    # defined_tags = {"Operations.CostCenter"= "42"}
    desired_state = var.key_desired_state # set this to DISABLED and apply the tf change before you try to tf destroy
    protection_mode = var.key_protection_mode

    # not using auto key rotation as main_kms_vault_type = DEFAULT (aka VIRTUAL mode) does not support this
    # we will use a workaround with another terraform resource to rotate the key down below
    is_auto_rotation_enabled = false
    # auto_key_rotation_details {

    #     #Optional
    #     rotation_interval_in_days = var.key_auto_key_rotation_details_rotation_interval_in_days
    #     time_of_schedule_start = var.key_auto_key_rotation_details_time_of_schedule_start

    #     # These are updatable output messages (not really necessary to use them)
    #     # last_rotation_message = var.key_auto_key_rotation_details_last_rotation_message
    #     # last_rotation_status = var.key_auto_key_rotation_details_last_rotation_status
    #     # time_of_last_rotation = var.key_auto_key_rotation_details_time_of_last_rotation
    #     # time_of_next_rotation = var.key_auto_key_rotation_details_time_of_next_rotation
    # }

    # Not using external key reference as it is a paid feature
    # external_key_reference { 
    #     #Required
    #     external_key_id = oci_kms_key.main_kms_key.id
    # }




    # depends_on = [ oci_kms_vault.main_kms_vault, oci_identity_policy.objectstorage_kms_policy ]
}


# --- Key Rotation Logic ----
variable "key_auto_key_rotation_details_rotation_interval_in_days" {
  type        = number
  description = "The interval of key rotation in days."
  default     = 90
}

# 1. The Timer
resource "time_rotating" "wait_rotation_days" {
  rotation_days = var.key_auto_key_rotation_details_rotation_interval_in_days
}

# 2. The Trigger Logic
resource "terraform_data" "rotation_trigger" {
  input = time_rotating.wait_rotation_days.id
}

resource "oci_kms_key_version" "rotated_version" {
  key_id              = oci_kms_key.main_kms_key.id
  management_endpoint = oci_kms_vault.main_kms_vault.management_endpoint

  # Remove time_of_deletion unless you specifically want this version 
  # to disappear from the vault entirely after a certain date.
  # If you want to keep old versions for decryption, leave it out.

  lifecycle {
    # 1. Create the new version first
    create_before_destroy = true

    # 2. Trigger the replacement based on your timer
    replace_triggered_by = [
      terraform_data.rotation_trigger
    ]
  }

  # depends_on = [oci_kms_vault.main_kms_vault, oci_kms_key.main_kms_key ]

}