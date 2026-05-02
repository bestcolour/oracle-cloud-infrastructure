
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
# this is where we register oracle cloud as our cloud platform provider
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}


# # ===== Backend =====
# # this is used for syncing the terraform tf state file with oracle cloud's object storage
# # This ensures the terraform state file is centralized and protected by OCI's security layers.
# terraform {
#   backend "oci" {
#     bucket    = "terraform-state-bucket"
#     namespace = "your-tenancy-namespace"
#     region    = var.region
#     key       = "network/terraform.tfstate"
#   }
# }




# # ===== Compartments  =====
# # define all the resources here
# resource "oci_identity_compartment" "data_arch_compartment" {
#     # Required
#     compartment_id = oci_identity_compartment.second_root_compartment
#     description = "This compartment holds the cloud resources that are provisioned for the main cloud architecture"
#     name = "data-arch-compartment"
#     enable_delete = true
# }

# # ========= IP ADDRESSES ============
# # https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_public_ip#lifetime-7
# resource "oci_core_public_ip" "main_reserved_public_ip" {
#     #Required
#     compartment_id = oci_identity_compartment.second_root_compartment.id
#     lifetime = "RESERVED" # "RESERVED"  # Or "EPHEMERAL"

#     #Optional
#     # defined_tags = {"Operations.CostCenter"= "42"}
#     display_name = "main-public-ip"
#     # freeform_tags = {"Department"= "Finance"}
#     # private_ip_id = oci_core_private_ip.test_private_ip.id
#     # public_ip_pool_id = oci_core_public_ip_pool.test_public_ip_pool.id
# }

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

