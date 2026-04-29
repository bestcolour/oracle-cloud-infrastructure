
# ===== Variables =====
variable "vcn_name" { 
    type = string 
    description = "The name for the VCN that will be provisioned within the second root compartment"
}

variable "vcn_dns_label" {
  type = string
  description = "The vcn_dns_label is part of the format that oracle uses to form a public address when one of your cloud server exposes it self to the public internet. The format is: 'hostname.subnet_dns_label.vcn_dns_label.oraclevcn.com'."
}

variable "vcn_cidr_blocks" {
    type = list(string)
    description = "The list of one or more IPv4 CIDR blocks for the VCN. Read more at https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn#cidr_blocks-1"
    default = ["10.0.0.0/16"]
}

# ====== Module Definition ======
# Source from https://registry.terraform.io/modules/oracle-terraform-modules/vcn/oci/
# Guide from https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-vcn.htm
module "vcn-1" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.6.0"

  # Required Inputs
  compartment_id = oci_identity_compartment.second-root-compartment.compartment_id

  # Optional Inputs 
  region = var.region
  
  # Changing the following default values
  vcn_name = var.vcn_name
  create_internet_gateway = true
#   create_nat_gateway = true
#   create_service_gateway = true

  # Using the following default values
  vcn_dns_label = var.vcn_dns_label
  vcn_cidrs = var.vcn_cidr_blocks

  depends_on = [ oci_identity_compartment.second-root-compartment ]
}

# ==== Output =====
# Outputs for the vcn module
output "vcn_id" {
  description = "OCID of the VCN that is created"
  value = module.vcn-1.vcn_id
}
output "id-for-route-table-that-includes-the-internet-gateway" {
  description = "OCID of the internet-route table. This route table has an internet gateway to be used for public subnets"
  value = module.vcn-1.ig_route_id
}
