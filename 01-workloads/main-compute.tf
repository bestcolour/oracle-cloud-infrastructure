# https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-compute.htm

# === oci related Variables ===
variable "kms_main_vault_ocid" {
  type = string 
  description = "The ocid of the main kms vault provisioned in the bootstrap terraform project."
}
variable "kms_main_key_ocid" {
  type = string 
  description = "The ocid of the main kms key provisioned in the bootstrap terraform project."
}

variable "free_forever_AMD_compute_shape" {
  type = string 
  default = "VM.Standard.E2.1.Micro"
  description = "The shape of the AMD compute which is free forever. Eg. VM.Standard.E2.1.Micro"
}

variable "free_forever_ARM_compute_shape" {
  type = string 
  default = "VM.Standard.A1.Flex"
  description = "The shape of the ARM compute which is free forever. Eg. VM.Standard.A1.Flex"
}

# # ===== Secure Web Gateway Instance - ssh key pair =========
variable "secure_web_gateway_vm_ssh_key_secret_name" {
  type = string 
  description = "The secret name assigned for this key to be stored in the oracle vault."
}

# 1. Generate the SSH Key Pair in memory
resource "tls_private_key" "secure_web_gateway_vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 4. Store the Private Key as a Secret in the Vault
resource "oci_vault_secret" "secure_web_gateway_vm_ssh_key_secret" {
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  vault_id       = var.kms_main_vault_ocid
  key_id         = var.kms_main_key_ocid
  secret_name    = var.secure_web_gateway_vm_ssh_key_secret_name

  secret_content {
    content_type = "BASE64"
    content      = base64encode(tls_private_key.secure_web_gateway_vm_ssh_key.private_key_pem)
  }
  depends_on = [ tls_private_key.secure_web_gateway_vm_ssh_key ]
}

# ===== Headscale Instance - ssh key pair =========
variable "headscale_vm_ssh_key_secret_name" {
  type        = string 
  description = "The secret name assigned for this key to be stored in the oracle vault."
}

# 1. Generate the SSH Key Pair in memory
resource "tls_private_key" "headscale_vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 4. Store the Private Key as a Secret in the Vault
resource "oci_vault_secret" "headscale_vm_ssh_key_secret" {
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  vault_id       = var.kms_main_vault_ocid
  key_id         = var.kms_main_key_ocid
  secret_name    = var.headscale_vm_ssh_key_secret_name

  secret_content {
    content_type = "BASE64"
    content      = base64encode(tls_private_key.headscale_vm_ssh_key.private_key_pem)
  }
  depends_on = [ tls_private_key.headscale_vm_ssh_key ]
}

# ===== Game Server Instance - ssh key pair =========
variable "gameserver_vm_ssh_key_secret_name" {
  type        = string 
  description = "The secret name assigned for this key to be stored in the oracle vault."
}

# 1. Generate the SSH Key Pair in memory
resource "tls_private_key" "gameserver_vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 4. Store the Private Key as a Secret in the Vault
resource "oci_vault_secret" "gameserver_vm_ssh_key_secret" {
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  vault_id       = var.kms_main_vault_ocid
  key_id         = var.kms_main_key_ocid
  secret_name    = var.gameserver_vm_ssh_key_secret_name

  secret_content {
    content_type = "BASE64"
    content      = base64encode(tls_private_key.gameserver_vm_ssh_key.private_key_pem)
  }
  depends_on = [ tls_private_key.gameserver_vm_ssh_key ]
}

# ===== Game Server Instance - pterodactyl app key =========
variable "gameserver_pterodactyl_app_key_secret_name" {
  type        = string 
  description = "The secret name assigned for this key to be stored in the oracle vault."
}

# 1. Generate a random 32-character base64 string for the App Key
resource "random_id" "gameserver_pterodactyl_app_key" {
  byte_length = 24 # 24 bytes results in a 32-character base64 string
}

# 2. Store that generated key in the OCI Vault
resource "oci_vault_secret" "gameserver_pterodactyl_app_key_secret" {
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  vault_id       = var.kms_main_vault_ocid
  key_id         = var.kms_main_key_ocid
  secret_name    = var.gameserver_pterodactyl_app_key_secret_name

  secret_content {
    content_type = "BASE64"
    # Convert the random hex ID to base64 format for Pterodactyl
    content      = base64encode(random_id.gameserver_pterodactyl_app_key.b64_std)
  }
}

# ===== Game Server Instance - pterodactyl db password =========
variable "gameserver_pterodactyl_db_password_secret_name" {
  type        = string 
  description = "The secret name assigned for this key to be stored in the oracle vault."
}

# 1. Generate a strong, random database password
resource "random_password" "gameserver_pterodactyl_db_password" {
  length           = 32
  special          = true
  override_special = "!#%&*()-_=+[]{}<>:?"
}

# 2. Store in OCI Vault
resource "oci_vault_secret" "gameserver_pterodactyl_db_password_secret" {
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  vault_id       = var.kms_main_vault_ocid
  key_id         = var.kms_main_key_ocid
  secret_name    = var.gameserver_pterodactyl_db_password_secret_name

  secret_content {
    content_type = "BASE64"
    content      = base64encode(random_password.gameserver_pterodactyl_db_password.result)
  }
}


########################################################################################################################
# EVERYTHING FROM HERE ONWARDS CAN BE COMMENTED OUT TO TF DESTROY/REPROVISION WITHOUT CHANGING TFVAR VALUE
########################################################################################################################

# ===== Cloud Init Variables - Domain & backend configuration =====
# Network configuration
variable "your_reverse_proxy_tcp_ports" {
  type        = list(string)
  description = "A list of TCP ports to open for the security configuration (e.g., ['80', '443'])."
  default     = ["80", "443"]
}

# DuckDNS configuration
variable "your_duckdns_token" {
  type        = string
  description = "The API token provided by DuckDNS for dynamic DNS updates."
  sensitive   = true
}

variable "your_duckdns_domainname" {
  type        = string
  description = "The subdomain part of your DuckDNS configuration (just the name, excluding '.duckdns.org')."
}

# Domain & backend configuration
variable "your_secure_web_gateway_base_domain" {
  type        = string
  description = "The top-level base domain name (e.g., 'example.com') used to derive subdomains."
}

variable "your_headscale_subdomain_name" {
  type        = string
  description = "e.g., 'headscale'. So the full subdomain will look like 'headscale.example.com'"
}

variable "your_project_1_subdomain_name" {
  type        = string
  description = "e.g., 'test'. So the full subdomain will look like 'test.example.com'"
}

variable "headscale_port" {
  type        = string
  description = "The port for the headscale backend (e.g., '8080')."
}

variable "projects_private_ip_n_port" {
  type        = string
  description = "The internal IP address and port for the side-projects backend (e.g., '10.0.1.20:8080')."
}

variable "your_cert_email" {
  type        = string
  description = "Email assigned the the automated cert retrieval process."
}

# Headscale Setup
variable "your_headscale_version" {
  type = string 
  description = "The version of headscale to install. It is advised to choose a stable version. Releases can be found here https://headscale.net/stable/about/releases/"
}

# ===== Secure Web Gateway Instance =========
# --- computing instance related Variables ---

variable "secure_web_gateway_vm_name" {
  type = string 
  description = "The name of the compute instance provisioned for the role of a secure web gateway"
}
variable "secure_web_gateway_vm_memory" {
  type = number 
  description = "The memory of the compute instance provisioned for the role of a secure web gateway"
}
variable "secure_web_gateway_vm_ocpus" {
  type = number 
  description = "The ocpus of the compute instance provisioned for the role of a secure web gateway"
}
variable "secure_web_gateway_vm_source_id" {
  type = string 
  description = "The image id of the os image you want your vm instance to use. Find your this value here https://docs.oracle.com/en-us/iaas/images/ > choose the image you want to use > copy the link based on your region"
}
variable "secure_web_gateway_vm_assign_public_ip" {
  type = bool 
  description = "Whether the VNIC should be assigned a public IP address. Defaults to whether the subnet is public or private. If not set and the VNIC is being created in a private subnet (that is, where prohibitPublicIpOnVnic = true in the Subnet), then no public IP address is assigned. If not set and the subnet is public (prohibitPublicIpOnVnic = false), then a public IP address is assigned. If set to true and prohibitPublicIpOnVnic = true, an error is returned"
}
variable "secure_web_gateway_vm_hostname_label" {
  type = string 
  description = "The hostname for the VNIC's primary private IP. Used for DNS. The value is the hostname portion of the primary private IP's fully qualified domain name (FQDN) (for example, bminstance1 in FQDN bminstance1.subnet123.vcn1.oraclevcn.com). Must be unique across all VNICs in the subnet and comply with RFC 952 and RFC 1123. The value appears in the Vnic object and also the PrivateIp object returned by ListPrivateIps and GetPrivateIp."
}
variable "secure_web_gateway_static_private_ip" {
  type        = string
  description = "The static private IP assigned to the Secure Web Gateway (must be within the public subnet CIDR)."
  # Example: default = "10.0.0.10" 
}



# --- computing core instance ---
resource "oci_core_instance" "secure_web_gateway_vm" {
    #Required
    availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
    compartment_id      = oci_identity_compartment.data_arch_compartment.id
    display_name        = var.secure_web_gateway_vm_name
    shape               = var.free_forever_ARM_compute_shape

    create_vnic_details {

        #Optional
        # assign_ipv6ip = var.instance_create_vnic_details_assign_ipv6ip
        # assign_private_dns_record = var.instance_create_vnic_details_assign_private_dns_record
        assign_public_ip = var.secure_web_gateway_vm_assign_public_ip
        # defined_tags = {"Operations.CostCenter"= "42"}
        # display_name = var.instance_create_vnic_details_display_name
        # freeform_tags = {"Department"= "Finance"}
        hostname_label = var.secure_web_gateway_vm_hostname_label
        nsg_ids = [oci_core_network_security_group.secure_web_gateway_network_security_group.id]
        # security_attributes = var.secure_web_gateway_vm_security_attributes # not using since this is outside of free forever tier

        subnet_id = oci_core_subnet.main_vcn_public_subnet.id
        private_ip = var.secure_web_gateway_static_private_ip
    }


    # security_attributes = var.secure_web_gateway_vm_security_attributes # not using since this is outside of free forever tier
    # shape = var.instance_shape
    shape_config {
      memory_in_gbs = var.secure_web_gateway_vm_memory
      ocpus         = var.secure_web_gateway_vm_ocpus
    }
    source_details {
        #Required
        source_id = var.secure_web_gateway_vm_source_id
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
      ssh_authorized_keys = tls_private_key.secure_web_gateway_vm_ssh_key.public_key_openssh
      user_data = base64encode(
        templatefile("${path.module}/main-compute-setup-secure-web-gateway.sh.tpl",
        {
          your_reverse_proxy_tcp_ports = join(" ", var.your_reverse_proxy_tcp_ports)
          your_duckdns_token= var.your_duckdns_token
          your_duckdns_domainname= var.your_duckdns_domainname
          your_secure_web_gateway_base_domain= var.your_secure_web_gateway_base_domain
          your_headscale_subdomain_name= var.your_headscale_subdomain_name
          your_project_1_subdomain_name= var.your_project_1_subdomain_name
          headscale_private_ip_n_port   = "${var.headscale_static_private_ip}:${var.headscale_port}"
          projects_private_ip_n_port= var.projects_private_ip_n_port    
          forward_proxy_port=var.forward_proxy_port    
          your_vcn_cidr_block=var.vcn_cidr_blocks[0]
          your_cert_email = var.your_cert_email
        }
        )
      )
    }
    preserve_boot_volume = false
      

  depends_on = [ tls_private_key.secure_web_gateway_vm_ssh_key, oci_core_network_security_group.secure_web_gateway_network_security_group ]
}



# ===== Secure Web Gateway Instance - IP Address =========
# IP Address Provisioning and Allocation
variable "secure_web_gateway_vm_ip_display_name" {
  type = string 
  description = "The display name for the ip address provisioned for the secure web gateway vm"
}

# 1. Get the VNIC ID from your existing instance
data "oci_core_vnic_attachments" "secure_web_gateway_vm_vnics" {
  compartment_id = oci_identity_compartment.data_arch_compartment.id
  instance_id    = oci_core_instance.secure_web_gateway_vm.id
}

# 2. Get the specific Private IP details
data "oci_core_private_ips" "secure_web_gateway_vm_primary_ip_search" {
  vnic_id = data.oci_core_vnic_attachments.secure_web_gateway_vm_vnics.vnic_attachments[0].vnic_id
}

# https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_public_ip#lifetime-7
# This is the public ip that is reserved for the computing instance
resource "oci_core_public_ip" "main_reserved_public_ip" {
    #Required
    compartment_id = oci_identity_compartment.data_arch_compartment.id
    lifetime = "RESERVED" # "RESERVED"  # Or "EPHEMERAL"

    #Optional
    # defined_tags = {"Operations.CostCenter"= "42"}
    display_name = var.secure_web_gateway_vm_ip_display_name

    # this is the private ip's ocid found from the vnic when the secure web gateway computing instance was provisioned
    private_ip_id = data.oci_core_private_ips.secure_web_gateway_vm_primary_ip_search.private_ips[0].id
    # freeform_tags = {"Department"= "Finance"}
    # public_ip_pool_id = oci_core_public_ip_pool.test_public_ip_pool.id
    depends_on = [ oci_core_instance.secure_web_gateway_vm ]
}


# ===== Headscale Instance =========
# --- computing instance related Variables ---

variable "headscale_vm_name" {
  type        = string 
  description = "The name of the compute instance provisioned for the role of headscale"
}
variable "headscale_vm_memory" {
  type        = number 
  description = "The memory of the compute instance provisioned for the role of headscale"
}
variable "headscale_vm_ocpus" {
  type        = number 
  description = "The ocpus of the compute instance provisioned for the role of headscale"
}
variable "headscale_vm_source_id" {
  type        = string 
  description = "The image id of the os image you want your vm instance to use. Find your this value here https://docs.oracle.com/en-us/iaas/images/ > choose the image you want to use > copy the link based on your region"
}
variable "headscale_vm_assign_public_ip" {
  type        = bool 
  description = "Whether the VNIC should be assigned a public IP address. Defaults to whether the subnet is public or private. If not set and the VNIC is being created in a private subnet (that is, where prohibitPublicIpOnVnic = true in the Subnet), then no public IP address is assigned. If not set and the subnet is public (prohibitPublicIpOnVnic = false), then a public IP address is assigned. If set to true and prohibitPublicIpOnVnic = true, an error is returned"
}
variable "headscale_vm_hostname_label" {
  type        = string 
  description = "The hostname for the VNIC's primary private IP. Used for DNS. The value is the hostname portion of the primary private IP's fully qualified domain name (FQDN) (for example, bminstance1 in FQDN bminstance1.subnet123.vcn1.oraclevcn.com). Must be unique across all VNICs in the subnet and comply with RFC 952 and RFC 1123. The value appears in the Vnic object and also the PrivateIp object returned by ListPrivateIps and GetPrivateIp."
}
variable "headscale_static_private_ip" {
  type        = string
  description = "The static private IP assigned to the Headscale VM (must be within the private subnet CIDR)."
  # Example: default = "10.0.1.10"
}
variable "your_headscale_arch_type" {
  type        = string
  description = "The string that determines the architecture type of the headscale app being installed."
  default = "amd64"
  # Example: "amd64" or "arm64"
}


# --- computing core instance ---
resource "oci_core_instance" "headscale_vm" {
    #Required
    availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
    compartment_id      = oci_identity_compartment.data_arch_compartment.id
    display_name        = var.headscale_vm_name
    shape               = var.free_forever_ARM_compute_shape

    create_vnic_details {

        #Optional
        # assign_ipv6ip = var.instance_create_vnic_details_assign_ipv6ip
        # assign_private_dns_record = var.instance_create_vnic_details_assign_private_dns_record
        assign_public_ip = var.headscale_vm_assign_public_ip
        # defined_tags = {"Operations.CostCenter"= "42"}
        # display_name = var.instance_create_vnic_details_display_name
        # freeform_tags = {"Department"= "Finance"}
        hostname_label = var.headscale_vm_hostname_label
        nsg_ids        = [oci_core_network_security_group.private_network_security_group.id]
        # security_attributes = var.headscale_vm_security_attributes # not using since this is outside of free forever tier

        subnet_id = oci_core_subnet.main_vcn_private_subnet.id
        private_ip = var.headscale_static_private_ip
    }


    # security_attributes = var.headscale_vm_security_attributes # not using since this is outside of free forever tier
    # shape = var.instance_shape
    shape_config {
      memory_in_gbs = var.headscale_vm_memory
      ocpus         = var.headscale_vm_ocpus
    }
    source_details {
        #Required
        source_id   = var.headscale_vm_source_id
        source_type = "image"

        # #Optional
        # boot_volume_size_in_gbs = var.instance_source_details_boot_volume_size_in_gbs
        # boot_volume_vpus_per_gb = var.instance_source_details_boot_volume_vpus_per_gb
        # instance_source_image_filter_details {
        #      #Required
        #      compartment_id = var.compartment_id

        #      #Optional
        #      defined_tags_filter = var.instance_source_details_instance_source_image_filter_details_defined_tags_filter
        #      operating_system = var.instance_source_details_instance_source_image_filter_details_operating_system
        #      operating_system_version = var.instance_source_details_instance_source_image_filter_details_operating_system_version
        # }
        # kms_key_id = oci_kms_key.test_key.id
    }
    metadata = {
      ssh_authorized_keys = tls_private_key.headscale_vm_ssh_key.public_key_openssh
      user_data = base64encode(
        templatefile("${path.module}/main-compute-setup-vpn.sh.tpl",
        {
          your_headscale_fqdn="${var.your_headscale_subdomain_name}.${var.your_secure_web_gateway_base_domain}"
          your_headscale_version=var.your_headscale_version
          your_headscale_arch_type =var.your_headscale_arch_type
          your_secure_web_gateway_base_domain=var.your_secure_web_gateway_base_domain
          secure_web_gateway_private_ip = var.secure_web_gateway_static_private_ip
          forward_proxy_port = var.forward_proxy_port
          reverse_proxy_port_to_open = var.headscale_port
        }
        )
      )
    }
    preserve_boot_volume = false
      

  depends_on = [ tls_private_key.headscale_vm_ssh_key, oci_core_network_security_group.private_network_security_group ]
}

# ===== Network Security Groups (NSG) - Secure Web Gateway & Private Subnet =========
variable "secure_web_gateway_NSG_display_name" {
  type = string
  description = "The display name for the secure web gateway's Network Security Group resource"
}

# This network security group will be used for the public facing vm instance
# https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group
resource "oci_core_network_security_group" "secure_web_gateway_network_security_group" {
    #Required
    compartment_id = oci_identity_compartment.data_arch_compartment.id
    vcn_id = module.main_vcn.vcn_id

    #Optional
    # defined_tags = {"Operations.CostCenter"= "42"}
    display_name = var.secure_web_gateway_NSG_display_name
    # freeform_tags = {"Department"= "Finance"}
}

variable "private_NSG_display_name" {
  type = string
  description = "The display name for the secure web gateway's recipient Network Security Group resource. The recipient of the secure web gateway's directed traffic include the Headscale control server VM and the other project VM"
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

variable "game_server_NSG_display_name" {
  type = string
  description = "The display name for the game server's Network Security Group resource"
}



# ===== Network Security Groups (NSG) Rules - Secure Web Gateway's Reverse Proxy NSG <-> Private NSG =========

# ----- 1. REVERSE PROXY NSG RULES -----
# Allow Reverse Proxy to send traffic out to the Private VMs
# By using a map of objects, your security architecture easily scales. If you later decide to add a completely different application that doesn't use web standards
# for example, a custom API on port 5000 can be mapped from an external port 8000 without needing you to touch your NSG code at all.

variable "reverse_proxy_forwarding_rules" {
  type = map(object({
    backend_port = number
  }))

  default = {
    "headscale" = {
      backend_port = 8080
    },
    # Just add a new block to your variable inputs; Terraform handles the rest automatically
    # "custom_api" = {
    # backend_port = 5000
    # }

  }
}

# 1. Public Proxy NSG (Egress to Private Subnet)
# This rule tells the proxy: "You are allowed to talk to the private VMs, 
# but ONLY on the specific backend ports they are listening on."
resource "oci_core_network_security_group_security_rule" "reverse_proxy_to_private_egress" {
  for_each                  = var.reverse_proxy_forwarding_rules
  network_security_group_id = oci_core_network_security_group.secure_web_gateway_network_security_group.id
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
resource "oci_core_network_security_group_security_rule" "private_from_reverse_proxy_ingress" {
  for_each                  = var.reverse_proxy_forwarding_rules
  network_security_group_id = oci_core_network_security_group.private_network_security_group.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  source_type = "NETWORK_SECURITY_GROUP"
  source      = oci_core_network_security_group.secure_web_gateway_network_security_group.id

  tcp_options {
    destination_port_range {
      min = each.value.backend_port
      max = each.value.backend_port
    }
  }
}

# ----- 2. PUBLIC FACING INGRESS RULES FOR REVERSE PROXY NSG -----

# Allow HTTP Ingress traffic from anywhere on the internet (Required for Certbot validation)
resource "oci_core_network_security_group_security_rule" "reverse_proxy_http_ingress" {
  network_security_group_id = oci_core_network_security_group.secure_web_gateway_network_security_group.id
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
  network_security_group_id = oci_core_network_security_group.secure_web_gateway_network_security_group.id
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

# ----- 3. Private Backend NSG (Egress to Proxy for Internet Access via Tinyproxy) -----
# These rules allow VM instances within the private subnet to send traffic out using the secure web gateway vm eg. via the application "tinyproxy"

variable "forward_proxy_port" {
  type = number
  description = "The port number used in the forward proxy application within the secure web gateway instance."
}

resource "oci_core_network_security_group_security_rule" "private_to_forward_proxy_egress" {
  network_security_group_id = oci_core_network_security_group.private_network_security_group.id
  direction                 = "EGRESS"
  protocol                  = "6" # TCP

  destination_type = "NETWORK_SECURITY_GROUP"
  destination      = oci_core_network_security_group.secure_web_gateway_network_security_group.id

  tcp_options {
    destination_port_range {
      min = var.forward_proxy_port
      max = var.forward_proxy_port
    }
  }
}

# ----- 4. Public Proxy NSG (Ingress from Private Backend for Proxy Requests) -----
resource "oci_core_network_security_group_security_rule" "forward_proxy_from_private_ingress" {
  network_security_group_id = oci_core_network_security_group.secure_web_gateway_network_security_group.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  source_type               = "NETWORK_SECURITY_GROUP"
  source                    = oci_core_network_security_group.private_network_security_group.id

  tcp_options {
    destination_port_range {
      min = var.forward_proxy_port
      max = var.forward_proxy_port
    }
  }
}



# ===== Gameserver Instance =========
# --- computing instance related Variables ---

variable "gameserver_vm_name" {
  type        = string 
  description = "The name of the compute instance provisioned for the role of gameserver"
}

variable "gameserver_vm_memory" {
  type        = number 
  description = "The memory of the compute instance provisioned for the role of gameserver"
}

variable "gameserver_vm_ocpus" {
  type        = number 
  description = "The ocpus of the compute instance provisioned for the role of gameserver"
}

variable "gameserver_vm_source_id" {
  type        = string 
  description = "The image id of the os image you want your vm instance to use. Find your this value here https://docs.oracle.com/en-us/iaas/images/ > choose the image you want to use > copy the link based on your region"
}

variable "gameserver_vm_assign_public_ip" {
  type        = bool 
  description = "Whether the VNIC should be assigned a public IP address. Defaults to whether the subnet is public or private. If not set and the VNIC is being created in a private subnet (that is, where prohibitPublicIpOnVnic = true in the Subnet), then no public IP address is assigned. If not set and the subnet is public (prohibitPublicIpOnVnic = false), then a public IP address is assigned. If set to true and prohibitPublicIpOnVnic = true, an error is returned"
}

variable "gameserver_vm_hostname_label" {
  type        = string 
  description = "The hostname for the VNIC's primary private IP. Used for DNS. The value is the hostname portion of the primary private IP's fully qualified domain name (FQDN) (for example, bminstance1 in FQDN bminstance1.subnet123.vcn1.oraclevcn.com). Must be unique across all VNICs in the subnet and comply with RFC 952 and RFC 1123. The value appears in the Vnic object and also the PrivateIp object returned by ListPrivateIps and GetPrivateIp."
}

variable "gameserver_duckdns_domain_name" {
  description = "The duckdns domain name. Eg. ducky.duckdns.org, 'ducky' is considered to be the value you want to assign for this variable."
  type        = string
  sensitive = true
}

variable "gameserver_github_raw_base_url" {
  type        = string
  description = "The base URL for pulling raw files from the public GitHub repository branch where deployment configuration documents reside (e.g., https://raw.githubusercontent.com/username/repo/main)."
}

variable "gameserver_github_repo_playbook_path" {
  type        = string
  description = "The relative repository path or file name for the Ansible deployment playbook (playbook.yml) used to provision systems, configure firewall rules, and deploy the Pterodactyl stack."
}

variable "gameserver_github_repo_pterodactyl_docker_compose_path" {
  type        = string
  description = "The relative repository path or file name for the Jinja2 template of the Docker Compose stack (docker-compose.yml.j2) used to generate the production application containers."
}

data "oci_secrets_secretbundle" "gameserver_pterodactyl_app_key_bundle" {
  secret_id = oci_vault_secret.gameserver_pterodactyl_app_key_secret.id
}

data "oci_secrets_secretbundle" "gameserver_pterodactyl_db_password_bundle" {
  secret_id = oci_vault_secret.gameserver_pterodactyl_db_password_secret.id
}

# --- computing core instance ---
resource "oci_core_instance" "gameserver_vm" {
    #Required
    availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
    compartment_id      = oci_identity_compartment.data_arch_compartment.id
    display_name        = var.gameserver_vm_name
    shape               = var.free_forever_ARM_compute_shape

    create_vnic_details {

        #Optional
        # assign_ipv6ip = var.instance_create_vnic_details_assign_ipv6ip
        # assign_private_dns_record = var.instance_create_vnic_details_assign_private_dns_record
        assign_public_ip = var.gameserver_vm_assign_public_ip
        # defined_tags = {"Operations.CostCenter"= "42"}
        # display_name = var.instance_create_vnic_details_display_name
        # freeform_tags = {"Department"= "Finance"}
        hostname_label = var.gameserver_vm_hostname_label
        nsg_ids        = [oci_core_network_security_group.game_server_network_security_group.id]
        # security_attributes = var.gameserver_vm_security_attributes # not using since this is outside of free forever tier

        subnet_id  = oci_core_subnet.main_vcn_public_subnet.id
    }


    # security_attributes = var.gameserver_vm_security_attributes # not using since this is outside of free forever tier
    # shape = var.instance_shape
    shape_config {
      memory_in_gbs = var.gameserver_vm_memory
      ocpus         = var.gameserver_vm_ocpus
    }
    source_details {
        #Required
        source_id   = var.gameserver_vm_source_id
        source_type = "image"

        # #Optional
        # boot_volume_size_in_gbs = var.instance_source_details_boot_volume_size_in_gbs
        # boot_volume_vpus_per_gb = var.instance_source_details_boot_volume_vpus_per_gb
        # instance_source_image_filter_details {
        #       #Required
        #       compartment_id = var.compartment_id

        #       #Optional
        #       defined_tags_filter = var.instance_source_details_instance_source_image_filter_details_defined_tags_filter
        #       operating_system = var.instance_source_details_instance_source_image_filter_details_operating_system
        #       operating_system_version = var.instance_source_details_instance_source_image_filter_details_operating_system_version
        # }
        # kms_key_id = oci_kms_key.test_key.id
    }
    metadata = {
      ssh_authorized_keys = tls_private_key.gameserver_vm_ssh_key.public_key_openssh
      user_data = base64encode(
        templatefile("${path.module}/main-compute-setup-gameserver.sh.tpl",
        {
          gameserver_tcp_ports_to_open = join(" ", var.game_server_tcp_ports)
          gameserver_udp_ports_to_open = join(" ", var.game_server_udp_ports)
          gameserver_panel_db_password = base64decode(data.oci_secrets_secretbundle.gameserver_pterodactyl_db_password_bundle.secret_bundle_content.0.content)
          gameserver_panel_app_key       = base64decode(data.oci_secrets_secretbundle.gameserver_pterodactyl_app_key_bundle.secret_bundle_content.0.content)
          gameserver_duckdns_domain_name = var.gameserver_duckdns_domain_name
          duck_dns_token = var.your_duckdns_token
          gameserver_github_raw_base_url=var.gameserver_github_raw_base_url
          gameserver_github_repo_playbook_path=var.gameserver_github_repo_playbook_path
          gameserver_github_repo_pterodactyl_docker_compose_path=var.gameserver_github_repo_pterodactyl_docker_compose_path
        }
        )
      )
    }
    preserve_boot_volume = false

  depends_on = [ tls_private_key.gameserver_vm_ssh_key, oci_core_network_security_group.private_network_security_group, oci_vault_secret.gameserver_vm_ssh_key_secret,oci_vault_secret.gameserver_pterodactyl_app_key_secret,oci_vault_secret.gameserver_pterodactyl_db_password_secret ]
}

# ===== Network Security Groups (NSG) - Game Server =========

# This network security group will be used for a public facing vm instance
# https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group
resource "oci_core_network_security_group" "game_server_network_security_group" {
    #Required
    compartment_id = oci_identity_compartment.data_arch_compartment.id
    vcn_id = module.main_vcn.vcn_id

    #Optional
    # defined_tags = {"Operations.CostCenter"= "42"}
    display_name = var.game_server_NSG_display_name
    # freeform_tags = {"Department"= "Finance"}
}


# ===== Network Security Groups (NSG) Rules - Game Server =========

# ----- 1. PUBLIC FACING INGRESS RULES FOR GAME SERVER's GAME PORTS -----

variable "game_server_tcp_ports" {
  type        = list(number)
  description = "List of TCP ports to open for the game server"
  default     = [25565] # You can add more ports here later (e.g., 8123 for Dynmap)
}

# 1. Rule for Games that uses TCP
resource "oci_core_network_security_group_security_rule" "game_server_NSG_TCP_rule" {
  for_each = toset([for p in var.game_server_tcp_ports : tostring(p)])
  network_security_group_id = oci_core_network_security_group.game_server_network_security_group.id
  direction                 = "INGRESS"
  protocol                  = "6" # "6" is the protocol number for TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
}


variable "game_server_udp_ports" {
  type        = list(number)
  description = "List of UDP ports to open for the game server"
  default     = [19132]
}

# 2. Rule for Games that uses UDP
resource "oci_core_network_security_group_security_rule" "game_server_NSG_UDP_rule" {
  for_each = toset([for p in var.game_server_udp_ports : tostring(p)])

  network_security_group_id = oci_core_network_security_group.game_server_network_security_group.id
  direction                 = "INGRESS"
  protocol                  = "17" # "17" is the protocol number for UDP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
}

