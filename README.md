# oracle-cloud-infrastructure


# 1. Introduction

## 1.1 Introduction - Project Title: Personal Oracle Cloud Infrastructure Projects
This repo holds all the golden source code for setting up my own app annd cloud infrastructure projects on Oracle Cloud.

| Project Folder  | Purpose | Status |
|-------|-----|------------|
| 00-bootstrap | Provision underlying security and terraform state sync infrastructure used for all other projects. | DONE   |
| 01-headscale  | Provision and setup a private Headscale VPN Control Server compute instance behind a public dual proxy compute instance. | DONE |
| 02-pterodactyl  | Provision and setup Pterodactyl Panel (frontend) & Pterodactyl Wings (backend) on the same public compute instance for maximum game server capabilities. | WIP (still need to setup backup cronjob) |


---
---
---

# 2. Table of Contents
Here is the generated Table of Contents with Markdown anchor links for your headings.

---

## Table of Contents

* [1. Introduction](#1-introduction)
  * [1.1 Introduction - Project Title: Personal Oracle Cloud Infrastructure Projects](#11-introduction---project-title-personal-oracle-cloud-infrastructure-projects)


* [2. Table of Contents](#2-table-of-contents)
* [3 Architecture Overview](#3-architecture-overview)
* [3.1 Architecture Overview - Architecture Diagram](#31-architecture-overview---architecture-diagram)
* [3.2 Architecture Overview - Key Components](#32-architecture-overview---key-components)
* [3.3 Architecture Overview - Technologies Used](#33-architecture-overview---technologies-used)
* [3.4 Architecture Overview - Design Philosophy](#34-architecture-overview---design-philosophy)


* [4 Project Structure](#4-project-structure)
* [4.1 Project Structure - Folder Organization Explanation](#41-project-structure---folder-organization-explanation)


* [5 General Prerequisites & Requirements](#5-general-prerequisites--requirements)
* [6 Projects](#6-projects)
  * [6.1 Projects - General Instructions](#61-projects---general-instructions)
    * [6.1.1 Projects - General Instructions - How to use terraform](#611-projects---general-instructions---how-to-use-terraform)
    * [6.1.2 Projects - General Instructions - Verify if Oracle Cloud Provider Works](#612-projects---general-instructions---verify-if-oracle-cloud-provider-works)
    * [6.1.3 Projects - General Instructions - Retrieving SSH key to the compute instance](#613-projects---general-instructions---retrieving-ssh-key-to-the-compute-instance)
    * [6.1.4 Projects - General Instructions - SSH to a private VM located within the private subnet](#614-projects---general-instructions---ssh-to-a-private-vm-located-within-the-private-subnet)
    * [6.1.5 Projects - General Instructions - Finding Values Of OCI Provider Terraform Variables](#615-projects---general-instructions---finding-values-of-oci-provider-terraform-variables)
    * [6.1.5.1 Projects - General Instructions - Finding Values Of OCI Provider Terraform Variables - Tenancy OCID](#6151-projects---general-instructions---finding-values-of-oci-provider-terraform-variables---tenancy-ocid)
    * [6.1.5.2 Projects - General Instructions - Finding Values Of OCI Provider Terraform Variables - User OCID](#6152-projects---general-instructions---finding-values-of-oci-provider-terraform-variables---user-ocid)
    * [6.1.5.3 Projects - General Instructions - Finding Values Of OCI Provider Terraform Variables - Fingerprint & Private Key Path](#6153-projects---general-instructions---finding-values-of-oci-provider-terraform-variables---fingerprint--private-key-path)
    * [6.1.5.4 Projects - General Instructions - Finding Values Of OCI Provider Terraform Variables - Region](#6154-projects---general-instructions---finding-values-of-oci-provider-terraform-variables---region)

  * [6.2 Projects - 00-bootstrap](#62-projects---00-bootstrap)
    * [6.2.1 Projects - 00-bootstrap - Description](#621-projects---00-bootstrap---description)
    * [6.2.2 Projects - 00-bootstrap - Setup Guide](#622-projects---00-bootstrap---setup-guide)
    * [6.2.3 Projects - 00-bootstrap - Usage](#623-projects---00-bootstrap---usage)


  * [6.3 Projects - 01-headscale](#63-projects---01-headscale)
    * [6.3.1 Projects - 01-headscale - Description](#631-projects---01-headscale---description)
    * [6.3.2 Projects - 01-headscale - Configuration Example](#632-projects---01-headscale---configuration-example)
    * [6.3.3 Projects - 01-headscale - Setup Guide](#633-projects---01-headscale---setup-guide)
    * [6.3.4 Projects - 01-headscale - Troubleshooting Or Checking Status](#634-projects---01-headscale---troubleshooting-or-checking-status)
      * [6.3.4.1 Projects - 01-headscale - Troubleshooting Or Checking Status - Check Headscale Control Server Operational](#6341-projects---01-headscale---troubleshooting-or-checking-status---check-headscale-control-server-operational)
      * [6.3.4.2 Projects - 01-headscale - Troubleshooting Or Checking Status - Check Secure Web Gateway Compute Instance Setup Progress](#6342-projects---01-headscale---troubleshooting-or-checking-status---check-secure-web-gateway-compute-instance-setup-progress)
      * [6.3.4.3 Projects - 01-headscale - Troubleshooting Or Checking Status - Check Headscale Compute Instance Setup Progress](#6343-projects---01-headscale---troubleshooting-or-checking-status---check-headscale-compute-instance-setup-progress)
    * [6.3.5 Projects - 01-headscale - Usage Guide](#635-projects---01-headscale---usage-guide)


* [6.4 Projects - 02-pterodactyl](#64-projects---02-pterodactyl)
  * [6.4.1 - 02-pterodactyl - Description](#641---02-pterodactyl---description)
  * [6.4.2 - 02-pterodactyl - Configuration Example](#642---02-pterodactyl---configuration-example)
  * [6.4.3 - 02-pterodactyl - Setup Guide](#643---02-pterodactyl---setup-guide)
  * [6.4.4 - 02-pterodactyl - Troubleshooting Or Checking Status](#644---02-pterodactyl---troubleshooting-or-checking-status)
    * [6.4.4.1 Projects - 02-pterodactyl - Troubleshooting Or Checking Status - Check Pterodactyl Panel Operational](#6441-projects---02-pterodactyl---troubleshooting-or-checking-status---check-pterodactyl-panel-operational)
    * [6.3.4.1 Projects - 02-pterodactyl - Troubleshooting Or Checking Status - Check Pterodactyl Setup Progress](#6341-projects---02-pterodactyl---troubleshooting-or-checking-status---check-pterodactyl-setup-progress)


  * [6.4.5 - 02-pterodactyl - Usage Guide - Setting up Initial Configs](#645---02-pterodactyl---usage-guide---setting-up-initial-configs)
  * [6.4.6 - 02-pterodactyl - Usage Guide - Setting up Automated Cloud Backup](#646---02-pterodactyl---usage-guide---setting-up-automated-cloud-backup)
  * [6.4.7 - 02-pterodactyl - Usage Guide - Seeing Automated Cloud Backup Logs](#647---02-pterodactyl---usage-guide---seeing-automated-cloud-backup-logs)
  * [6.4.8 - 02-pterodactyl - Usage Guide - Changing Cron Schedule for Automated Cloud Backup](#648---02-pterodactyl---usage-guide---changing-cron-schedule-for-automated-cloud-backup)
  * [6.4.9 - 02-pterodactyl - Usage Guide - Enabling & Setting up Scheduled Backups on Pterodactyl](#649---02-pterodactyl---usage-guide---enabling--setting-up-scheduled-backups-on-pterodactyl)
  * [6.4.10 - 02-pterodactyl - Usage Guide - Changing Versions of Apps Used](#6410---02-pterodactyl---usage-guide---changing-versions-of-apps-used)
  * [6.4.11 - 02-pterodactyl - Usage Guide - Opening More Game Ports for New Games](#6411---02-pterodactyl---usage-guide---opening-more-game-ports-for-new-games)




* [Common Troubleshooting Issues](#common-troubleshooting-issues)
* [Unable to lookup backend tf state Object Storage, server misbehaving](#unable-to-lookup-backend-tf-state-object-storage-server-misbehaving)

---
---
---






# 3 Architecture Overview

## 3.1 Architecture Overview - Architecture Diagram
![](https://raw.githubusercontent.com/bestcolour/site/refs/heads/master/assets/image/IT_Automation-Oracle_Cloud/Current%20Architecture-Oracle%20Cloud%20Resources.drawio.png)

[Read more](https://bestcolour.github.io/site/projects/IT-automation-info/#oracle-cloud-personal-architecture)

---
---

## 3.2 Architecture Overview - Key Components 

- 00-bootstrap (foundational resources)
- 01-headscale (core infrastructure for setting up a secure Headscale VPN control server)
- 02-pterodactyl  (core infrastructure for setting up a Game Hosting & Management Server - Pterodactyl Panel frontend server and a Pterodactyl Wings backend server)


---
---


## 3.3 Architecture Overview - Technologies Used
  - Terraform
  - Shell Scripts
  - Oracle Cloud Infrastructure (OCI)
  - Docker & Docker Compose
  - Cloud Init
  - Ansible

---
---

## 3.4 Architecture Overview - Design Philosophy
00-bootstrap was initialised first to ensure that all preceding cloud infrastructure can be secured using Key Management System (KMS) Vault, KMS Key and KMS Secrets along with a Object Storage (also secured with the before mentioned vault) to centralise the project's Terraform State file thus allowing multiple devices to work on the same Oracle Cloud Infrastructure project.


---
---
---

# 4 Project Structure 

## 4.1 Project Structure - Folder Organization Explanation

```
00-bootstrap/ — Foundation setup (KMS vault, state storage, compartments)
01-headscale/ — Headscale VPN deployment
02-pterodactyl/ — Game server management (Pterodactyl panel)
```

---
---
---

# 5 General Prerequisites & Requirements

1) A "Pay as you go" or "Free Forever Tier" Oracle Cloud Infrastructure Account (Projects here are always within the limits of "Free Forever Tier" unless explicitly mentioned)
2) Docker Engine
3) Basic Knowledge on SSH
4) Basic Knowledge on Terraform
5) Basic Knowledge on Cloud-Init
6) [A free DuckDNS Account](https://www.duckdns.org/)

---
---
---


# 6 Projects

## 6.1 Projects - General Instructions

### 6.1.1 Projects - General Instructions - How to use terraform

To start terraform in a container on your device, open a terminal in the git repository project's root and run the below code:

```bash
docker-compose run --rm terraform
```

Then, change directory to your desired project and proceed with terraforming.

Eg.
```bash
cd 00-bootstrap
```

---


### 6.1.2 Projects - General Instructions - Verify if Oracle Cloud Provider Works

To check if your project is connected correctly to Oracle Cloud, simply change directory to your project of choice and run:

Once inside:

```bash
terraform init
terraform plan
```

You should see regions and other outputs being listed in the console. If you see it, it means that your oracle cloud is properly connected to terraform.

---

### 6.1.3 Projects - General Instructions - Retrieving SSH key to the compute instance

If you need to access a compute instance provisioned, you could retrieve the SSH key needed for access using the method below:

**Setup**

To do so, you need a .oci folder which contains:
1) 'config' file that contains:
```
[DEFAULT]
user=ocid1.user.oc1..
fingerprint=
tenancy=ocid1.tenancy.oc1..
region=
key_file=/oracle/.oci/oci_api_key.pem
```

2) A 'oci_api_key.pem' file that lets you access your oracle account using Command Line Interface (CLI) (which you should already have if you have setup the terraform project above)

**Command To Call**

We will use oci.yml (located in the root of the git repo) to run an oci container and retrieve the ssh key. This will be the command we will be running:
```
docker compose -f oci.yml run --rm oci-cli "oci secrets secret-bundle get-secret-bundle-by-name --secret-name '<YOUR_SECRET_NAME>' --vault-id <YOUR_VAULT_OCID> --query 'data.\"secret-bundle-content\".content' --raw-output | base64 -d > my_secret.pem"
```

---

### 6.1.4 Projects - General Instructions - SSH to a private VM located within the private subnet
To SSH into any of the private VMs located within the private subnet, we can use the secure web gateway computing instance as a Bastion and just SSH from it.

Here is the how the ssh command line will look like:
```
ssh -o ProxyCommand="ssh -i /path/to/bastion_key.pem -W %h:%p ubuntu@<bastion_public_ip>" -i /path/to/headscale_key.pem ubuntu@<headscale_private_ip>
```

---
---

### 6.1.5 Projects - General Instructions - Finding Values Of OCI Provider Terraform Variables

These are usually the first set of credentials to find in any project as it is commonly required.

```
# Tenancy and User Information
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaxexample"
user_ocid        = "ocid1.user.oc1..aaaaaaaayexample"

# Authentication
fingerprint      = "20:3b:97:13:55:1c:..."
private_key_path = #TO DO, SET THIS PATH TO THE VOLUME MOUNTED PATH WITHIN DOCKER COMPOSE eg. "/workspace/.oci/oci_api_key.pem"

# Infrastructure Region
region           = "us-ashburn-1"
```

To find these identifiers in the Oracle Cloud Infrastructure (OCI) console, you can think of it in two main stops: your **Tenancy** details and your **User** details.

Here is the step-by-step guide for each:

#### 6.1.5.1 Projects - General Instructions - Finding Values Of OCI Provider Terraform Variables - Tenancy OCID

The Tenancy OCID is the unique identifier for your entire cloud account.

* **Where:** In the top-right corner, click the **Profile** icon (the silhouette).
* **Action:** Click on **Tenancy: [Your_Tenancy_Name]**.
* **The ID:** Under the **Tenancy Information** tab, look for **OCID**. Click **Copy**.

---

#### 6.1.5.2 Projects - General Instructions - Finding Values Of OCI Provider Terraform Variables - User OCID

This is the identifier for your specific user account.

* **Where:** Click the **Profile** icon again.
* **Action:** Select **User Settings** (or click on your username).
* **The ID:** Under **User Information**, you will see your **OCID**. Click **Copy**.

---

#### 6.1.5.3 Projects - General Instructions - Finding Values Of OCI Provider Terraform Variables - Fingerprint & Private Key Path

The fingerprint is generated when you create an API Key pair.

* **Where:** On your **User Settings** page (from the step above), scroll down to the **Resources** section on the top toolbar.
* **Action:** Click **API Keys** → **Add API Key**.
* **Generate:** * Select **Generate API Key Pair**.
    * **Crucial:** Click **Download Private Key** and save it to a secure folder (e.g., `~/.oci/`).
    * Click **Add**.
* **The ID:** A pop-up will appear showing your **Fingerprint** (a series of hex pairs). It also provides a helpful configuration snippet you can copy.
* **Path:** Your `private_key_path` in Terraform is simply the local path where you just saved that `.pem` file.

---

#### 6.1.5.4 Projects - General Instructions - Finding Values Of OCI Provider Terraform Variables - Region

The region is the physical location of your data center.

* **Where:** Look at the top-right navigation bar, next to your profile icon.
* **Action:** It will show your current region (e.g., **US East (Ashburn)**).
* **The ID:** While it shows a "pretty" name, Terraform needs the **Region Identifier**.
    * Common identifiers: `us-ashburn-1`, `uk-london-1`, `eu-frankfurt-1`.
    * You can see the full list by clicking the region name and selecting **Manage Regions**.


---
---


## 6.2 Projects - 00-bootstrap
### 6.2.1 Projects - 00-bootstrap - Description

This project's `.tf` needs to be applied first before any other projects'. They lay the foundation of the entire cloud architecture by provisioning a KMS vault, a KMS master key (with additional resources to help rotate the key) and an object storage to store the terraform state file as a backend (with additional resources to delete versions of the terraform state file over an interval to prevent exceeding storage limit by the free forever tier).

To get this project up and running, you need to:
1) Create and define your configuration files
2) Run the Terraform commands required to make use of the code and defined configurations

---

### 6.2.2 Projects - 00-bootstrap - Setup Guide

1) Create a new file called `terraform.tfvars` in the same directory as the folder `00-bootstrap`.

2) Use the below example of how the configuration file will look like for 00-bootstrap's terraform files. We will explore how to find some of these values in the next step.
```
# Tenancy and User Information
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaxexample"
user_ocid        = "ocid1.user.oc1..aaaaaaaayexample"

# Authentication
fingerprint      = "20:3b:97:13:55:1c:..."
private_key_path = #TO DO, SET THIS PATH TO THE VOLUME MOUNTED PATH WITHIN DOCKER COMPOSE eg. "/workspace/.oci/oci_api_key.pem"

# Infrastructure Region
region           = "us-ashburn-1"

# Compartments
second_root_compartment_name = "my-second-root"
bootstrap_compartment_name= "my-bootstrap-compartment"

# === Bucket For Syncing Terraform State ====
tf_state_bucket_name = "my-tf-state-bucket"
tf_state_bucket_access_type = "NoPublicAccess"
tf_state_bucket_auto_tiering = "Disabled"
tf_state_bucket_object_events_enabled=false
tf_state_bucket_storage_tier = "Standard"
tf_state_bucket_versioning = "Enabled"
tf_state_bucket_lifecycle_time_amount = "30"
tf_state_bucket_lifecycle_time_unit = "DAYS"

# === Vault & Key ===
# Vault
main_kms_vault_display_name = "the-main-kms-vault"
main_kms_vault_type = "DEFAULT"

# Key
main_kms_key_display_name = "main-kms-key"
key_key_shape_algorithm = "AES"
key_protection_mode = "SOFTWARE"
key_key_shape_length = 32
key_auto_key_rotation_details_rotation_interval_in_days = 90
key_desired_state = "ENABLED"
```

3) To find the values, look at [Finding Values Of OCI Provider Terraform Variables](#615-projects---general-instructions---finding-values-of-oci-provider-terraform-variables). The rest of the values can be left as default.

4) After filling in the values and changing them to your liking, it time to provision the cloud resources using the configurations and Terraform code defined.

Start up terraform
```bash
docker-compose run --rm terraform
```

Go to 00-bootstrap directory
```
cd 00-bootstrap
```

Run terraform these commands one after the other to provision the resources.

```
terraform init
terraform plan
terraform apply
```

Once done, keep the resulting `terraform.tfstate` and `terraform.tfvars` files safe (e.g., in a secure password manager or an encrypted file storage), as this manages your management layer.

---

### 6.2.3 Projects - 00-bootstrap - Usage

To tell any other new Terraform projects to use the Object Storage provisioned here as a centralised Terraform State holder, create a file `backend-config.tfvars` with the example configuration below and place it in the project's folder (eg. the folders `01-headscale` or `02-pterodactyl`)

```hcl
bucket="tf-state-anchor-bucket"
namespace         = "mynamespace_look_for_me_in_oracle_cloud_webpage"
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaxexample"
user_ocid        = "ocid1.user.oc1..aaaaaaaayexample"

# Authentication
fingerprint      = "20:3b:97:13:55:1c:..."
private_key_path = "/workspace/.oci/oci_api_key.pem"

# Infrastructure Region
region           = "us-ashburn-1"

key               = "path/that/the/tfstate_file/will/be/saved/in" # for example, if the project you want to use this for is 01-headscale, use a value like "01headscale/backend/tf_state"
workspace_key_prefix = "envs/"
# kms_key_id        = "ocid1.key.oc1.iad.xxxxxxxxxxxxxx"
# auth              = "APIKey"
# config_file_profile = "DEFAULT"

```

Then, initialise that Terraform project with 
```
terraform init -backend-config="backend-config.tfvars"
```


---
---

## 6.3 Projects - 01-headscale

### 6.3.1 Projects - 01-headscale - Description

The Headscale project mainly consists of two components. 

1) Secure Web Gateway - A compute instance that runs in a public subnet with a public IP address. This will be responsible for directing external traffic into a private subnet containing private compute instances.
2) Headscale Control Server - A compute instance that runs in the private subnet with a static private IP address. This will run the VPN control server software to securely exchange the IP addresses of registered devices.

---

### 6.3.2 Projects - 01-headscale - Configuration Example

Below is the configuration example for the 01-headscale project.
Values that you must change are:
1) tenancy_ocid
2) user_ocid
3) fingerprint
4) private_key_path
5) region
6) second_root_compartment_ocid
7) kms_main_vault_ocid
8) kms_main_key_ocid
9) your_duckdns_token
10) your_duckdns_domainname
11) your_secure_web_gateway_base_domain
12) your_cert_email
13) secure_web_gateway_vm_ssh_key_secret_name
14) headscale_vm_ssh_key_secret_name

- 1-5 can be retrieved by following [this guide](#615-projects---general-instructions---finding-values-of-oci-provider-terraform-variables)
- 6-8 will require you to log into your Oracle Cloud account and search for it (Tenancy Explorer & Key Management).
- 9-11 would be from your DuckDNS account
- 12 would be your own email that you are comfortable with getting server certificate renewal messages about (in the unlikely event that the automatic renewal process fails)

- 13-14 would be self declared secret names used to record sensitive values generated on terraform provision.

```
# Tenancy and User Information
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaxexample"
user_ocid        = "ocid1.user.oc1..aaaaaaaayexample"

# Authentication
fingerprint      = "20:3b:97:13:55:1c:..."
private_key_path = "/workspace/.oci/oci_api_key.pem" # Set as the volume mounted path within Docker 

# Infrastructure Region
region           = "us-ashburn-1"

# Compartments
second_root_compartment_ocid ="ocid1.compartment.oc1..aaaaaaaaxexample"

# kms resources
kms_main_vault_ocid = "ocid1.vault.oc1.us-ashburn-1.example"
kms_main_key_ocid = "ocid1.key.oc1.us-ashburn-1.example"

# VCN
vcn_name = "01-headscale-vcn-1"
vcn_dns_label = "h01vcn1"
vcn_cidr_blocks = ["10.0.0.0/16"]
main_vcn_private_subnet_dns_label = "private"
main_vcn_private_subnet_cidr_block ="10.0.1.0/24"
main_vcn_public_subnet_dns_label = "public"
main_vcn_public_subnet_cidr_block="10.0.0.0/24"

# Computing Instance
free_forever_ARM_compute_shape = "VM.Standard.A1.Flex"
free_forever_AMD_compute_shape = "VM.Standard.E2.1.Micro" # currently this shape is out of stock. Hence I will not recommend trying to provision it in my current region

# Computing Instance - Cloudinit script related Variables - Network configuration
your_reverse_proxy_tcp_ports = ["80", "443"]

# Computing Instance - Cloudinit script related Variables - DuckDNS configuration
your_duckdns_token      = "insert_duckdns_token_from_duckdns_page"
your_duckdns_domainname = "insert_duckdns_domainname_from_duckdns_page"

# Computing Instance - Cloudinit script related Variables - Domain & backend configuration
your_secure_web_gateway_base_domain            = "insert_full_duckdns_domain_from_duckdns_page" # basically your your_duckdns_domainname+".duckdns.org"
your_headscale_subdomain_name = "headscale"
your_project_1_subdomain_name = "wip"
headscale_port = "8080"
projects_private_ip_n_port  = "10.0.1.20:8443" # serves as an example
your_headscale_version = "0.28.0"
your_headscale_arch_type = "arm64"
your_cert_email="insert_your_email_for_certbot" # this is for emergency contact for when the things break or SSL certificates fail to automatically renew.

# Computing Instance - Secure Web Gateway
secure_web_gateway_vm_ssh_key_secret_name = "01-headscale-secure-web-gateway-ssh" # note that if `terraform destroy` is called, you will need to change this value as the previous instance of this object will go into a soft deletion 
secure_web_gateway_vm_name       = "01-headscale-secure-web-gateway"
secure_web_gateway_vm_memory     = 2
secure_web_gateway_vm_ocpus      = 1
secure_web_gateway_vm_source_id  = "ocid1.image.oc1.ap-singapore-1.aaaaaaaaovl4wfgvifzemo53rqy4dbotsx2xsus7y6j374urnxfrjhijkfqq"
secure_web_gateway_vm_assign_public_ip = false
secure_web_gateway_vm_hostname_label = "01headscalesecurewebgateway"
secure_web_gateway_vm_ip_display_name = "01-headscale-secure-web-gateway-reserved-public-ip"
secure_web_gateway_static_private_ip = "10.0.0.10" # private ips in the public subnet has "0" as the third digit

# Computing Instance - Headscale VPN
headscale_vm_ssh_key_secret_name = "01-headscale-headscale" # note that if `terraform destroy` is called, you will need to change this value as the previous instance of this object will go into a soft deletion 
headscale_vm_name       = "01-headscale-headscale"
headscale_vm_memory     = 1
headscale_vm_ocpus      = 1
headscale_vm_source_id  = "ocid1.image.oc1.ap-singapore-1.aaaaaaaaovl4wfgvifzemo53rqy4dbotsx2xsus7y6j374urnxfrjhijkfqq"
headscale_vm_assign_public_ip = false
headscale_vm_hostname_label = "01headscaleheadscale"
headscale_static_private_ip = "10.0.1.10" # private ips in the public subnet has "1" as the third digit

# Computing Instance - Network Security Group - VPN & Secure Web Gateway
secure_web_gateway_NSG_display_name = "01-headscale-secure-web-gateway-NSG"
private_NSG_display_name = "01-headscale-private-VMs-NSG"
reverse_proxy_forwarding_rules = {
    "headscale" = {
      backend_port = 8080
    },
  # Future apps can be cleanly added here:
  # "nextcloud" = {
  #   backend_port = 9000
  # }
  }
forward_proxy_port=8888
```


---

### 6.3.3 Projects - 01-headscale - Setup Guide

1) Make sure you create a fresh DuckDNS sub domain to reduce any likelihood of the DuckDNS failing the Certbot challenge.

2) Create a `backend-config.tfvars` file with guidance of the [00bootstrap Usage](#623-projects---00-bootstrap---usage) section and place them in the folder `01-headscale`.

3) Create a `terraform.tfvars` file with guidance of the [01 Headscale Configuration Example](#622-projects---01-headscale---configuration-example) section and place them in the folder `01-headscale`.

4) Start up terraform
```bash
docker-compose run --rm terraform
```

5) Go to 01-headscale directory
```
cd 01-headscale
```

6) Run terraform (but with backend config) to setup the backend with the bootstrap object storage and provision the resources

```
terraform init -backend-config="backend-config.tfvars"
```

7) Run these terraform commands:

To do a quick check on your terraform provisions, run
```
terraform plan
```

If everything looks good, run
```
terraform apply
```

8) Now wait for approximately 15 to 30 minutes for the entire automated process to finish. If you want to check on the status of the cloud resources go to [this section](#624-projects---01-headscale---troubleshooting-or-checking-status)

Once done, keep the resulting `terraform.tfvars` file safe (e.g., in a secure password manager or encrypted file storage).

---

### 6.3.4 Projects - 01-headscale - Troubleshooting Or Checking Status

#### 6.3.4.1 Projects - 01-headscale - Troubleshooting Or Checking Status - Check Headscale Control Server Operational

To check if the Headscale control server is up and operational, simply go to your browser and type in `headscale.<your_duckdns_subdomain_name>.duckdns.org/windows`. If you see a headscale logo and the page with text describing the steps for "Windows configuration", then the deployment was successful.

---

#### 6.3.4.2 Projects - 01-headscale - Troubleshooting Or Checking Status - Check Secure Web Gateway Compute Instance Setup Progress

To check if the Secure Web Gateway is still setting up or is running into any issues, we can SSH into the compute instance acting as the Secure Web Gateway.

We will first need to retrieve its SSH key. To do so, we can follow the [guide on how to get SSH keys from Oracle Cloud Secrets](#613-projects---general-instructions---retrieving-ssh-key-to-the-compute-instance).

Log into your Oracle Cloud Account and at the search bar near the top of the page, search for "Instances".

Under the "Services" section, click on the word "Instances" located in the same row as "Compute".

In this new page, find the "Applied filters" option and select the compartment name that you provisioned your Headscale related compute instances in (or you can just keep trying each filter to find out which is the correct one).

From there, find your Secure Web Gateway compute instance's public ip address.

Then open a new terminal and run the command
```
ssh ubuntu@<secure_web_gateway_compute_instance_ip_address> -i <the_path_of_your_retrieved_ssh_key>
```

Once inside, you can check the details of the Cloud-Init script by running

```
cloud-init status
```

Doing so will give you one of 3 responses
```
error
running
done
```

If you wish to further investigate the setup process, run this command:
```
tail -f /var/log/cloud-init-output.log -n 50
```

---

#### 6.3.4.3 Projects - 01-headscale - Troubleshooting Or Checking Status - Check Headscale Compute Instance Setup Progress

To check if the Headscale control server is still setting up or is running into any issues, we can SSH into its compute instance.

We will first need to retrieve both the Secure Web Gateway and Headscale computes' SSH keys. To do so, we can follow the [guide on how to get SSH keys from Oracle Cloud Secrets](#613-projects---general-instructions---retrieving-ssh-key-to-the-compute-instance).

Log into your Oracle Cloud Account and at the search bar near the top of the page, search for "Instances".

Under the "Services" section, click on the word "Instances" located in the same row as "Compute".

In this new page, find the "Applied filters" option and select the compartment name that you provisioned your Headscale related compute instances in (or you can just keep trying each filter to find out which is the correct one).

From there, find your Secure Web Gateway compute instance's public ip address and Headscale compute instance's private ip address (or you can refer to your `terraform.tfvars` file and look for `headscale_static_private_ip`).

Next, follow [the guide accessing a compute instance using SSH via a Bastion Host](#614-projects---general-instructions---ssh-to-a-private-vm-located-within-the-private-subnet).

Once inside, you can check the details of the Cloud-Init script by running

```
cloud-init status
```

Doing so will give you one of 3 responses
```
error
running
done
```

If you wish to further investigate the setup process, run this command:
```
tail -f /var/log/cloud-init-output.log -n 50
```


---

### 6.3.5 Projects - 01-headscale - Usage Guide


1) To start using the Headscale VPN Control server, you need to get access to the compute instance running this control server.

Follow [this guide](#6243-projects---01-headscale---troubleshooting-or-checking-status---check-headscale-compute-instance-setup-progress)

2) Once inside use the commands created by the official [headscale team](https://headscale.net/stable/usage/getting-started/).


---
---
---

## 6.4 Projects - 02-pterodactyl

### 6.4.1 - 02-pterodactyl - Description

The Pterodactyl project mainly consists of two components. 

1) Pterodactyl Panel Docker Compose Stack - A Docker Compose stack that sets up the database, proxies, cache and other necessities so that the frontend called Pterodactyl Panel could run. This Docker Compose stack will run on a single compute instance running in a public subnet with a public ephemeral public IP address.
2) Pterodactyl Wings - The backend server package needed for Pterodactyl Panel user interactions to carry out the server hosting, etc. This backend server package is usually ran on multiple separate compute instances but will run on the same compute instance as (1) to allow maximum CPU cores to utilised for running the server.

---

### 6.4.2 - 02-pterodactyl - Configuration Example
Below is the configuration example for the 02-pterodactyl project.
Values that you must change are:
1) tenancy_ocid
2) user_ocid
3) fingerprint
4) private_key_path
5) region
6) second_root_compartment_ocid
7) kms_main_vault_ocid
8) kms_main_key_ocid
9) your_duckdns_token
10) gameserver_duckdns_domain_name
11) game_server_tcp_ports (as required)
12) game_server_udp_ports (as required)
13) gameserver_vm_ssh_key_secret_name
14) gameserver_pterodactyl_db_password_secret_name
15) gameserver_pterodactyl_app_key_secret_name
16) gameserver_backup_cron_expression
17) gameserver_rclone_remote_name

- 1-5 can be retrieved by following [this guide](#615-projects---general-instructions---finding-values-of-oci-provider-terraform-variables).
- 6-8 will require you to log into your Oracle Cloud account and search for it (Tenancy Explorer & Key Management).
- 9-10 would be from your DuckDNS account.
- 11-12 would be based on the game you want to play (whichever ports for udp/tcp they need opening will be keyed in here).
- 13-15 would be self declared secret names used to record sensitive values generated on terraform provision.
- 16-17 would be self declared cron schedule and rclone remote name used in the setting up of cloud automated backup pipeline.


```
# Tenancy and User Information
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaxexample"
user_ocid        = "ocid1.user.oc1..aaaaaaaayexample"

# Authentication
fingerprint      = "20:3b:97:13:55:1c:..."
private_key_path = "/workspace/.oci/oci_api_key.pem" # Set as the volume mounted path within Docker 

# Infrastructure Region
region           = "us-ashburn-1"

# Compartments
second_root_compartment_ocid ="ocid1.compartment.oc1..aaaaaaaaxexample"

# kms resources
kms_main_vault_ocid = "ocid1.vault.oc1.us-ashburn-1.example"
kms_main_key_ocid = "ocid1.key.oc1.us-ashburn-1.example"

# VCN
vcn_name = "02-pterodactyl-vcn-1"
vcn_dns_label = "p02vcn1"
vcn_cidr_blocks = ["10.0.0.0/16"]
main_vcn_public_subnet_dns_label = "public"
main_vcn_public_subnet_cidr_block="10.0.0.0/24"


# Computing Instance
free_forever_ARM_compute_shape = "VM.Standard.A1.Flex"
free_forever_AMD_compute_shape = "VM.Standard.E2.1.Micro" # currently this shape is out of stock. Hence I will not recommend trying to provision it in my current region


# Computing Instance - Cloudinit script related Variables - DuckDNS configuration
your_duckdns_token      = "insert_duckdns_token_from_duckdns_page"


# Computing Instance - Game Server
gameserver_vm_ssh_key_secret_name = "02-pterodactyl-forward-avatar" # note that if `terraform destroy` is called, you will need to change this value as the previous instance of this object will go into a soft deletion 
gameserver_vm_name       = "02-pterodactyl-gameserver-vm-name"
gameserver_vm_memory     = 24
gameserver_vm_ocpus      = 4
gameserver_vm_source_id  = "ocid1.compartment.oc1..aaaaaaaaxexample"
gameserver_vm_assign_public_ip = true
gameserver_vm_hostname_label = "02pterodactylhostnamelabel"

# Computing Instance - Network Security Group - Game Server
game_server_NSG_display_name = "02-pterodactyl-gameserver-NSG"
game_server_tcp_ports = [80,443,8080,2022] # add your web ports and then game ports here (eg. 25565 is minecraft's port)
game_server_udp_ports= [] # add your web ports and then game ports here (eg. 19132 is minecraft's bedrock port)


# Computing Instance - Cloudinit script related Variables - Game Server (Pteradactyl Panel)
gameserver_duckdns_domain_name="insert_duckdns_domainname_from_duckdns_page"
gameserver_pterodactyl_db_password_secret_name="02-pterodactyl-db-password-secret-name" # note that if `terraform destroy` is called, you will need to change this value as the previous instance of this object will go into a soft deletion 
gameserver_pterodactyl_app_key_secret_name = "02-pterodactyl-app-key-secret-name" # note that if `terraform destroy` is called, you will need to change this value as the previous instance of this object will go into a soft deletion 
gameserver_github_raw_base_url="https://raw.githubusercontent.com/bestcolour/oracle-cloud-infrastructure/refs/heads/main"
gameserver_github_repo_playbook_path="02-pterodactyl/main-compute-setup-gameserver-playbook.yml"
gameserver_github_repo_maintain_playbook_path="02-pterodactyl/main-compute-manage-gameserver-playbook.yml"
gameserver_github_repo_pterodactyl_docker_compose_path="02-pterodactyl/main-compute-setup-gameserver-ansible-pterodactyl-docker-compose.yml.j2"
gameserver_github_repo_custom_shell_fix_path="02-pterodactyl/main-compute-setup-gameserver-custom-fix.sh"
gameserver_github_repo_backup_script_path="02-pterodactyl/main-compute-setup-gameserver-backup-script.sh"
gameserver_backup_cron_expression="25 * * * *" # how often you want the cloud backup to run
gameserver_rclone_remote_name="pterodactly_mega_drive_backup" # name of your rclone remote configuration
gameserver_rclone_remote_backup_path="pterodactyl_backups" # path of your cloud directory where you want to save the backups in
```

---

### 6.4.3 - 02-pterodactyl - Setup Guide

1) Make sure you create a fresh DuckDNS sub domain to reduce any likelihood of the DuckDNS failing the Certbot challenge.

2) Create a `backend-config.tfvars` file with guidance of the [00bootstrap Usage](#623-projects---00-bootstrap---usage) section and place them in the folder `02-pterodactyl`.

3) Create a `terraform.tfvars` file with guidance of the [02 Pterodactyl Configuration Example](#642---02-pterodactyl---configuration-example) section and place them in the folder `02-pterodactyl`.

4) Start up terraform
```bash
docker-compose run --rm terraform
```

5) Go to 01-headscale directory
```
cd 02-pterodactyl
```

6) Run terraform (but with backend config) to setup the backend with the bootstrap object storage and provision the resources

```
terraform init -backend-config="backend-config.tfvars"
```

7) Run these terraform commands:

To do a quick check on your terraform provisions, run
```
terraform plan
```

If everything looks good, run
```
terraform apply
```

8) Now wait for approximately 15 to 30 minutes for the entire automated process to finish. If you want to check on the status of the cloud resources go to [this section](#644---02-pterodactyl---troubleshooting-or-checking-status)

9) Proceed to setup [a game server](#645---02-pterodactyl---usage-guide---setting-up-initial-configs) and [automated cloud backup](#646---02-pterodactyl---usage-guide---setting-up-automated-cloud-backup).

Once done, keep the resulting `terraform.tfvars` file safe (e.g., in a secure password manager or encrypted file storage).


---


### 6.4.4 - 02-pterodactyl - Troubleshooting Or Checking Status


#### 6.4.4.1 Projects - 02-pterodactyl - Troubleshooting Or Checking Status - Check Pterodactyl Panel Operational

To check if the Pterodactyl Panel server is up and operational, simply go to your browser and type in `<gameserver_duckdns_domain_name>.duckdns.org`. If you see a login page and a Pterodactyl logo, then the Pterodactyl Panel deployment was successful.

---

#### 6.3.4.1 Projects - 02-pterodactyl - Troubleshooting Or Checking Status - Check Pterodactyl Setup Progress

To check if the Pterodactyl app is still setting up or is running into any issues, we can SSH into the compute instance.

We will first need to retrieve its SSH key. To do so, we can follow the [guide on how to get SSH keys from Oracle Cloud Secrets](#613-projects---general-instructions---retrieving-ssh-key-to-the-compute-instance).

Log into your Oracle Cloud Account and at the search bar near the top of the page, search for "Instances".

Under the "Services" section, click on the word "Instances" located in the same row as "Compute".

In this new page, find the "Applied filters" option and select the compartment name that you provisioned your Headscale related compute instances in (or you can just keep trying each filter to find out which is the correct one).

From there, find your Secure Web Gateway compute instance's public ip address.

Then open a new terminal and run the command
```
ssh ubuntu@<pterodactyl_compute_instance_ip_address> -i <the_path_of_your_retrieved_ssh_key>
```

Once inside, you can check the details of the Cloud-Init script by running

```
cloud-init status
```

Doing so will give you one of 3 responses
```
error
running
done
```

If you wish to further investigate the cloud-init and Ansible setup process, run this command:
```
tail -f /var/log/cloud-init-output.log -n 50
```

---



### 6.4.5 - 02-pterodactyl - Usage Guide - Setting up Initial Configs

1) Once the provisioned compute instance has been setup, we will need to create an admin account for management purposes.

SSH into the Pterodactyl instance by following [the "Check Pterodactyl Setup Progress Guide"](#6341-projects---02-pterodactyl---troubleshooting-or-checking-status---check-pterodactyl-setup-progress).

Once inside your server, navigate to the directory where your game server setup and `docker-compose.yml` file live. 

```
cd /var/www/pterodactyl
```

Find out what is the pterodactyl panel docker container name by running
```
sudo docker ps
```

You should a table like this. Find pterodactyl panel's name
```
CONTAINER ID   IMAGE                               COMMAND                  CREATED          STATUS          PORTS                                                                                             NAMES
...

f31714f1ef38   ghcr.io/pterodactyl/panel:v1.12.4   "/bin/ash .github/do…"   20 minutes ago   Up 20 minutes   80/tcp, 443/tcp, 9000/tcp                                                                         pterodactyl-panel-1

...
```

Often times, it will be `pterodactyl-panel-1`

Then, execute the interactive account creation wizard inside the running Pterodactyl Docker container by running:

```
sudo docker exec -it pterodactyl-panel-1 php artisan p:user:make
```

Follow the instructions and sign up your admin account. 

2) Once done, visit `https://YOUR_DUCKDNS_DOMAIN.duckdns.org` and log into your account

3) Once inside, click "Locations" on the left panel bar and create a new location
4) Next, click on "Nodes" on the left panel bar and create a new node
	1) Key in the FDQN with `<YOUR_DUCKDNS_DOMAIN_NAME>.duckdns.org`
	2) Define your resources base on your compute instances' CPU and RAM
	3) Make sure to use SSL connection (do not use HTTP only)
5) Once done, you will be on the Node's IP Address page. Do the following:
	1) Go to your terminal that SSH into Pteradactyl and run the command `hostname -I | awk '{print $1}'`
	2) Grab the output value and place it into the "Create IP Address" section
	3) Then set the name as "Internal IP"
	4) Press create/allocate IP Address
6) Next, on the horizontal bar at near the top of the page, click on "Configuration"
	1) Click "Generate Token"
	2) Copy that line of code
	3) Go to your terminal that SSH into Pteradactyl, paste the line the code and press enter
	4) Press "y" to confirm (if necessary)
	5) Once done, run the following command `sudo apply-wings-fixes`
7) And now you're done! You have successfully done to following:
	1) Created a Location (US, UK, etc) that a Node (basically another word for "machine") will be categorised under
	2) Created a Node that has the Pterodactyl Wings server program running and linked it to the Pterodactyl Panel app
	3) Allocated the Node's internal IP Address in the Pterodactyl Panel app so that servers running on the node could use it.
	4) Configured the Pterodactyl Wings machine so that it can communicate with the Pterodactyl Panel app and could spin up game servers
8) You can now create your own servers for Minecraft, Rust, etc!


---


### 6.4.6 - 02-pterodactyl - Usage Guide - Setting up Automated Cloud Backup

[Prerequisite - Enable & Setup Scheduled Backups](#649---02-pterodactyl---usage-guide---enabling--setting-up-scheduled-backups-on-pterodactyl)

If you wish to utilise the automated cloud backup (ran by a dockerised rclone container) to backup the pterodactyl panel, wings and game servers data to your own cloud drive (eg. Mega, Google Cloud Drive, etc), read this guide.

1) Assuming that you have keyed in a valid value for `gameserver_backup_cron_expression` in your `terraform.tfvars` file, SSH into your instance to setup your rclone configrations. You can follow the steps found in [here](#6341-projects---02-pterodactyl---troubleshooting-or-checking-status---check-pterodactyl-setup-progress) before progressing.

2) To allow the automated cloud backup to work, you need to create a rclone remote configuration with you cloud drive's credentials so that it could upload the files into your account.

Run this code first to give permision to your rclone container:
```
sudo chown -R "$(id -u):$(id -g)" /etc/rclone
```

Setup your rclone config by running the following commands:
```
sudo docker run -it --rm --volume /etc/rclone:/config/rclone --user $(id -u):$(id -g) rclone/rclone config
```

Follow the instructions to create a new remote (press n). Make sure that the name you give that remote matches the `gameserver_rclone_remote_name` variable value you set in `terraform.tfvars`.

Then, select your choice of cloud drive that you are using and follow the rest of the wizard's instructions. Read more [here](https://rclone.org/).

3) Once that remote is created, the backup script will automatically run base off of the cron expression you've defined in `gameserver_backup_cron_expression` in your `terraform.tfvars` file.

> It is crucial to have the local backup job scheduled before the cloud backup job so that the cloud backup job uploads the newly updated files

---

### 6.4.7 - 02-pterodactyl - Usage Guide - Seeing Automated Cloud Backup Logs

[Prerequisite - Enable & Setup Scheduled Backups](#649---02-pterodactyl---usage-guide---enabling--setting-up-scheduled-backups-on-pterodactyl)

To see the logs of the syncing process everytime the cronjob runs, run the following command:
(You can change `50` to increase/decrease the number of lines you want to see)
```
tail -f /var/log/pterodactyl_backup.log -n 50
```

---

### 6.4.8 - 02-pterodactyl - Usage Guide - Changing Cron Schedule for Automated Cloud Backup

[Prerequisite - Enable & Setup Scheduled Backups](#649---02-pterodactyl---usage-guide---enabling--setting-up-scheduled-backups-on-pterodactyl)

To change the cron schedule expression after you have already provisioned and performed the initial setup for the automated cloud backup, run the following command:
```
sudo crontab -e
```

Scroll down to find the previous cron schedule you have defined. It should look something like this:
```
30 2 * * * /usr/local/bin/pterodactyl-backup >> /var/log/pterodactyl_backup.log 2>&1
```

> It is crucial to have the local backup job scheduled before the cloud backup job so that the cloud backup job uploads the newly updated files


Change the `30 2 * * *` part to your new cron expression. Once again, you can use https://crontab.guru/ as a guide.

Exit, save and you're done!

---

### 6.4.9 - 02-pterodactyl - Usage Guide - Enabling & Setting up Scheduled Backups on Pterodactyl

Before you can perform any sort of automated cloud backup in the following guides, [1](#646---02-pterodactyl---usage-guide---setting-up-automated-cloud-backup), [2](#647---02-pterodactyl---usage-guide---seeing-automated-cloud-backup-logs), [3](#648---02-pterodactyl---usage-guide---changing-cron-schedule-for-automated-cloud-backup), you will need to enable backups on your Pterodactyl game server.

Why the local backup job needs to be configured first:
1) The compute instance will perform a local backup job based on the schedule you choose on pterodactyl.
2) Once the backup is saved successfully on the compute instance locally, the automated cloud backup will run (again based on your scheduled timing) to upload the new backup files to the cloud drive.
3) It is crucial to have the local backup job scheduled before the cloud backup job.

How to configure the local backup job:
1) At the page where you have your admin page opened (the gear icon on the top right), click on "Servers" and click on your Game Server that you want to enable backups on.
2) Click on "Manage" and click on "Build Configuration"
3) Find the "Backup Limit" setting and set it to a limit that you desire and press "Update".
4) On that same page, find the "open in new tab" icon (it looks like ↗ but with a 🗖 surrounding it)
5) This provides a console view of the server's operations. Click on "Backup" and you can see that the backup feature is now available for your server.
6) To ensure that a backup is scheduled, click on "Schedules" and click "Create Schedule"
7) Key in your "Schedule Name" and define your schedule (in cron expression). Use the cheatsheet or https://crontab.guru/ for guidance.
8) Click into your newly created Schedule and click "New Task".
9) Select "Create Backup" for the "Action" dropdown and press "Save"
10) That's it!



---

### 6.4.10 - 02-pterodactyl - Usage Guide - Changing Versions of Apps Used

For this project, there are a couple of files that you can look into to modify the versions of the applications used:
1) ARM64 Pterodactyl Wings runtime binary: main-compute-setup-gameserver-playbook in "Fetch and deploy ARM64 Pterodactyl Wings runtime binary"
2) Pterodactyl App Docker Compose Stack: main-compute-setup-gameserver-ansible-pterodactyl-docker-compose.yml

---

### 6.4.11 - 02-pterodactyl - Usage Guide - Opening More Game Ports for New Games

To open more game ports for when adding new games, simply add the values into `game_server_tcp_ports` & `game_server_udp_ports` in `terraform.tfvars` file before running `terraform apply` (this opens up the tcp and udp port the cloud level). 

Then, SSH into the compute instance and run the following commands with your new port `game_server_tcp_ports` & `game_server_udp_ports` values inserted:
```
ansible-playbook /tmp/maintain_playbook.yml -e "gameserver_tcp_ports_to_open='8080 8443' gameserver_udp_ports_to_open='5000 5001'"
```
This opens up the tcp and udp ports on the OS level.

---
---
---




# Common Troubleshooting Issues

## Unable to lookup backend tf state Object Storage, server misbehaving 

```
│ Error: Failed to get existing workspaces: Get "redacted": dial tcp: lookup objectstorage.redacted.oraclecloud.com on 127.0.0.11:53: server misbehaving 
```

There are times where the backend Object Storage that is used to sync tf state across multiple devices using Terraform has a "misbehaving" eror. This is likely due to the Docker container not being properly stopped when the terminal running that container is closed.

To cleanly close the container, we need to first find the Terraform container
```
docker ps -a
```

and stop it
```
docker stop <container_id>
```

Then, we just run:
```
docker compose down -v
```

After that, you can just re-init the Terrform backend