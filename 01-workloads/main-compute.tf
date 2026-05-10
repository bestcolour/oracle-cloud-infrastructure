# https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-compute.htm

# ===== Reverse Proxy Instance =========
# --- Variables ---
variable "kms_main_vault_ocid" {
  type = string 
  description = "The ocid of the main kms vault provisioned in the bootstrap terraform project."
}
variable "kms_main_key_ocid" {
  type = string 
  description = "The ocid of the main kms key provisioned in the bootstrap terraform project."
}

variable "free_forever_compute_shape" {
  type = string 
  default = "VM.Standard.A1.Flex"
  description = "The shape of the compute which is free forever. Eg. VM.Standard.A1.Flex"
}

variable "reverse_proxy_vm_ssh_key_secret_name" {
  type = string 
  description = "The ocid of the main kms key provisioned in the bootstrap terraform project."
}
variable "reverse_proxy_vm_name" {
  type = string 
  description = "The name of the compute instance provisioned for the role of a reverse proxy"
}
variable "reverse_proxy_vm_memory" {
  type = number 
  description = "The memory of the compute instance provisioned for the role of a reverse proxy"
}
variable "reverse_proxy_vm_ocpus" {
  type = number 
  description = "The ocpus of the compute instance provisioned for the role of a reverse proxy"
}
variable "reverse_proxy_vm_source_id" {
  type = string 
  description = "The image id of the os image you want your vm instance to use. Find your this value here https://docs.oracle.com/en-us/iaas/images/ > choose the image you want to use > copy the link based on your region"
}
variable "reverse_proxy_vm_assign_public_ip" {
  type = bool 
  description = "Whether the VNIC should be assigned a public IP address. Defaults to whether the subnet is public or private. If not set and the VNIC is being created in a private subnet (that is, where prohibitPublicIpOnVnic = true in the Subnet), then no public IP address is assigned. If not set and the subnet is public (prohibitPublicIpOnVnic = false), then a public IP address is assigned. If set to true and prohibitPublicIpOnVnic = true, an error is returned"
}
variable "reverse_proxy_vm_hostname_label" {
  type = string 
  description = "The hostname for the VNIC's primary private IP. Used for DNS. The value is the hostname portion of the primary private IP's fully qualified domain name (FQDN) (for example, bminstance1 in FQDN bminstance1.subnet123.vcn1.oraclevcn.com). Must be unique across all VNICs in the subnet and comply with RFC 952 and RFC 1123. The value appears in the Vnic object and also the PrivateIp object returned by ListPrivateIps and GetPrivateIp."
}



# --- Resources ---
# 1. Generate the SSH Key Pair in memory
resource "tls_private_key" "reverse_proxy_vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 4. Store the Private Key as a Secret in the Vault
resource "oci_vault_secret" "reverse_proxy_vm_ssh_key_secret" {
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  vault_id       = var.kms_main_vault_ocid
  key_id         = var.kms_main_key_ocid
  secret_name    = var.reverse_proxy_vm_ssh_key_secret_name

  secret_content {
    content_type = "BASE64"
    content      = base64encode(tls_private_key.reverse_proxy_vm_ssh_key.private_key_pem)
  }
  depends_on = [ tls_private_key.reverse_proxy_vm_ssh_key ]
}

resource "oci_core_instance" "reverse_proxy_vm" {
    #Required
    availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
    compartment_id      = oci_identity_compartment.data_arch_compartment.id
    display_name        = var.reverse_proxy_vm_name
    shape               = var.free_forever_compute_shape

    create_vnic_details {

        #Optional
        # assign_ipv6ip = var.instance_create_vnic_details_assign_ipv6ip
        # assign_private_dns_record = var.instance_create_vnic_details_assign_private_dns_record
        assign_public_ip = var.reverse_proxy_vm_assign_public_ip
        # defined_tags = {"Operations.CostCenter"= "42"}
        # display_name = var.instance_create_vnic_details_display_name
        # freeform_tags = {"Department"= "Finance"}
        hostname_label = var.reverse_proxy_vm_hostname_label

        # security_attributes = var.reverse_proxy_vm_security_attributes # not using since this is outside of free forever tier

        subnet_id = oci_core_subnet.main_vcn_public_subnet.id
    }


    # security_attributes = var.reverse_proxy_vm_security_attributes # not using since this is outside of free forever tier
    # shape = var.instance_shape
    shape_config {
      memory_in_gbs = var.reverse_proxy_vm_memory
      ocpus         = var.reverse_proxy_vm_ocpus
    }
    source_details {
        #Required
        source_id = var.reverse_proxy_vm_source_id
        source_type = "image"

        # #Optional
        # boot_volume_size_in_gbs = var.instance_source_details_boot_volume_size_in_gbs
        # boot_volume_vpus_per_gb = var.instance_source_details_boot_volume_vpus_per_gb
        # instance_source_image_filter_details {
        #     #Required
        #     compartment_id = var.compartment_id

        #     #Optional
        #     defined_tags_filter = var.instance_source_details_instance_source_image_filter_details_defined_tags_filter
        #     operating_system = var.instance_source_details_instance_source_image_filter_details_operating_system
        #     operating_system_version = var.instance_source_details_instance_source_image_filter_details_operating_system_version
        # }
        # kms_key_id = oci_kms_key.test_key.id
    }
    metadata = {
      ssh_authorized_keys = tls_private_key.reverse_proxy_vm_ssh_key.public_key_openssh
    }
    preserve_boot_volume = false
      

  depends_on = [ tls_private_key.reverse_proxy_vm_ssh_key ]
}