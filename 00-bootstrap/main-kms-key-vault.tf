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
    description = "The vault type that you want to provision. Value is VIRTUAL or VIRTUAL_PRIVATE. The 1st one is free forever."
}

# Provision a kms vault
resource "oci_kms_vault" "main_kms_vault" {
    #Required
	compartment_id = oci_identity_compartment.second_root_compartment.id
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

variable "key_is_auto_rotation_enabled" {
  type        = bool
  description = "Whether or not auto-rotation is enabled for this key."
  default     = false
}

variable "key_auto_key_rotation_details_rotation_interval_in_days" {
  type        = number
  description = "The interval of key rotation in days."
  default     = 90
}

variable "key_auto_key_rotation_details_time_of_schedule_start" {
  type        = string
  description = "The time the rotation schedule starts in RFC3339 format. Eg 2024-12-31T00:00:00Z"
  default     = null
}

# We are not using this cause its not necessary
# variable "key_auto_key_rotation_details_last_rotation_message" {
#   type        = string
#   description = "The message of the last rotation."
#   default     = null
# }

# variable "key_auto_key_rotation_details_last_rotation_status" {
#   type        = string
#   description = "The status of the last rotation."
#   default     = null
# }

# variable "key_auto_key_rotation_details_time_of_last_rotation" {
#   type        = string
#   description = "The time of the last rotation in RFC3339 format."
#   default     = null
# }

# variable "key_auto_key_rotation_details_time_of_next_rotation" {
#   type        = string
#   description = "The time of the next rotation in RFC3339 format."
#   default     = null
# }

variable "key_protection_mode" {
  type        = string
  description = "The protection mode of the key (HSM or SOFTWARE)."
  default     = "HSM"
}

# Provision a kms key that uses the vault
resource "oci_kms_key" "main_kms_key" {
    #Required
    compartment_id = oci_identity_compartment.second_root_compartment.id
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
    auto_key_rotation_details {

        #Optional
        rotation_interval_in_days = var.key_auto_key_rotation_details_rotation_interval_in_days
        time_of_schedule_start = var.key_auto_key_rotation_details_time_of_schedule_start

        # These are updatable output messages (not really necessary to use them)
        # last_rotation_message = var.key_auto_key_rotation_details_last_rotation_message
        # last_rotation_status = var.key_auto_key_rotation_details_last_rotation_status
        # time_of_last_rotation = var.key_auto_key_rotation_details_time_of_last_rotation
        # time_of_next_rotation = var.key_auto_key_rotation_details_time_of_next_rotation
    }
    # defined_tags = {"Operations.CostCenter"= "42"}

    # Not using external key reference as it is a paid feature
    # external_key_reference { 
    #     #Required
    #     external_key_id = oci_kms_key.main_kms_key.id
    # }
    # freeform_tags = {"Department"= "Finance"}

    is_auto_rotation_enabled = var.key_is_auto_rotation_enabled
    protection_mode = var.key_protection_mode

    depends_on = [ oci_kms_vault.main_kms_vault ]
}