locals {
  # Load YAML file instead of environment.hcl
  global_vars  = yamldecode(file(find_in_parent_folders("global-values.yaml")))
  environment  = local.global_vars.global.environment
  building_block = local.global_vars.global.building_block
  project = local.global_vars.global.cloud_storage_project
  compartment_ocid     = local.global_vars.global.oci_compartment_ocid
  tenancy_ocid     = local.global_vars.global.tenancy_ocid
  oci_dynamic_group     = local.global_vars.global.oci_dynamic_group
  oci_dynamic_group_ocid     = local.global_vars.global.oci_dynamic_group_ocid
  oci_object_storage_namespace     = local.global_vars.global.oci_object_storage_namespace
}

# For local development
terraform {
  source = "../../modules//service-account/"
}

dependency "storage" {
    config_path = "../storage"
    mock_outputs = {
      oci_private_bucket_name = "dummy" 
    }

}

dependency "oke_cluster" {
  config_path = "../oke"
  
  mock_outputs = {
    cluster_id   = "mock-oke-cluster-ocid" # Use a dummy value that matches the expected type (e.g., a string for OCID)
    cluster_name = "mock-oke-cluster-name"
    # Add any other outputs that your service-account module tries to read from oke
  }
  # Set this to true if the OKE cluster is not always present (e.g., in some dev environments)
  # But if it's always required for this policy, keep it false or omit.
  # skip_outputs = false

}

inputs = {
  environment         = local.environment
  building_block      = local.building_block
  project             = local.project
  compartment_ocid     = local.compartment_ocid
  tenancy_ocid     = local.tenancy_ocid
  oci_dynamic_group     = local.oci_dynamic_group
  oci_dynamic_group_ocid     = local.oci_dynamic_group_ocid
  oci_object_storage_namespace = local.oci_object_storage_namespace
}
