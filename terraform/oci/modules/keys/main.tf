provider "tls" {}

locals {
  global_values_keys_file = "${var.base_location}/../global-keys-values.yaml"
  jwt_script_location = "${var.base_location}/../../../../scripts/jwt-keys.py"
  rsa_script_location = "${var.base_location}/../../../../scripts/rsa-keys.py"
  global_values_jwt_file_location = "${var.base_location}/../../../../scripts/global-values-jwt-tokens.yaml"
  global_values_rsa_file_location = "${var.base_location}/../../../../scripts/global-values-rsa-keys.yaml"
}

resource "random_password" "generated_string" {
  length  = 16          # Length of the string (can be between 12 and 24)
  special = false        # Do not include special characters
  upper   = true         # Include uppercase letters
  lower   = true         # Include lowercase letters
  numeric = true         # Include numbers
}

resource "random_password" "encryption_string" {
  length  = 32          # Length of the string (can be between 32)
  special = false        # Do not include special characters
  upper   = true         # Include uppercase letters
  lower   = true         # Include lowercase letters
  numeric = true         # Include numbers
}

resource "null_resource" "generate_jwt_keys" {
  triggers = {
    command = "${timestamp()}"
  }

  provisioner "local-exec" {
    # The Python script should generate the JWT keys and save them directly
    # to the file specified by local.global_values_jwt_file_location.
    # It should NOT modify global-values.yaml or any other file read by Terragrunt/Terraform.
    #command = "python3 ${local.jwt_script_location} ${random_password.generated_string.result} >>  ${local.global_values_jwt_file_location}"
    command = <<-EOT
      echo "" > ${local.global_values_jwt_file_location}
      echo "" >> ${local.global_values_jwt_file_location}
      # Run the Python script and append its output to the file
      python3 ${local.jwt_script_location} ${random_password.generated_string.result} >> ${local.global_values_jwt_file_location}
    EOT
    interpreter = ["bash", "-c"] # Explicitly use bash to interpret the command
  }

}

resource "null_resource" "generate_rsa_keys" {
  # This null_resource's trigger should be stable. If rsa_keys_count changes,
  # or if the python script itself changes, then regenerate.
  triggers = {
    command = "${timestamp()}"
  }

  provisioner "local-exec" {
    # The Python script should print the content of the YAML file it intends to generate
    # to standard output.
    #command = "python3 ${local.rsa_script_location} ${var.rsa_keys_count} >> ${local.global_values_rsa_file_location}"
    command = <<-EOT
      echo "" > ${local.global_values_rsa_file_location}
      echo "" >> ${local.global_values_rsa_file_location}

      # Run the Python script and append its content (which is expected to be the YAML) to the file.
      # The Python script should print the content of the YAML file it intends to generate
      # to standard output.
      python3 ${local.rsa_script_location} ${var.rsa_keys_count} >> ${local.global_values_rsa_file_location}
    EOT

    interpreter = ["bash", "-c"]
  }

}

resource "null_resource" "upload_global_jwt_values_yaml" {
  # This trigger will change ONLY if the content of the source file changes.
  # filebase64sha256 calculates a hash of the file's content.
  triggers = {
    #file_content_hash = filebase64sha256(local.global_values_jwt_file_location)
    command = "${timestamp()}"
  }

  provisioner "local-exec" {
    # The command should overwrite the file if it exists, as the trigger ensures
    # this provisioner only runs when an update is needed.
    command = <<-EOT
      echo "INFO: Checking and uploading 'global_jwt_values.yaml' if content changed..."
      oci os object put \
        --bucket-name "${var.oci_storage_bucket_name}" \
        --name "${var.environment}-global-values-jwt-tokens.yaml" \
        --file "${local.global_values_jwt_file_location}" \
        --force \
        --query 'etag' --raw-output # Optional: Suppress verbose output, just show Etag
      echo "INFO: 'global_jwt_values.yaml' upload/overwrite complete."
    EOT
    interpreter = ["bash", "-c"] # Explicitly use bash to interpret the multi-line command

    environment = {
      # Ensure OCI_CLI_AUTH and other necessary OCI CLI env vars are set if not
      # configured via ~/.oci/config or instance principles.
      # Example (if you pass these as Terragrunt inputs or locals):
      # OCI_CLI_AUTH = "config" # Or "instance_principal"
    }
  }

  # Keep your dependency as is.
  depends_on = [null_resource.generate_jwt_keys]
}

resource "null_resource" "upload_global_rsa_values_yaml" {
  # This trigger will change ONLY if the content of the source file changes.
  # filebase64sha256 calculates a hash of the file's content.
  triggers = {
    #file_content_hash = filebase64sha256(local.global_values_rsa_file_location)
    command = "${timestamp()}"
  }

  provisioner "local-exec" {
    # The command should overwrite the file if it exists, as the trigger ensures
    # this provisioner only runs when an update is needed.
    command = <<-EOT
      echo "INFO: Checking and uploading 'global_rsa_values.yaml' if content changed..."
      oci os object put \
        --bucket-name "${var.oci_storage_bucket_name}" \
        --name "${var.environment}-global-values-rsa-keys.yaml" \
        --file "${local.global_values_rsa_file_location}" \
        --force \
        --query 'etag' --raw-output # Optional: Suppress verbose output, just show Etag
      echo "INFO: 'global_rsa_values.yaml' upload/overwrite complete."
    EOT
    interpreter = ["bash", "-c"] # Explicitly use bash to interpret the multi-line command

    environment = {
      # Ensure OCI_CLI_AUTH and other necessary OCI CLI env vars are set if not
      # configured via ~/.oci/config or instance principles.
      # Example (if you pass these as Terragrunt inputs or locals):
      # OCI_CLI_AUTH = "config" # Or "instance_principal"
    }
  }

  # Keep your dependency as is.
  depends_on = [null_resource.generate_rsa_keys]
}

# Sample code to enable encryption of global values files
# Encrypted files cannot be passed to helm

# resource "null_resource" "terrahelp_encryption" {
#   triggers = {
#     command = "${timestamp()}"
#   }
#   provisioner "local-exec" {
#       command = "terrahelp encrypt -simple-key=${random_password.generated_string.result} } -file=${local.global_values_keys_file}"
#   }
# }
