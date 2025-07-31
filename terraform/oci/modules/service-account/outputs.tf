/*
output "oci_iam_user_ocid" {
  value       = oci_identity_user.programmatic_user.id
  description = "The OCID of the OCI IAM User created for programmatic access."
}

output "oci_iam_user_name" {
  value       = oci_identity_user.programmatic_user.name
  description = "The name of the OCI IAM User created for programmatic access."
}

output "oci_api_key_fingerprint" {
  value       = oci_identity_api_key.programmatic_user_api_key.fingerprint
  description = "The fingerprint of the uploaded OCI API key."
}
*/
# DO NOT output the private key directly in Terraform if you can avoid it.
# If you absolutely must access it via Terraform (e.g., for a post-provisioning script),
# ensure it's handled with extreme care (sensitive=true, and consider OCI Vault).
# This assumes you are providing the public_key and have the private key locally.
/*
output "oci_api_private_key_local_path" {
  # This would only be relevant if you're writing the private key to a local file
  # via a separate `local_sensitive_file` resource, which is still not ideal.
  value       = "${path.module}/private_keys/${oci_identity_user.programmatic_user.name}.pem" # Example path
  description = "The local file path where the OCI API private key is expected to be stored."
  sensitive   = true
}
*/
