# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These parameters must be supplied when consuming this module.
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# OCI START
# ---------------------------------------------------------------------------------------------------------------------

variable "compartment_ocid" {
  description = "The OCID of the compartment where OKE resources will be created."
  type        = string
}

variable "oke_vcn_id" {
  description = "The OCID of the VCN for the OKE cluster."
  type        = string
}

variable "oke_kubernetes_api_endpoint_subnet_id" {
  description = "The OCID of the private subnet for the OKE Kubernetes API endpoint."
  type        = string
}

variable "oke_worker_node_subnet_id" {
  description = "The OCID of the subnet for OKE worker nodes."
  type        = string
}

variable "oke_kms_key_id" {
  description = "OCID of the KMS key for secrets encryption (optional)."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the OKE cluster (e.g., 'v1.28.3')."
  type        = string
}

variable "cluster_type" {
  description = "The OKE cluster type (Values can be BASIC_CLUSTER or ENHANCED_CLUSTER)."
  type        = string
  default     = "ENHANCED_CLUSTER"
}

variable "instance_type" {
  description = "The instance shape for OKE worker nodes (e.g., 'VM.Standard.E3.Flex')."
  type        = string
  default     = "VM.Standard.E3.Flex"
}

variable "node_pool_ocpus" {
  description = "Number of OCPUs for flexible node pool shapes (e.g., VM.Standard.E3.Flex). Must be within the shape's allowed range."
  type        = number
  default     = 5 # A common starting point for flexible shapes, adjust as needed
}

variable "node_pool_ssh_public_key" {
  description = "node_pool_ssh_public_key."
  type        = string
}

variable "node_pool_memory_in_gbs" {
  description = "Amount of memory in GBs for flexible node pool shapes. Must be within the shape's allowed range (often 8GB/OCPU for E3/E4, 6GB/OCPU for A1.Flex)."
  type        = number
  default     = 48 # Example: 2 OCPUs * 8GB/OCPU = 16GB
}

variable "oke_node_pool_scaling_min_size" {
  description = "Minimum number of nodes in the OKE node pool."
  type        = number
  default     = 1
}

variable "oke_node_pool_scaling_max_size" {
  description = "Maximum number of nodes in the OKE node pool."
  type        = number
  default     = 5
}

variable "oke_node_pool_scaling_desired_size" {
  description = "Desired number of nodes in the OKE node pool."
  type        = number
  default     = 1
}

variable "oke_node_pool_network_tags" {
  description = "Freeform tags to apply to the network interfaces of worker nodes."
  type        = list(string)
  default     = []
}

variable "oke_node_default_disk_size_gb" {
  description = "Boot volume size for OKE worker nodes in GBs."
  type        = number
  default     = 100
}

variable "oke_pod_security_policy_enabled" {
  description = "Whether to enable Pod Security Policy addon."
  type        = bool
  default     = false
}

variable "oke_network_security_group_ids_control_plane" {
  description = "List of NSG OCIDs for the control plane endpoint."
  type        = list(string)
  default     = []
}

variable "oke_network_security_group_ids_worker_nodes" {
  description = "List of NSG OCIDs for worker nodes."
  type        = list(string)
  default     = []
}

variable "oke_node_image_id" {
  description = "OCID of the custom or platform image for OKE worker nodes. Oracle-Linux-8.10-aarch64-2025.05.19-0-OKE-1.33.1-804"
  type        = string
  default     = "ocid1.image.oc1.iad.aaaaaaaau3ahhbqeyyfikf27szllwurv7k2w6yo3ffwupmpk4sm6korpq7ra"
}

variable "oke_node_image_display_name_pattern" {
  description = "Pattern to search for the OKE node image. E.g., 'Oracle-Linux-8-OKE-*-GPU' or 'Oracle-Linux-8-OKE-*'."
  type        = string
  default     = "Oracle-Linux-8*" # Common default for OKE worker nodes
}

variable "oke_kubernetes_version_for_image" {
  description = "The Kubernetes version for which to find a compatible OKE image (e.g., 'v1.28.0')."
  type        = string
  # IMPORTANT: Make sure this matches the kubernetes_version of your OKE cluster!
  # You might want to get this from a data source for the cluster itself if available,
  # or pass the cluster's K8s version as an input here.
  # For simplicity, let's assume it's derived from the cluster if not explicitly passed.
  default = null # Will be derived or taken from cluster/service options if cluster K8s version is known.
}

variable "region" {
  description = "The OCI region where resources will be deployed."
  type        = string
}

variable "identity_namespace" {
  description = "OCI IAM namesapce"
  type        = string
}

variable "resource_labels" {
  description = "Freeform tags to apply to OKE cluster and node pool."
  type        = map(string)
  default     = {}
}

variable "pod_cidr_block" {
  description = "The IP range in CIDR notation to use for the pod network."
  type        = string
  default     = "10.244.0.0/16" # Example: Ensure this doesn't overlap with your VCN CIDR
}

variable "services_cidr_block" {
  description = "The IP range in CIDR notation to use for the services network."
  type        = string
  default     = "10.96.0.0/16"
}

# ---------------------------------------------------------------------------------------------------------------------
# OCI END
# ---------------------------------------------------------------------------------------------------------------------

variable "building_block" {
  type        = string
  description = "Building block name. All resources will be prefixed with this value."
}

variable "environment" {
    type        = string
    description = "environment name. All resources will be prefixed with this value."
}

variable "env" {
  type        = string
  description = "Environment name. All resources will be prefixed with this value."
}

variable "project" {
  description = "The project ID to host the cluster in"
  type        = string
}

variable "location" {
  description = "The location (region or zone) to host the cluster in"
  type        = string
}

## VPC

variable "create_network" {
  description = "Create a new VPC network."
  type        = bool
  default     = false
}

variable "cluster_secondary_range_name" {
  description = "The name of the secondary range within the subnetwork for the cluster to use"
  type        = string
  default = ""
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the cluster"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "description" {
  description = "The description of the cluster"
  type        = string
  default     = "sunbird-ed cluster"
}

variable "oke_node_pool_instance_type" {
  type        = string
  description = "OKE nodepool instance types."
}

variable "oke_node_pool_scaling_config" {
  type        = map(number)
  description = "OKE node group auto scaling configuration."
  default     = {
    desired_size = 3
    min_size = 3
    max_size = 3
  }
}

variable "kubernetes_storage_class" {
  type        = string
  description = "Storage class name for the OKE cluster"
  default     = "oci-bv"
}

variable "kubernetes_storage_class_raw" {
  type        = string
  description = "Storage class name in raw format, they use a different notation than the GKE cluster"
  default     = "premium-rwo"
}

variable "oke_node_pool_preemptible" {
  type        = bool
  description = "Whether to use preemptible nodes for the GKE cluster; use `true` for fault-tolerant workloads, `false` otherwise. Ref: https://cloud.oracle.com/kubernetes-engine/docs/how-to/preemptible-vms"
  default     = false
}

variable "logging_service" {
  description = "The logging service that the cluster should write logs to. Available options include logging.oracleapis.com/kubernetes, logging.oracleapis.com (legacy), and none"
  type        = string
  default     = "logging.oracleapis.com/kubernetes"
}


variable "horizontal_pod_autoscaling" {
  description = "Whether to enable the horizontal pod autoscaling addon"
  type        = bool
  default     = true
}

variable "http_load_balancing" {
  description = "Whether to enable the http (L7) load balancing addon"
  type        = bool
  default     = true
}

variable "oci_filestore_csi_driver" {
  description = "Whether to enable the Filestore CSI driver addon"
  type        = bool
  default     = true
}

variable "gce_persistent_disk_csi_driver" {
  description = "Whether to enable the Google Compute Engine Persistent Disk Container Storage Interface (CSI) Driver addon"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Control whether nodes have internal IP addresses only. If enabled, all nodes are given only RFC 1918 private addresses and communicate with the master via private networking."
  type        = bool
  default     = false
}

variable "disable_public_endpoint" {
  description = "Control whether the master's internal IP address is used as the cluster endpoint. If set to 'true', the master can only be accessed from internal IP addresses."
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted master network. This range will be used for assigning internal IP addresses to the master or set of masters, as well as the ILB VIP. This range must not overlap with any other ranges in use within the cluster's network."
  type        = string
  default     = ""
}

variable "network_project" {
  description = "The project ID of the shared VPC's host (for shared vpc support)"
  type        = string
  default     = ""
}

variable "master_authorized_networks_config" {
  description = <<EOF
  The desired configuration options for master authorized networks. Omit the nested cidr_blocks attribute to disallow external access (except the cluster node IPs, which GKE automatically whitelists)
  ### example format ###
  master_authorized_networks_config = [{
    cidr_blocks = [{
      cidr_block   = "10.0.0.0/8"
      display_name = "example_network"
    }],
  }]
EOF
  type        = list(any)
  default     = []
}

variable "maintenance_start_time" {
  description = "Time window specified for daily maintenance operations in RFC3339 format"
  type        = string
  default     = "05:00"
}

variable "alternative_default_service_account" {
  description = "Alternative Service Account to be used by the Node VMs. If not specified, the default compute Service Account will be used. Provide if the default Service Account is no longer available."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS - RECOMMENDED DEFAULTS
# These values shouldn't be changed; they're following the best practices defined at https://cloud.oracle.com/kubernetes-engine/docs/how-to/hardening-your-cluster
# ---------------------------------------------------------------------------------------------------------------------

variable "enable_legacy_abac" {
  description = "Whether to enable legacy Attribute-Based Access Control (ABAC). RBAC has significant security advantages over ABAC."
  type        = bool
  default     = false
}

variable "enable_network_policy" {
  description = "Whether to enable Kubernetes NetworkPolicy on the master, which is required to be enabled to be used on Nodes."
  type        = bool
  default     = true
}

variable "basic_auth_username" {
  description = "The username used for basic auth; set both this and `basic_auth_password` to \"\" to disable basic auth."
  type        = string
  default     = ""
}

variable "basic_auth_password" {
  description = "The password used for basic auth; set both this and `basic_auth_username` to \"\" to disable basic auth."
  type        = string
  default     = ""
}

variable "secrets_encryption_kms_key" {
  description = "The Cloud KMS key to use for the encryption of secrets in etcd, e.g: projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key"
  type        = string
  default     = null
}
 variable "gsuite_domain_name" {  
  description = "The G Suite domain name to use for the cluster"
  type        = string
  default     = ""
   
 }

# See https://cloud.oracle.com/kubernetes-engine/docs/concepts/verticalpodautoscaler
variable "enable_vertical_pod_autoscaling" {
  description = "Whether to enable Vertical Pod Autoscaling"
  type        = string
  default     = false
}

variable "services_secondary_range_name" {
  description = "The name of the secondary range within the subnetwork for the services to use"
  type        = string
  default     = null
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity on the cluster"
  default     = true
  type        = bool
}

variable "private_ingressgateway_ip" {
    type        = string
    description = "Nginx private ingress ip."
    default = "10.0.0.10"
}
