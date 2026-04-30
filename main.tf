
# ====== Version =====
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

# ===== Variables ======
variable "tenancy_ocid" { type = string }
variable "user_ocid" { type = string }
variable "fingerprint" { type = string }
variable "private_key_path" { type = string }
variable "region" { type = string }

# ====== Provider =====
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}


# ===== Compartments  =====
# define all the resources here
resource "oci_identity_compartment" "second_root_compartment" {
    # Required
    compartment_id = var.tenancy_ocid # change this to var.tenancy_ocid if you just want your minecraft server compartment to be under the root compartment else set it to a compartment id that you want this minecraft server to be in
    description = "Second Root Compartment. This compartment is just acts like another root compartment that allows for automated tear down of resources since the root compartment does not allow that"
    name = "second_root_compartment"
    enable_delete = true
}

# ========= IP ADDRESSES ============
resource "oci_core_public_ip" "main_reserved_public_ip" {
    #Required
    compartment_id = oci_identity_compartment.second_root_compartment.id
    lifetime = "RESERVED" # "RESERVED"  # Or "EPHEMERAL"

    #Optional
    # defined_tags = {"Operations.CostCenter"= "42"}
    display_name = "main-public-ip"
    # freeform_tags = {"Department"= "Finance"}
    # private_ip_id = oci_core_private_ip.test_private_ip.id
    # public_ip_pool_id = oci_core_public_ip_pool.test_public_ip_pool.id
}

# resource "oci_core_public_ip" "main_ephemeral_public_ip" {
#     #Required
#     compartment_id = oci_identity_compartment.second_root_compartment.id
#     lifetime = "EPHEMERAL"

#     #Optional
#     # defined_tags = {"Operations.CostCenter"= "42"}
#     display_name = "main-ephemeral-public-ip"
#     # freeform_tags = {"Department"= "Finance"}
#     # private_ip_id = oci_core_private_ip.test_private_ip.id
#     # public_ip_pool_id = oci_core_public_ip_pool.test_public_ip_pool.id
# }

