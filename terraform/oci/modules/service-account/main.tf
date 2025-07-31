# main.tf (OCI IAM and Workload Identity Setup)

locals {
  # Common tags for OCI resources
  oci_freeform_tags = {
    environment   = var.environment
    BuildingBlock = var.building_block
  }
  environment_name = "${var.building_block}-${var.environment}"

  enable_workload_identity_setup = var.enable_oke_workload_identity

  dynamic_group_name = var.oci_dynamic_group

  # Base policy statement templates (static strings)
  base_policy_statement_templates = [
    "Allow dynamic-group %s to manage instance-family in compartment id %s",
    "Allow dynamic-group %s to use volume-family in compartment id %s",
    "Allow dynamic-group %s to use secret-family in compartment id %s",
    "Allow dynamic-group %s to read metrics in compartment id %s",
    "Allow dynamic-group %s to manage object-family in compartment id %s",
    "Allow dynamic-group %s to manage bucket-family in compartment id %s",
    "Allow dynamic-group %s to use ons-topics in compartment id %s",
    "Allow dynamic-group %s to read database-family in compartment id %s",
    "Allow dynamic-group %s to use virtual-network-family in compartment id %s", # Crucial for networking
    "Allow dynamic-group %s to use functions-family in compartment id %s", # If you use OCI Functions
    "Allow dynamic-group %s to use cloudevents-rules in compartment id %s", # If you use OCI Events
    "Allow dynamic-group %s to manage autonomous-container-databases in compartment id %s", # If using ADB
  ]

  default_oke_policy_statements = [
    for statement_template in local.base_policy_statement_templates :
    format(statement_template, local.dynamic_group_name, var.compartment_ocid)
  ]

  # This is the final list of policy statements to be used.
  # It checks if var.service_account_roles was provided; if not, it uses the generated default.
  final_policy_statements = var.service_account_roles != null ? var.service_account_roles : local.default_oke_policy_statements

}

## 1. Create an OCI IAM Dynamic Group for your OKE worker nodes
## This group will implicitly contain all OKE worker nodes in the specified compartment/cluster.
#resource "oci_identity_dynamic_group" "oke_nodes_dg" {
#  provider       = oci
#  compartment_id = var.tenancy_ocid
#  name           = "${local.environment_name}-oke-nodes-dg"
#  description    = var.cluster_service_account_description # Use the description variable
#
#  # Rule to match OKE worker nodes (based on dynamic group rule best practices)
#  # This rule ensures that any compute instance belonging to the OKE cluster
#  # will be part of this dynamic group. Adjust if your naming convention is different.
#  matching_rule = "ALL {instance.compartment.id = '${var.compartment_ocid}', instance.display-name =~ '^${local.environment_name}-pool-.*$'}"
#  # A more robust rule for OKE might be based on instance pool OCIDs or specific tags applied by OKE.
#  # Example for OKE-managed node pools (these have a specific tag automatically added by OKE):
#  # matching_rule = "ALL {instance.compartment.id = '${var.compartment_ocid}', tag.oke.cluster.id = '${oci_containerengine_cluster.cluster.id}'}"
#  # This requires the cluster to exist first.
#  # For initial setup, the display-name regex is often safer if you name your node pools predictably.
#
#  freeform_tags = local.oci_freeform_tags
#}

# 2. Create an OCI IAM Policy that grants permissions to the Dynamic Group
resource "oci_identity_policy" "oke_nodes_policy" {
  provider       = oci
  compartment_id = var.compartment_ocid # Policy scoped to this compartment
  name           = "${local.environment_name}-oke-nodes-policy"
  description    = "Policy for OKE worker nodes via Dynamic Group"

  # Policy statements based on `var.service_account_roles`
  # Each string in the list becomes a separate policy statement.
  #statements = local.final_policy_statements

  # Example for Storage Admin equivalent (granular for OCI)
  statements = [
    "Allow dynamic-group id ${var.oci_dynamic_group_ocid} to manage all-resources in compartment id ${var.compartment_ocid}"
  ]

  freeform_tags = local.oci_freeform_tags
}

# The OKE cluster resource (`oci_containerengine_cluster.cluster`) should have:
# options {
#   workload_identity_config {
#     enabled = true
#     # No direct configuration in Terraform for Workload Identity here beyond enabling.
#     # The actual federation is done via annotations on K8s Service Accounts.
#   }
# }

# OCI Workload Identity Policy for the K8s Service Account
# This policy allows the OKE Workload Identity service to federate a K8s SA to a Dynamic Group
resource "oci_identity_policy" "oke_k8s_sa_policy" {
  count = local.enable_workload_identity_setup ? 1 : 0

  provider       = oci
  compartment_id = var.compartment_ocid
  name           = "${local.environment_name}-k8s-sa-policy"
  description    = "Policy to allow Kubernetes Service Account to federate with OCI IAM Dynamic Group via Workload Identity."

  # This policy allows the OKE Workload Identity service (which runs in your tenancy)
  # to 'act as' (federate) your Kubernetes Service Accounts into the Dynamic Group.
  statements = [
    "Allow dynamic-group ${var.oci_dynamic_group} to use ANY {instance-pool-id} in compartment id ${var.compartment_ocid}",
    # The crucial Workload Identity statement:
    # "OKE_WORKLOAD_IDENTITY_PRINCIPAL" is a special IAM principal representing a federated K8s SA.
    # It must be scoped to specific K8s SA and cluster.
    #"Define PRINCIPAL_NAME as `OCI_WORKLOAD_IDENTITY_POOL/ocid1.cluster.oc1.${var.oci_region}.${dependency.oke_cluster.outputs.cluster_id}/${var.k8s_service_account_namespace}/${var.k8s_service_account_name}`",
    "ENDORSE PRINCIPAL_NAME to use dynamic-group ${var.oci_dynamic_group} in tenancy"
  ]

  freeform_tags = local.oci_freeform_tags
}


# --- Service Account Key Generation & Upload (Discouraged for OCI in most cases) ---
# The following resources are generally NOT needed for OCI OKE best practices.
# If you *still* need a service account key for some non-OKE-related programmatic access,
# you would create an OCI IAM User and generate an API key for that user.
# Then, you'd securely store it (e.g., in OCI Vault, not a local file + object storage).

/*
# Create an OCI IAM User (if you need a programmatic user with API keys)
resource "oci_identity_user" "programmatic_user" {
  # Only if you absolutely need a traditional API key for some external system.
  # Not recommended for OKE node/pod permissions.
  # count = var.create_programmatic_user ? 1 : 0 # Example conditional creation

  compartment_id = var.compartment_ocid
  name           = "${local.environment_name}-programmatic-user"
  description    = "Programmatic user for ${local.environment_name} applications."
  email          = "tf-user-${local.environment_name}@example.com" # Must be unique
}

# Generate an API Key for that OCI IAM User
resource "oci_identity_api_key" "programmatic_user_api_key" {
  # count = var.create_programmatic_user ? 1 : 0 # Example conditional creation

  user_id     = oci_identity_user.programmatic_user[0].id
  public_key  = var.programmatic_user_public_api_key # You'd provide a public key here

  # OCI does not generate private keys. You generate the key pair locally,
  # give the public key to OCI, and keep the private key secure.
}

# Storing the key to local file and then uploading is still possible but discouraged
# for automated key management. If you need to store secrets, use OCI Vault.

resource "null_resource" "upload_sensitive_file_to_os" {
  # This assumes you have a private key file generated locally via some other process
  # and you need to upload it. This is generally NOT the pattern for OCI API keys
  # directly generated by Terraform.

  count = var.sa_key_store_bucket != null ? 1 : 0

  triggers = {
    command = "${timestamp()}"
    file_content_hash = filemd5("${path.module}/sa-keys/${local.environment_name}.json") # Watch file content
  }

  provisioner "local-exec" {
    command = "oci os object put -bn ${var.sa_key_store_bucket} --name service-accounts/${local.environment_name}.json --file ${path.module}/sa-keys/${local.environment_name}.json --namespace ${var.oci_object_storage_namespace}"
  }
  # depends_on = [local_file.service_account] # If you were still using local_file
}
*/
