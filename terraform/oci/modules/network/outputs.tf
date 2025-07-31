output "vcn_id" {
  description = "The OCID of the VCN."
  value       = oci_core_vcn.vcn.id
}

output "vcn_name" {
  description = "The display name of the VCN."
  value       = oci_core_vcn.vcn.display_name
}

output "vcn_cidr_block" {
  description = "The primary CIDR block of the VCN."
  value       = oci_core_vcn.vcn.cidr_block
}

output "public_kubernetes_api_subnet_ocid" {
  description = "The OCID of the public subnet for OKE Kubernetes API endpoint."
  value       = oci_core_subnet.public_kubernetes_api_subnet.id
}

output "public_load_balancer_subnet_ocid" {
  description = "The OCID of the public subnet for OKE Load Balancers."
  value       = oci_core_subnet.public_load_balancer_subnet.id
}

output "private_worker_node_subnet_ocid" {
  description = "The OCID of the private subnet for OKE Worker Nodes."
  value       = oci_core_subnet.private_worker_node_subnet.id
}

output "private_pod_subnet_ocid" {
  description = "The OCID of the private subnet for OKE Pods."
  value       = oci_core_subnet.private_pod_subnet.id
}

output "public_route_table_ocid" {
  description = "The OCID of the public route table."
  value       = oci_core_route_table.public_rt.id
}

output "private_route_table_ocid" {
  description = "The OCID of the private route table."
  value       = oci_core_route_table.private_rt.id
}

output "k8s_api_security_list_ocid" {
  description = "The OCID of the Security List for the Public K8s API Subnet."
  value       = oci_core_security_list.sl_k8s_api.id
}

output "lb_security_list_ocid" {
  description = "The OCID of the Security List for the Public Load Balancer Subnet."
  value       = oci_core_security_list.sl_lb.id
}

output "worker_node_security_list_ocid" {
  description = "The OCID of the Security List for the Private Worker Node Subnet."
  value       = oci_core_security_list.sl_worker_node.id
}

output "pod_security_list_ocid" {
  description = "The OCID of the Security List for the Private Pod Subnet."
  value       = oci_core_security_list.sl_pod.id
}

# NSG Outputs (RECOMMENDED for OKE integration)
output "nsg_k8s_api_endpoint_ocid" {
  description = "OCID of the Network Security Group for OKE K8s API Endpoint."
  value       = oci_core_network_security_group.nsg_k8s_api_endpoint.id
}

output "nsg_worker_node_ocid" {
  description = "OCID of the Network Security Group for OKE Worker Nodes."
  value       = oci_core_network_security_group.nsg_worker_node.id
}

output "nsg_internal_lb_ocid" {
  description = "OCID of the Network Security Group for OKE Internal Load Balancers."
  value       = oci_core_network_security_group.nsg_internal_lb.id
}

output "nsg_external_lb_ocid" {
  description = "OCID of the Network Security Group for OKE External Load Balancers."
  value       = oci_core_network_security_group.nsg_external_lb.id
}

output "nsg_pod_ocid" {
  description = "OCID of the Network Security Group for OKE Pods."
  value       = oci_core_network_security_group.nsg_pod.id
}

