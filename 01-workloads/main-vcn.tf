# ====== VCN ==========
# ----- Variables -----
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

# ------ Module Definition ------
# Source from https://registry.terraform.io/modules/oracle-terraform-modules/vcn/oci/
# Guide from https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-vcn.htm
module "main_vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.6.0"

  # Required Inputs
  compartment_id = oci_identity_compartment.data_arch_compartment.id

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

  depends_on = [ oci_identity_compartment.data_arch_compartment]
}

# ---- Output -----
# Outputs for the vcn module
output "vcn_id" {
  description = "OCID of the VCN that is created"
  value = module.main_vcn.vcn_id
}
output "id_for_route_table_that_includes_the_internet_gateway" {
  description = "OCID of the internet-route table. This route table has an internet gateway to be used for public subnets"
  value = module.main_vcn.ig_route_id
}


# ====== Private Subnet Security List ==========
# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list
resource "oci_core_security_list" "main_vcn_private_security_list"{

  # Required
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  vcn_id = module.main_vcn.vcn_id

  # Optional
  display_name = "${var.vcn_name}-private-subnet-security-list"

  # EGRESS SECURITY RULES GUIDE: https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-vcn.htm#customize-network
  egress_security_rules {
        stateless = false
        destination = "0.0.0.0/0" # change this a Service CIDR if you wish to communicate between oracle services (eg databases)
        destination_type = "CIDR_BLOCK"
        protocol = "all" 
    }

  # INGRESS SECURITY RULES GUIDE: https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-vcn.htm#customize-network
  ingress_security_rules { 
      stateless = false
      source = "10.0.0.0/16"
      source_type = "CIDR_BLOCK"
      # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
      protocol = "6"
      tcp_options { 
          min = 22
          max = 22
      }
    }

  ingress_security_rules { 
      stateless = false
      source = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"
      # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
      protocol = "1"
  
      # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
      icmp_options {
        type = 3
        code = 4
      } 
    }   
  
  ingress_security_rules { 
      stateless = false
      source = "10.0.0.0/16"
      source_type = "CIDR_BLOCK"
      # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
      protocol = "1"
  
      # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
      icmp_options {
        type = 3
      } 
    }

    depends_on = [ oci_identity_compartment.data_arch_compartment ]
}


output "private_security_list_name" {
  value = oci_core_security_list.main_vcn_private_security_list.display_name
}
output "private_security_list_OCID" {
  value = oci_core_security_list.main_vcn_private_security_list.id
}




# ====== Private Subnet ==============
# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet
variable "main_vcn_private_subnet_dns_label" {
  type = string
}

resource "oci_core_subnet" "main_vcn_private_subnet"{

  # Required
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  vcn_id = module.main_vcn.vcn_id
  cidr_block = "10.0.1.0/24"
  dns_label = var.main_vcn_private_subnet_dns_label
  # Optional
  # Caution: For the route table id, use module.vcn.nat_route_id.
  # Do not use module.vcn.nat_gateway_id, because it is the OCID for the gateway and not the route table.
  route_table_id = module.main_vcn.nat_route_id
  security_list_ids = [oci_core_security_list.main_vcn_private_security_list.id]
  display_name = "${var.vcn_name}-private-subnet"

  depends_on = [ oci_identity_compartment.data_arch_compartment ]
}


# ------ Outputs for private subnet -------------
output "private-subnet-name" {
  value = oci_core_subnet.main_vcn_private_subnet.display_name
}
output "private-subnet-OCID" {
  value = oci_core_subnet.main_vcn_private_subnet.id
}


# ====== Public Subnet Security List ==========
# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list
resource "oci_core_security_list" "main_vcn_public_security_list"{

  # Required
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  vcn_id = module.main_vcn.vcn_id

  # Optional
  display_name = "${var.vcn_name}-public-subnet-security-list"

  # EGRESS SECURITY RULES GUIDE: https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-vcn.htm#customize-network
  egress_security_rules {
        stateless = false
        destination = "0.0.0.0/0" # change this a Service CIDR if you wish to communicate between oracle services (eg databases)
        destination_type = "CIDR_BLOCK"
        protocol = "all" 
    }

  # INGRESS SECURITY RULES GUIDE: https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-vcn.htm#customize-network
  ingress_security_rules { 
      stateless = false
      source = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"
      # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
      protocol = "6"
      tcp_options { 
          min = 22
          max = 22
      }
    }

  ingress_security_rules { 
      stateless = false
      source = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"
      # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
      protocol = "1"
  
      # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
      icmp_options {
        type = 3
        code = 4
      } 
    }   
  
  ingress_security_rules { 
      stateless = false
      source = "10.0.0.0/16"
      source_type = "CIDR_BLOCK"
      # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
      protocol = "1"
  
      # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
      icmp_options {
        type = 3
      } 
    }

    depends_on = [ oci_identity_compartment.data_arch_compartment ]
}

# Outputs for public security list
output "public_security_list_name" {
  value = oci_core_security_list.main_vcn_public_security_list.display_name
}
output "public_security_list_OCID" {
  value = oci_core_security_list.main_vcn_public_security_list.id
}


# ====== Public Subnet ==========
variable "main_vcn_public_subnet_dns_label" {
  type = string
}

# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet
resource "oci_core_subnet" "main_vcn_public_subnet"{

  # Required
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  vcn_id = module.main_vcn.vcn_id
  cidr_block = "10.0.0.0/24"
  dns_label = var.main_vcn_public_subnet_dns_label
 
  # Optional
  route_table_id = module.main_vcn.ig_route_id
  security_list_ids = [oci_core_security_list.main_vcn_public_security_list.id]
  display_name = "${var.vcn_name}-public-subnet"
  
  depends_on = [ oci_identity_compartment.data_arch_compartment ]
}

# Outputs for public subnet
output "public_subnet_name" {
  value = oci_core_subnet.main_vcn_public_subnet.display_name
}
output "public_subnet_OCID" {
  value = oci_core_subnet.main_vcn_public_subnet.id
}