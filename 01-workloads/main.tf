
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


# ===== Backend =====
# this is used for syncing the terraform tf state file with oracle cloud's object storage
# This ensures the terraform state file is centralized and protected by OCI's security layers.
# this is left blank on purpose to allow another .tfvars file called "backend-config.tfvars" to fill up the details
# to init with this file, use:
# terraform init -backend-config="backend-config.tfvars"
terraform {
  backend "oci" {

  }
}

# ==== availability domains =====
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}


# ===== Compartments  =====
variable "second_root_compartment_ocid" {
  type = string 
  description = "The ocid of the sub-compartment of the root compartment."
}

# define all the resources here
resource "oci_identity_compartment" "data_arch_compartment" {
    # Required
    compartment_id = var.second_root_compartment_ocid
    description = "This compartment holds the cloud resources that are provisioned for the main cloud architecture"
    name = "data-arch-compartment"
    enable_delete = true
}

# ========= IP ADDRESSES ============
# https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_public_ip#lifetime-7
resource "oci_core_public_ip" "main_reserved_public_ip" {
    #Required
    compartment_id = oci_identity_compartment.data_arch_compartment.id
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
#     compartment_id = oci_identity_compartment.data_arch_compartment.id
#     lifetime = "EPHEMERAL"

#     #Optional
#     # defined_tags = {"Operations.CostCenter"= "42"}
#     display_name = "main-ephemeral-public-ip"
#     # freeform_tags = {"Department"= "Finance"}
#     # private_ip_id = oci_core_private_ip.test_private_ip.id
#     # public_ip_pool_id = oci_core_public_ip_pool.test_public_ip_pool.id
# }

