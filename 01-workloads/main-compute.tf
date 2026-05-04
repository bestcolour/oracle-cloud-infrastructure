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

# 5. Provision the Compute Instance
resource "oci_core_instance" "reverse_proxy_vm" {
  availability_domain = var.region
  compartment_id      = oci_identity_compartment.data_arch_compartment.id
  display_name        = var.reverse_proxy_vm_name
  shape               = var.free_forever_compute_shape

  shape_config {
    memory_in_gbs = var.reverse_proxy_vm_memory
    ocpus         = var.reverse_proxy_vm_ocpus
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.main_vcn_public_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = var.reverse_proxy_vm_source_id # e.g., Oracle Linux 8
  }

  metadata = {
    # We pass the PUBLIC key generated in Step 1 to the instance
    ssh_authorized_keys = tls_private_key.reverse_proxy_vm_ssh_key.public_key_openssh
  }

  depends_on = [ tls_private_key.reverse_proxy_vm_ssh_key ]
}