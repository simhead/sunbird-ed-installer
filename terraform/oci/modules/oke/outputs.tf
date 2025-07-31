output "cluster_name" {
  description = "The name of the OKE cluster. This output is used for interpolation with node pools, other modules."
  value       = oci_containerengine_cluster.cluster.name
}

output "kubernetes_version" { # Changed from master_version to kubernetes_version for OCI
  description = "The Kubernetes cluster version."
  value       = oci_containerengine_cluster.cluster.kubernetes_version
}

output "cluster_id" { # OCI uses 'id' for the cluster OCID, which is a key identifier
  description = "The OCID of the OKE cluster."
  value       = oci_containerengine_cluster.cluster.id
}

output "cluster_endpoint" { # OKE exposes endpoint details in the 'endpoints' block
  description = "The public endpoint of the OKE cluster master."
  sensitive   = true # Still sensitive
  value       = oci_containerengine_cluster.cluster.endpoints[0].public_endpoint # Accessing the first public endpoint
  # If you are using a private endpoint, you might want to output that instead or additionally:
  # value = oci_containerengine_cluster.cluster.endpoints[0].private_endpoint
}

# output "client_certificate" {
#   description = "Public certificate used by clients to authenticate to the cluster endpoint. (Not directly exposed for OKE)"
#   value       = "Use `oci ce cluster create-kubeconfig` to get kubeconfig."
# }

# output "client_key" {
#   description = "Private key used by clients to authenticate to the cluster endpoint. (Not directly exposed for OKE)"
#   value       = "Use `oci ce cluster create-kubeconfig` to get kubeconfig."
#   sensitive   = true
# }

# output "cluster_ca_certificate" {
#   description = "The public certificate that is the root of trust for the cluster. (Not directly exposed for OKE)"
#   value       = "Use `oci ce cluster create-kubeconfig` to get kubeconfig."
# }

output "private_ingressgateway_ip" {
  # This variable seems to be an input to your GKE module.
  # If it's still a relevant IP you manage externally, you can keep it as is.
  # Otherwise, reconsider its necessity for OKE.
  value = var.private_ingressgateway_ip
}

output "storage_class_note" { # Renamed and changed value, as OKE doesn't have a direct attribute for this
  description = "Note: The default storage class for OKE uses OCI Block Volume. No direct Terraform attribute here."
  value       = "OKE typically uses the OCI Block Volume CSI Driver for default storage. You configure StorageClasses in Kubernetes."
  # You might want to output a specific storage class name if you deploy it via Kubernetes manifests.
  # For example, if you define a custom default storage class within the cluster's Kubernetes manifests.
}

output "node_pool_id" {
  description = "The OCID of the primary node pool created with the cluster."
  value       = oci_containerengine_node_pool.node_pool.id
}

output "node_pool_name" {
  description = "The name of the primary node pool created with the cluster."
  value       = oci_containerengine_node_pool.node_pool.name
}

# Add an output for easy kubeconfig generation instructions
output "kubeconfig_command" {
  description = "Command to generate kubeconfig for the OKE cluster."
  value = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.cluster.id} --file ~/.kube/config --region ${var.region} --overwrite"
}

#output "debug_all_oke_node_images" {
#  description = "All images found by oci_core_images data source"
#  value       = data.oci_core_images.oke_node_images.images
#}
#
#output "debug_cluster_kubernetes_version" {
#  description = "Kubernetes version used for filtering"
#  value       = local.cluster_kubernetes_version_to_filter
#}
#
#output "debug_oke_node_image_display_name_pattern" {
#  description = "Image display name pattern used for filtering"
#  value       = var.oke_node_image_display_name_pattern
#}
#
#output "debug_filtered_compatible_images_raw" {
#  description = "Images remaining after pattern and K8s version filtering"
#  value       = local.filtered_compatible_images
#}
#
#output "debug_selected_node_image_id_final" {
#  description = "The final image ID selected (will be null if none found)"
#  value       = local.selected_node_image_id
#}
