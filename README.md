# oracle-cloud-infrastructure
This project will hold all the golden source code for setting up my own infrastructure

---
---
---


# Architecture Explanation

## Architecture Diagram
![](https://raw.githubusercontent.com/bestcolour/site/refs/heads/master/assets/image/IT_Automation-Oracle_Cloud/Current%20Architecture-Oracle%20Cloud%20Resources.drawio.png)

[Read more](https://bestcolour.github.io/site/projects/IT-automation-info/#oracle-cloud-personal-architecture)

---
---
---

# Setup & Instruction to Use
---


## How to use terraform

To start terraform in a container on your device, run the below code:

```bash
docker-compose run --rm terraform
```


---

## General Folder Explanation

There are 2 folders in this repository, namely 00-bootstrap and 01-workloads. Both of them are integral to the provisioning for the oracle cloud architecture. We will talk more about the things to cover in the next few sections

### 00-bootstrap
Run the tf files in this folder first. They lay the foundation of the entire cloud architecture by provisioning a kms vault, a kms master key (with additional resources to help rotate the key) and an object storage to store the terraform state file as a backend (with additional resources to delete versions of the terraform state file over an interval to prevent exceeding storage limit by the free forever tier).

Create a terraform.tfvars file with guidance of the [bootstrap example config](#tfvars-example-config-file---00-bootstrap) section and place that file in the folder `00-bootstrap`

Start up terraform
```bash
docker-compose run --rm terraform
```

Go to 00-bootstrap directory
```
cd 00-bootstrap
```

Run terraform normally to provision the resources

```
terraform init
terraform plan
terraform apply
```

Once done, keep the resulting `terraform.tfstate` and `terraform.tfvars` files safe (e.g., in a secure password manager or a private Git repo with restricted access), as this manages your management layer.

### 01-workloads

This is where the main oracle cloud architecture resources will be provisioned. Run the tf files here only after finished 00-bootstrap's run. It will contain resources mentioned in [the architecture diagram](#architecture-diagram).

The tfstate file of this project will be uploaded to an object storage bucket provisioned by 00-bootstrap's run. This is done to securely 'sync' the terraform state file accross multiple devices and reduce the need for manual syncing across multiple devices. 


Create a `terraform.tfvars` and a `backend-config.tfvars` file with guidance of the [workloads example config](#tfvars-example-config-file---01-workloads) section and place them in the folder `01-workloads`.

Start up terraform
```bash
docker-compose run --rm terraform
```

Go to 00-bootstrap directory
```
cd 00-bootstrap
```

Run terraform (but with backend config) to setup the backend with the bootstrap object storage and provision the resources

```
terraform init -backend-config="backend-config.tfvars"
terraform plan
terraform apply
```

Once done, keep the resulting `terraform.tfstate` and `terraform.tfvars` files safe (e.g., in a secure password manager or a private Git repo with restricted access).


---


## tfvars example config file - oci provider tfvars

First set of credentials to find are the credentials to setup the oci provider. The oci provider code can be found in multiple tf files hence this set of credentials is repeated in multiple places.

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

### 1. Tenancy OCID

The Tenancy OCID is the unique identifier for your entire cloud account.

* **Where:** In the top-right corner, click the **Profile** icon (the silhouette).
* **Action:** Click on **Tenancy: [Your_Tenancy_Name]**.
* **The ID:** Under the **Tenancy Information** tab, look for **OCID**. Click **Copy**.

### 2. User OCID

This is the identifier for your specific user account.

* **Where:** Click the **Profile** icon again.
* **Action:** Select **User Settings** (or click on your username).
* **The ID:** Under **User Information**, you will see your **OCID**. Click **Copy**.

### 3. Fingerprint & Private Key Path

The fingerprint is generated when you create an API Key pair.

* **Where:** On your **User Settings** page (from the step above), scroll down to the **Resources** section on the top toolbar.
* **Action:** Click **API Keys** → **Add API Key**.
* **Generate:** * Select **Generate API Key Pair**.
    * **Crucial:** Click **Download Private Key** and save it to a secure folder (e.g., `~/.oci/`).
    * Click **Add**.
* **The ID:** A pop-up will appear showing your **Fingerprint** (a series of hex pairs). It also provides a helpful configuration snippet you can copy.
* **Path:** Your `private_key_path` in Terraform is simply the local path where you just saved that `.pem` file.

### 4. Region

The region is the physical location of your data center.

* **Where:** Look at the top-right navigation bar, next to your profile icon.
* **Action:** It will show your current region (e.g., **US East (Ashburn)**).
* **The ID:** While it shows a "pretty" name, Terraform needs the **Region Identifier**.
    * Common identifiers: `us-ashburn-1`, `uk-london-1`, `eu-frankfurt-1`.
    * You can see the full list by clicking the region name and selecting **Manage Regions**.

---
---
---

## tfvars example config file - 00-bootstrap
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
tf_state_bucket_name = "my-bucket"
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

---
---
---

## tfvars example config file - 01-workloads

There will be two tfvars file to be created in `01-workloads`:
1) `terraform.tfvars`
2) `backend-config.tfvars`


`terraform.tfvars`:
```hcl
# Tenancy and User Information
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaxexample"
user_ocid        = "ocid1.user.oc1..aaaaaaaayexample"

# Authentication
fingerprint      = "20:3b:97:13:55:1c:..."
private_key_path = #TO DO, SET THIS PATH TO THE VOLUME MOUNTED PATH WITHIN DOCKER COMPOSE eg. "/workspace/.oci/oci_api_key.pem"

# Infrastructure Region
region           = "us-ashburn-1"

# =============== STOP HERE IF YOU ARE WRITING TFVARS FILE FOR BOOTSTRAP DIRECTORY ============

vcn_name = "vcn-1"
vcn_dns_label = "ohnoooo"
vcn_cidr_blocks = ["10.0.0.0/16"]
```


`backend-config.tfvars`
```hcl
bucket="tf-state-anchor-bucket"
namespace         = "mynamespace_look_for_me_in_oracle_cloud_webpage"
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaxexample"
user_ocid        = "ocid1.user.oc1..aaaaaaaayexample"

# Authentication
fingerprint      = "20:3b:97:13:55:1c:..."
private_key_path = #TO DO, SET THIS PATH TO THE VOLUME MOUNTED PATH WITHIN DOCKER COMPOSE eg. "/workspace/.oci/oci_api_key.pem"

# Infrastructure Region
region           = "us-ashburn-1"

key               = "this/is/the/path/that/the/tfstate_file/will/be/saved/in"
workspace_key_prefix = "envs/"
# kms_key_id        = "ocid1.key.oc1.iad.xxxxxxxxxxxxxx"
# auth              = "APIKey"
# config_file_profile = "DEFAULT"

```



---




---

## Verify if Oracle Cloud Provider Works

Once inside:

```bash
terraform init
terraform plan
```

You should see regions and other outputs being listed in the console. If you see it, it means that your oracle cloud is properly connected to terraform.

---
---
---
