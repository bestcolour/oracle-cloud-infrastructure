# This file will contain the necessary tf code to provision a compartment to organise whatever cloud resources there is to provision in the bootstrap project.
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

# ===== Compartments  =====
variable "second_root_compartment_name" { type = string }
variable "bootstrap_compartment_name" { type = string }


# define all the resources here
resource "oci_identity_compartment" "second_root_compartment" {
    # Required
    compartment_id = var.tenancy_ocid # change this to var.tenancy_ocid if you just want your minecraft server compartment to be under the root compartment else set it to a compartment id that you want this minecraft server to be in
    description = "Designated Name: ${var.second_root_compartment_name}\nPurpose: Second Root Compartment. This compartment is just acts like another root compartment that allows for automated tear down of resources since the root compartment does not allow that"
    name = var.second_root_compartment_name
    enable_delete = true
}


# define all the resources here
resource "oci_identity_compartment" "bootstrap_compartment" {
    # Required
    compartment_id = oci_identity_compartment.second_root_compartment.id 
    description = "Designated Name: ${var.bootstrap_compartment_name}\nPurpose: Bootstrap Compartment. This compartment holds all the cloud resources that are provisioned in during the bootstrap terraform apply process"
    name = var.bootstrap_compartment_name
    enable_delete = true
}
