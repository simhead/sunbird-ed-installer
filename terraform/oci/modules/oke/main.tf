# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A OKE CLUSTER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Data source to get Availability Domains in the region
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid # compartment OCID of your cluster
}

data "oci_core_images" "oke_node_images" {
  compartment_id = var.compartment_ocid
  # Only list available (active) images
  state = "AVAILABLE"
  # Optional: Filter by operating system. This makes the search more specific.
  operating_system = "Oracle Linux" # Or "Ubuntu" if you use Ubuntu for OKE
}

data "local_file" "cloud_init" {
  filename = "${path.module}/cloud-init-node-pool.sh"
}

locals {
  workload_identity_config = !var.enable_workload_identity ? [] : var.identity_namespace == null ? [{
    identity_namespace = "${var.project}.svc.id.goog"
  }] : [{
    identity_namespace = var.identity_namespace
  }]

  common_tags = {
    environment    = var.environment
    BuildingBlock  = var.building_block
  }

  environment_name = "${var.building_block}-${var.environment}"

  cluster_kubernetes_version_to_filter = var.kubernetes_version

  # Filter images based on display name pattern and Kubernetes version
  filtered_compatible_images = [
    for img in data.oci_core_images.oke_node_images.images : img
    # Condition 1: Check if the display name matches the regex pattern
    # length(regex(...)) > 0 correctly checks for a match.
    if length(regex(var.oke_node_image_display_name_pattern, img.display_name)) > 0 &&
       # Condition 2: Check if the display name contains the Kubernetes version string
       # Using strcontains() for substring check.
       strcontains(img.display_name, replace(local.cluster_kubernetes_version_to_filter, "v", ""))
  ]

  # Just pick the first compatible image found in the list.
  selected_node_image_id = length(local.filtered_compatible_images) > 0 ? local.filtered_compatible_images[0].id : null

}

# OCI OKE Cluster
resource "oci_containerengine_cluster" "cluster" {
  provider       = oci

  # Required
  compartment_id = var.compartment_ocid
  vcn_id         = var.oke_vcn_id
  name           = "${local.environment_name}" 
  kubernetes_version = var.kubernetes_version

  # OKE specific options
  kms_key_id     = coalesce(var.oke_kms_key_id, "none") != "none" ? var.oke_kms_key_id : null

  endpoint_config {
    is_public_ip_enabled = !var.disable_public_endpoint
    # master_ipv4_cidr_block from GKE is handled by OCI's VCN subnet configuration
    # You can add NSGs for API access control (similar to GKE's master_authorized_networks_config)
    nsg_ids = var.oke_network_security_group_ids_control_plane
    subnet_id = var.oke_kubernetes_api_endpoint_subnet_id
  }

  options {
    admission_controller_options {
      is_pod_security_policy_enabled = var.oke_pod_security_policy_enabled
    }

    kubernetes_network_config {
      pods_cidr    = var.pod_cidr_block # Example: Ensure this doesn't overlap with your VCN CIDR
      services_cidr = var.services_cidr_block # Example: Ensure this doesn't overlap with your VCN CIDR
      # For OCI_VCN_IP_NATIVE, you might also specify pod_nsg_ids and pod_subnet_ids in node pool
    }
  }

  freeform_tags = var.resource_labels

  lifecycle {
    ignore_changes = [freeform_tags]
  }
  
  type = var.cluster_type
}

# OCI OKE Node Pool
resource "oci_containerengine_node_pool" "node_pool" {
  provider       = oci

  # Required
  compartment_id = var.compartment_ocid
  cluster_id     = oci_containerengine_cluster.cluster.id
  name           = "${var.building_block}-${local.environment_name}-pool" 
  node_shape     = var.instance_type 

  #node_metadata   = { user_data: base64encode(data.local_file.cloud_init.content) }
  ssh_public_key  = var.node_pool_ssh_public_key

  node_shape_config {
    ocpus         = var.node_pool_ocpus
    memory_in_gbs = var.node_pool_memory_in_gbs
  }

  # Optional
  node_source_details {
    image_id                = var.oke_node_image_id # OCID of the OS image
    #image_id          = local.selected_node_image_id # Use the dynamically selected image ID
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = var.oke_node_default_disk_size_gb 
  }

  initial_node_labels {
    key          = "oke-node"
    value        = local.environment_name
  }

  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = var.oke_worker_node_subnet_id
    }

    # add NSGs to worker node VNICs for network tagging equivalent.
    nsg_ids = var.oke_network_security_group_ids_worker_nodes
    size = var.oke_node_pool_scaling_desired_size 
  }

  freeform_tags = var.resource_labels
  #defined_tags  = {"Operations.CostCenter"= defined_tags.value}

}

# Configure kubectl (OCI equivalent)
# This null_resource will run a local command to get kubeconfig.
resource "null_resource" "configure_kubectl" {
  triggers = {
    cluster_ocid = oci_containerengine_cluster.cluster.id
    region       = var.region
    force_update = timestamp() # Forces re-run every time
  }

  provisioner "local-exec" {
    command = "oci ce cluster create-kubeconfig --cluster-id ${self.triggers.cluster_ocid} --file ~/.kube/config --region ${self.triggers.region} --overwrite"
    environment = {
      KUBECONFIG = pathexpand("~/.kube/config")
    }
  }

  depends_on = [oci_containerengine_cluster.cluster]
}

#-----------------------------------------------------------

