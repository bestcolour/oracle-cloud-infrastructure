# https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-compute.htm

# ===== Reverse Proxy Instance =========
# --- oci related Variables ---
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

# --- cloud-init script related Variables ---
# NETWORK CONFIGURATION 
variable "your_tcp_ports" {
  type        = list(string)
  description = "A list of TCP ports to open for the security configuration (e.g., ['80', '443'])."
  default     = ["80", "443"]
}

#  DUCKDNS CONFIGURATION 

variable "your_duckdns_token" {
  type        = string
  description = "The API token provided by DuckDNS for dynamic DNS updates."
  sensitive   = true
}

variable "your_duckdns_domainname" {
  type        = string
  description = "The subdomain part of your DuckDNS configuration (just the name, excluding '.duckdns.org')."
}

#  DOMAIN & BACKEND CONFIGURATION 

variable "your_base_domain" {
  type        = string
  description = "The top-level base domain name (e.g., 'example.com') used to derive subdomains."
}

variable "headscale_private_ip_n_port" {
  type        = string
  description = "The internal IP address and port for the Headscale backend (e.g., '10.0.1.10:8080')."
}

variable "projects_private_ip_n_port" {
  type        = string
  description = "The internal IP address and port for the side-projects backend (e.g., '10.0.1.20:8080')."
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
        nsg_ids = [oci_core_network_security_group.reverse_proxy_network_security_group.id]
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
      user_data = base64encode(
        templatefile("${path.module}/main-compute-setup-reverse-proxy.sh.tpl",
        {
          your_tcp_ports = join(" ", var.your_tcp_ports)
          your_duckdns_token= var.your_duckdns_token
          your_duckdns_domainname= var.your_duckdns_domainname
          your_base_domain= var.your_base_domain
          headscale_private_ip_n_port= var.headscale_private_ip_n_port
          projects_private_ip_n_port= var.projects_private_ip_n_port        
        }
        )
      )
    }
    preserve_boot_volume = false
      

  depends_on = [ tls_private_key.reverse_proxy_vm_ssh_key, oci_core_network_security_group.reverse_proxy_network_security_group ]
}


# ===== Reverse Proxy Instance - IP Address =========
# IP Address Provisioning and Allocation
variable "reverse_proxy_vm_ip_display_name" {
  type = string 
  description = "The display name for the ip address provisioned for the reverse proxy vm"
}

# 1. Get the VNIC ID from your existing instance
data "oci_core_vnic_attachments" "reverse_proxy_vm_vnics" {
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  instance_id    = oci_core_instance.reverse_proxy_vm.id
}

# 2. Get the specific Private IP details
data "oci_core_private_ips" "reverse_proxy_vm_primary_ip_search" {
  vnic_id = data.oci_core_vnic_attachments.reverse_proxy_vm_vnics.vnic_attachments[0].vnic_id
}

# https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_public_ip#lifetime-7
# This is the public ip that is reserved for the computing instance
resource "oci_core_public_ip" "main_reserved_public_ip" {
    #Required
    compartment_id = oci_identity_compartment.data_arch_compartment.id
    lifetime = "RESERVED" # "RESERVED"  # Or "EPHEMERAL"

    #Optional
    # defined_tags = {"Operations.CostCenter"= "42"}
    display_name = var.reverse_proxy_vm_ip_display_name

    # this is the private ip's ocid found from the vnic when the reverse proxy computing instance was provisioned
    private_ip_id = data.oci_core_private_ips.reverse_proxy_vm_primary_ip_search.private_ips[0].id
    # freeform_tags = {"Department"= "Finance"}
    # public_ip_pool_id = oci_core_public_ip_pool.test_public_ip_pool.id
    depends_on = [ oci_core_instance.reverse_proxy_vm ]
}


# ===== Reverse Proxy Instance - Network Security Group & Attributes =========
variable "reverse_proxy_NSG_display_name" {
  type = string
  description = "The display name for the reverse proxy's Network Security Group resource"
}

# This network security group will be used for the public facing vm instance
# https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group
resource "oci_core_network_security_group" "reverse_proxy_network_security_group" {
    #Required
    compartment_id = oci_identity_compartment.data_arch_compartment.id
    vcn_id = module.main_vcn.vcn_id

    #Optional
    # defined_tags = {"Operations.CostCenter"= "42"}
    display_name = var.reverse_proxy_NSG_display_name
    # freeform_tags = {"Department"= "Finance"}
}

variable "private_NSG_display_name" {
  type = string
  description = "The display name for the reverse proxy's recipient Network Security Group resource. The recipient of the reverse proxy's directed traffic include the Headscale control server VM and the other project VM"
}

# This network security group will be used for the private facing vm instances (the Headscale vm and the project vm)
# https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group
resource "oci_core_network_security_group" "private_network_security_group" {
    #Required
    compartment_id = oci_identity_compartment.data_arch_compartment.id
    vcn_id = module.main_vcn.vcn_id

    #Optional
    # defined_tags = {"Operations.CostCenter"= "42"}
    display_name = var.private_NSG_display_name
    # freeform_tags = {"Department"= "Finance"}
}


# =============================================================================
# SECURITY RULES FOR REVERSE PROXY NSG <--> RECIPIENT (PRIVATE) NSG
# =============================================================================

# -----------------------------------------------------------------------------
# 1. REVERSE PROXY NSG RULES
# -----------------------------------------------------------------------------

# Allow Reverse Proxy to send traffic out to the Private VMs
# By using a map of objects, your security architecture easily scales. If you later decide to add a completely different application that doesn't use web standards
# for example, a custom API on port 5000 can be mapped from an external port 8000 without needing you to touch your NSG code at all.

variable "reverse_proxy_forwarding_rules" {
  type = map(object({
    public_port  = number
    backend_port = number
  }))

  default = {
    "http" = {
      public_port  = 80
      backend_port = 8080
    },
    "https" = {
      public_port  = 443
      backend_port = 8443
    },
    # Just add a new block to your variable inputs; Terraform handles the rest automatically
    # "custom_api" = {
    # public_port  = 8000
    # backend_port = 5000
    # }

  }
}

# 1. Public Proxy NSG (Egress to Private Subnet)
# This rule tells the proxy: "You are allowed to talk to the private VMs, 
# but ONLY on the specific backend ports they are listening on."
resource "oci_core_network_security_group_security_rule" "proxy_to_private_egress" {
  for_each                  = var.reverse_proxy_forwarding_rules
  network_security_group_id = oci_core_network_security_group.reverse_proxy_network_security_group.id
  direction                 = "EGRESS"
  protocol                  = "6" # TCP

  destination_type = "NETWORK_SECURITY_GROUP"
  destination      = oci_core_network_security_group.private_network_security_group.id

  tcp_options {
    destination_port_range {
      # We use backend_port because that's where the traffic is going
      min = each.value.backend_port
      max = each.value.backend_port
    }
  }
}

# 2. Private Backend NSG (Ingress from Proxy Subnet)
# This rule tells the private VMs: "You may accept incoming traffic from the proxy, 
# but only on your designated backend ports."
resource "oci_core_network_security_group_security_rule" "private_from_proxy_ingress" {
  for_each                  = var.reverse_proxy_forwarding_rules
  network_security_group_id = oci_core_network_security_group.private_network_security_group.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  source_type = "NETWORK_SECURITY_GROUP"
  source      = oci_core_network_security_group.reverse_proxy_network_security_group.id

  tcp_options {
    destination_port_range {
      min = each.value.backend_port
      max = each.value.backend_port
    }
  }
}

# =============================================================================
# PUBLIC FACING INGRESS RULES FOR REVERSE PROXY NSG
# =============================================================================

# Allow HTTP Ingress traffic from anywhere on the internet (Required for Certbot validation)
resource "oci_core_network_security_group_security_rule" "reverse_proxy_http_ingress" {
  network_security_group_id = oci_core_network_security_group.reverse_proxy_network_security_group.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

# Allow HTTPS Ingress traffic from anywhere on the internet
resource "oci_core_network_security_group_security_rule" "reverse_proxy_https_ingress" {
  network_security_group_id = oci_core_network_security_group.reverse_proxy_network_security_group.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}
