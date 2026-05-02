# This is file is used to verify if your oracle cloud provider has been set up correctly. 
# To do so, run the code below:
# terraform init
# terraform plan

# This data source simply lists Availability Domains. 
# If this works, your authentication is correct.
data "oci_identity_availability_domains" "test_ads" {
  compartment_id = var.tenancy_ocid
}

# to print the fetched information (Output names) to your terminal
output "ads" {
  value = data.oci_identity_availability_domains.test_ads.availability_domains[*].name
}