locals {
  # Load YAML file instead of environment.hcl
  global_vars  = yamldecode(file(find_in_parent_folders("global-values.yaml")))
  environment  = local.global_vars.global.environment
  building_block = local.global_vars.global.building_block
  project = local.global_vars.global.cloud_storage_project
  region = local.global_vars.global.cloud_storage_region
  oci_region               = local.global_vars.global.oci_region
  oci_compartment_ocid     = local.global_vars.global.oci_compartment_ocid
  oci_object_storage_namespace = local.global_vars.global.oci_object_storage_namespace
  vcn_cidr_block             = local.global_vars.global.network.vcn_cidr_block
  public_kubernetes_api_subnet_cidr = local.global_vars.global.network.public_kubernetes_api_subnet_cidr
  public_load_balancer_subnet_cidr = local.global_vars.global.network.public_load_balancer_subnet_cidr
  private_worker_node_subnet_cidr  = local.global_vars.global.network.private_worker_node_subnet_cidr
  private_pod_subnet_cidr          = local.global_vars.global.network.private_pod_subnet_cidr
  private_subnet_cidr          = local.global_vars.global.network.private_subnet_cidr
}

# For local development
terraform {
  source = "../../modules//network/"
}

inputs = {
  environment         = local.environment
  building_block      = local.building_block
  project             = local.project
  region              = local.region

  compartment_ocid           = local.oci_compartment_ocid
  oci_region                 = local.oci_region
  vcn_cidr_block             = local.vcn_cidr_block

  public_kubernetes_api_subnet_cidr = local.public_kubernetes_api_subnet_cidr
  public_load_balancer_subnet_cidr = local.public_load_balancer_subnet_cidr
  private_worker_node_subnet_cidr  = local.private_worker_node_subnet_cidr
  private_pod_subnet_cidr          = local.private_pod_subnet_cidr
  private_subnet_cidr              = local.private_subnet_cidr
  allow_ssh_from_cidr              = "0.0.0.0/0" # Consider a more restrictive CIDR in production (e.g., local.root_config.locals.trusted_cidrs.ssh)

}
