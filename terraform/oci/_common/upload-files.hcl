# For local development
locals {
  # This section will be enabled after final code is pushed and tagged
  # source_base_url = "github.com/<org>/modules.git//app"
  global_vars  = yamldecode(file(find_in_parent_folders("global-values.yaml")))
  env = local.global_vars.global.env
  environment  = local.global_vars.global.environment
  building_block = local.global_vars.global.building_block
  oci_region = local.global_vars.global.cloud_storage_region
  project = local.global_vars.global.cloud_storage_project
  cloud_storage_provider = local.global_vars.global.cloud_storage_provider
  oci_compartment_ocid     = local.global_vars.global.oci_compartment_ocid
  oci_object_storage_namespace     = local.global_vars.global.oci_object_storage_namespace
}

terraform {
  source = "../../modules//upload-files/"
}

dependency "storage" {
    config_path = "../storage"
    mock_outputs = {
      oci_public_bucket_name = "dummy-container-public"
      oci_private_bucket_name = "dummy"
    }
}

dependency "service-account" {
  config_path = "../service-account"
  mock_outputs = {
    #service_account_email = "dummy-service-account-email"
    #service_account_key_local_path = "dummy-service-account-key"
  }
}

inputs = {
  #storage_container_public              = dependency.storage.outputs.oci_public_bucket_name
  #storage_account_name                  = dependency.service-account.outputs.service_account_key_email
  #storage_account_primary_access_key    = dependency.service-account.outputs.service_account_key_local_path

  oci_region                         = local.oci_region
  oci_compartment_ocid               = local.oci_compartment_ocid
  oci_object_storage_namespace       = local.oci_object_storage_namespace
  oci_storage_bucket_public          = dependency.storage.outputs.oci_public_bucket_name
  oci_storage_bucket_private         = dependency.storage.outputs.oci_private_bucket_name
}
