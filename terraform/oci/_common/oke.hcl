locals {
  # This section will be enabled after final code is pushed and tagged
  # source_base_url = "github.com/<org>/modules.git//app"
  global_vars  = yamldecode(file(find_in_parent_folders("global-values.yaml")))
  environment  = local.global_vars.global.environment
  building_block = local.global_vars.global.building_block
  project = local.global_vars.global.cloud_storage_project
  zone = local.global_vars.global.zone
  identity_namespace = local.global_vars.global.oci_object_storage_namespace
  location= local.global_vars.global.cloud_storage_region 
  create_network= local.global_vars.global.create_network
 
  kubernetes_version       = local.global_vars.global.kubernetes_version 
  oci_region               = local.global_vars.global.oci_region
  oci_compartment_ocid     = local.global_vars.global.oci_compartment_ocid
  oci_object_storage_namespace = local.global_vars.global.oci_object_storage_namespace
  node_pool_ssh_public_key     = local.global_vars.global.node_pool_ssh_public_key

  oke_node_pool_instance_type= local.global_vars.global.oke_node_pool_instance_type
  oke_node_default_disk_size_gb= local.global_vars.global.oke_node_default_disk_size_gb
  oke_node_pool_scaling_desired_size = local.global_vars.global.oke_node_pool_scaling_desired_size
  region = local.global_vars.global.cloud_storage_region
  env = local.global_vars.global.env
  # random_string  = local.environment_vars.locals.random_string 
}

# For local development
terraform {
  source = "../../modules//oke/"
}

dependency "network" {
    config_path = "../network"
    mock_outputs = {
      network = "sunbird-vpc"
      public_subnetwork = "dummy"
      subnetwork = "dummy"
      public_services_secondary_range_name = "dummy"
      vcn_id = "dummy"
      public_kubernetes_api_subnet_ocid = "dummy"
      private_worker_node_subnet_ocid = "dummy"
    }
}

inputs = {
  environment                        = local.environment
  building_block                     = local.building_block
  kubernetes_version	             = local.kubernetes_version
  identity_namespace                 = local.identity_namespace

  oke_vcn_id                            = dependency.network.outputs.vcn_id
  oke_kubernetes_api_endpoint_subnet_id = dependency.network.outputs.public_kubernetes_api_subnet_ocid
  oke_worker_node_subnet_id             = dependency.network.outputs.private_worker_node_subnet_ocid
  

  project                            = local.project
  zone                               = local.zone
  region                             = local.region
  location                           = local.location
  create_network                     = local.create_network
  oke_node_pool_instance_type        = local.oke_node_pool_instance_type
  oke_node_default_disk_size_gb      = local.oke_node_default_disk_size_gb
  oke_node_pool_scaling_desired_size = local.oke_node_pool_scaling_desired_size
  node_pool_ssh_public_key           = local.node_pool_ssh_public_key
  env                                = local.env
  compartment_ocid                   = local.oci_compartment_ocid
}
