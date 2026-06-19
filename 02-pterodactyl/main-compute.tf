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
# DuckDNS configuration
variable "your_duckdns_token" {
  type        = string
  description = "The API token provided by DuckDNS for dynamic DNS updates."
  sensitive   = true
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

variable "gameserver_github_repo_maintain_playbook_path" {
  type        = string
  description = "The relative repository path or file name for the Ansible manage playbook used to manage firewall rules the Pterodactyl stack."
}

variable "gameserver_github_repo_pterodactyl_docker_compose_path" {
  type        = string
  description = "The relative repository path or file name for the Jinja2 template of the Docker Compose stack (docker-compose.yml.j2) used to generate the production application containers."
}

variable "gameserver_github_repo_custom_shell_fix_path" {
  type        = string
  description = "The relative repository path or file name for the shell script that needs to ran after configuring a node on pterodactyl panel."
}

variable "gameserver_github_repo_backup_script_path" {
  type        = string
  description = "The relative repository path or file name for the shell script that will be used to run for backing up pterodactyl panel (this means user accounts, locations, nodes and servers data) and wings data files (this means the actual game server's data files eg. Minecraft worlds)."
}

variable "gameserver_backup_cron_expression" {
  type        = string
  description = "The schedule that will determine when and how frequent the backup script will run. Use this for easy expression generation https://crontab.guru/"
}

variable "gameserver_rclone_remote_name" {
  type        = string
  description = "The rclone remote name which you will have to later manually type into after the compute instance's setup is done (one time setup). This setup process will then require you to type in your cloud storage account credentials."
  default = "pterodactyl_cloud_backup"
}

variable "gameserver_rclone_remote_backup_path" {
  type        = string
  description = "The rclone remote path defines where the automated cloud drive backup files will be synced to. For example, if the value is set to 'pterodactyl_backups', then the backup data will appear inside of the folder 'pterodactyl_backups' located at the root of your cloud drive."
  default = "pterodactyl_backups"
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
          gameserver_github_repo_custom_shell_fix_path=var.gameserver_github_repo_custom_shell_fix_path
          gameserver_github_repo_backup_script_path=var.gameserver_github_repo_backup_script_path
          gameserver_backup_cron_expression=var.gameserver_backup_cron_expression
          gameserver_rclone_remote_name=var.gameserver_rclone_remote_name
          gameserver_rclone_remote_backup_path=var.gameserver_rclone_remote_backup_path
          gameserver_github_repo_maintain_playbook_path=var.gameserver_github_repo_maintain_playbook_path
        }
        )
      )
    }
    preserve_boot_volume = false

  depends_on = [ tls_private_key.gameserver_vm_ssh_key,  oci_vault_secret.gameserver_vm_ssh_key_secret,oci_vault_secret.gameserver_pterodactyl_app_key_secret,oci_vault_secret.gameserver_pterodactyl_db_password_secret ]
}

# ===== Network Security Groups (NSG) - Game Server =========
variable "game_server_NSG_display_name" {
  type = string
  description = "The display name for the game server's Network Security Group resource"
}


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

