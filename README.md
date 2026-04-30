# oracle-cloud-infrastructure
This project will hold all the golden source code for setting up my own infrastructure

---
---
---


# Setup & Instruction to Use

## How to find values for terraform.tfvars
Setup your terraform variables by creating "terraform.tfvars" file and filling in the values found in the example below:

```hcl
# Tenancy and User Information
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaxexample"
user_ocid        = "ocid1.user.oc1..aaaaaaaayexample"

# Authentication
fingerprint      = "20:3b:97:13:55:1c:..."
private_key_path = #TO DO, SET THIS PATH TO THE VOLUME MOUNTED PATH WITHIN DOCKER COMPOSE eg. "/workspace/.oci/oci_api_key.pem"

# Infrastructure Region
region           = "us-ashburn-1"

vcn_name = "vcn-1"
vcn_dns_label = "ohnoooo"
vcn_cidr_blocks = ["10.0.0.0/16"]
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


## How to use terraform

To have terraform ready on your device, run the below code:

```bash
docker-compose run --rm terraform
```

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

# Architecture Explanation

## Architecture Diagram
![](https://raw.githubusercontent.com/bestcolour/site/refs/heads/master/assets/image/IT_Automation-Oracle_Cloud/Current%20Architecture-Oracle%20Cloud%20Resources.drawio.png)

[Read more](https://bestcolour.github.io/site/projects/IT-automation-info/#oracle-cloud-personal-architecture)

## Main tf files to look at
Here are the important files to look at for this infrastructure architecture:
1) main.tf
2) main-vcn.tf

