# # https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-compute.htm


# variable "ssh_key_folder_path" {
#   type = string
#   description = "The local path in which the automated ssh key generation will be placed in."
# }


# # 1. Generate the RSA key pair
# resource "tls_private_key" "compute_1_ssh_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# # 2. Save the Private Key to your local folder (via the Docker mount)
# resource "local_file" "ssh_private_key" {
#   content         = tls_private_key.compute_1_ssh_key.private_key_pem
#   filename        = "${path.module}/${var.ssh_key_folder_path}/id_rsa_oci.pem"
#   file_permission = "0600"
# }
