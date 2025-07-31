locals {
  # This section will be enabled after final code is pushed and tagged
  # source_base_url = "github.com/<org>/modules.git//app"
  global_vars  = yamldecode(file(find_in_parent_folders("global-values.yaml")))
  environment  = local.global_vars.global.environment
  building_block = local.global_vars.global.building_block
  oci_storage_bucket_name = get_env("TERRAFORM_BACKEND_BUCKET") 
}

# For local development
terraform {
  source = "../../modules//keys/"
}

dependency "storage" {
    config_path = "../storage"
    mock_outputs = {
      oci_private_bucket_name = "dummy-container-private"   
      storage_container_public = "dummy-container-public"                      
      oci_public_bucket_name = "dummy-container-public"                      
    }
}

inputs = {
  environment                          = local.environment
  storage_container_private            = dependency.storage.outputs.oci_private_bucket_name
  building_block                       = local.building_block
  storage_container_public             = dependency.storage.outputs.oci_public_bucket_name
  oci_storage_bucket_name              = local.oci_storage_bucket_name
}
