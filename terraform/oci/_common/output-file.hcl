locals {
  # This section will be enabled after final code is pushed and tagged
  # source_base_url = "github.com/<org>/modules.git//app"
  global_vars  = yamldecode(file(find_in_parent_folders("global-values.yaml")))
  env = local.global_vars.global.env
  environment  = local.global_vars.global.environment
  building_block = local.global_vars.global.building_block
  storage_class = local.global_vars.global.storage_class
  region = local.global_vars.global.cloud_storage_region
  project = local.global_vars.global.cloud_storage_project
  cloud_storage_provider = local.global_vars.global.cloud_storage_provider
  oci_compartment_ocid     = local.global_vars.global.oci_compartment_ocid
  oci_object_storage_namespace     = local.global_vars.global.oci_object_storage_namespace
}

# For local development
terraform {
  source = "../../modules//output-file/"
}

dependency "storage" {
    config_path = "../storage"
    mock_outputs = {
      oci_public_bucket_name = "dummy"
      oci_private_bucket_name = "dummy"
      oci_dial_state_bucket_public_name = "dummy"
    }
}

dependency "oke" {
    config_path = "../oke"
    mock_outputs = {
      private_ingressgateway_ip = "10.1.1.1"
      encryption_string = "test"
      cluster_endpoint = "test"
      cluster_name = "test"
      cluster_id = "test"
    }
}

dependency "keys" {
    config_path = "../keys"
    mock_outputs = {
      random_string = "dummy-string"
      encryption_string = "dummy-string"
    }
}
 
 dependency "service-account" {
   config_path = "../service-account"
   mock_outputs = {
     oci_iam_user_ocid = "dummy"
     oci_iam_user_name = "dummy"
     oci_api_key_fingerprint = "dummy"
     oci_api_private_key_local_path = "dummy"
  }
}

inputs = {
  env                                = local.env
  environment                        = local.environment
  building_block                     = local.building_block
  oci_compartment_ocid               = local.oci_compartment_ocid
  oci_object_storage_namespace       = local.oci_object_storage_namespace
  oci_storage_bucket_public          = dependency.storage.outputs.oci_public_bucket_name
  oci_storage_bucket_private         = dependency.storage.outputs.oci_private_bucket_name
  storage_container_public           = dependency.storage.outputs.oci_public_bucket_name
  storage_container_private          = dependency.storage.outputs.oci_private_bucket_name
#  oci_storage_bucket_public          = "storage_container_public"
#  oci_storage_bucket_private         = "storage_container_private"
#  storage_container_public           = "storage_container_public"
#  storage_container_private          = "storage_container_private"
  private_ingressgateway_ip          = dependency.oke.outputs.private_ingressgateway_ip
  encryption_string                  = dependency.keys.outputs.encryption_string
  random_string                      = dependency.keys.outputs.random_string
  cloud_storage_region               = local.region
  dial_state_container_public        = dependency.storage.outputs.oci_dial_state_bucket_public_name
  oci_dial_state_bucket_public       = dependency.storage.outputs.oci_dial_state_bucket_public_name
  oci_project_id                     = local.project
  storage_class                      = local.storage_class
  cloud_storage_provider             = local.cloud_storage_provider
  cloud_storage_region               = local.region
  oke_cluster_endpoint               = dependency.oke.outputs.cluster_endpoint
  oke_cluster_name                   = dependency.oke.outputs.cluster_name 
}
