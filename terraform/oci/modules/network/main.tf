# main.tf (or relevant network .tf files)

locals {
  common_tags = {
    environment   = var.environment
    BuildingBlock = var.building_block
  }
  environment_name = "${var.building_block}-${var.environment}"

  prefix              = "${local.environment_name}"
  vcn_display_name    = "${local.prefix}-vcn"
  igw_display_name    = "${local.prefix}-igw"
  nat_gw_display_name = "${local.prefix}-natgw"
  sgw_display_name    = "${local.prefix}-sgw"

  public_kubernetes_api_subnet_display_name = "${local.prefix}-k8s-api-subnet"
  public_load_balancer_subnet_display_name  = "${local.prefix}-lb-subnet"
  private_worker_node_subnet_display_name   = "${local.prefix}-worker-subnet"
  private_pod_subnet_display_name           = "${local.prefix}-pod-subnet"

  # Security List display names
  sl_k8s_api_display_name      = "${local.prefix}-k8s-api-sl"
  sl_lb_display_name           = "${local.prefix}-lb-sl"
  sl_worker_node_display_name  = "${local.prefix}-worker-sl"
  sl_pod_display_name          = "${local.prefix}-pod-sl"

  # Network Security Group (NSG) display names (recommended for OKE)
  nsg_k8s_api_endpoint_display_name = "${local.prefix}-k8s-api-endpoint-nsg" # For OKE API endpoint
  nsg_worker_node_display_name      = "${local.prefix}-worker-node-nsg"      # For OKE worker nodes
  nsg_internal_lb_display_name      = "${local.prefix}-internal-lb-nsg"      # For OKE internal LBs
  nsg_external_lb_display_name      = "${local.prefix}-external-lb-nsg"      # For OKE external LBs
  nsg_pod_display_name              = "${local.prefix}-pod-nsg"              # For OKE CNI Pods

  oci_freeform_tags = local.common_tags
}

# 1. Virtual Cloud Network (VCN)
resource "oci_core_vcn" "vcn" {
  provider       = oci
  compartment_id = var.compartment_ocid
  display_name   = local.vcn_display_name
  dns_label      = lower(replace(local.prefix, "-", ""))
  cidr_block     = var.vcn_cidr_block # Main CIDR for the VCN

  # In OCI, routing_mode is implicitly handled by Route Tables and Gateways.
  # auto_create_subnetworks has no direct equivalent; you always define subnets explicitly.

  # Lifecycle rules for preventing destroy
  #lifecycle {
  #  prevent_destroy = true
  #}

  # Add OCI specific tags
  freeform_tags = local.oci_freeform_tags
  # defined_tags = {
  #   "Operations.Project" = var.project_name
  # }
}

# 2. Internet Gateway - Allows public internet access (similar to a default route to internet in GCP)
resource "oci_core_internet_gateway" "igw" {
  provider       = oci
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.igw_display_name

  # Add tags
  freeform_tags = local.oci_freeform_tags
}

# 3. NAT Gateway - Allows private subnets to reach the internet for updates, etc., without public IPs
resource "oci_core_nat_gateway" "nat_gw" {
  provider       = oci
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.nat_gw_display_name

  # Add tags
  freeform_tags = local.oci_freeform_tags
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name" # You can also use "display_name" here as it's the same
    values = ["All IAD Services In Oracle Services Network"] # Exact match
    regex  = false # No need for regex, we have the exact value
  }
}

# 4. Service Gateway - Allows private subnets to reach OCI Public Services (e.g., Object Storage, KMS) privately
resource "oci_core_service_gateway" "sgw" {
  provider       = oci
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.sgw_display_name

  # Access to all OCI services (e.g., Object Storage, Streaming, etc.)
  services {
    # service_id = var.service_ocid
    # Alternatively, use data "oci_core_services" "all_services" { filter { ... } } to find it dynamically
    # Dynamically find the "All Services" ID
    service_id = data.oci_core_services.all_services.services[0].id # Get the ID of the first (and usually only) matching service

  }

  # Add tags
  freeform_tags = local.oci_freeform_tags
}

# Security Lists
# Security List for Public Kubernetes API Subnet
resource "oci_core_security_list" "sl_k8s_api" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.sl_k8s_api_display_name
  freeform_tags  = local.oci_freeform_tags

  # Ingress Rules
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = var.allow_ssh_from_cidr # SSH access
    tcp_options {
      min = 22
      max = 22
    }
    description = "Allow SSH from trusted CIDR"
  }
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0" # Allow K8s API 6443 from anywhere (often restricted further in prod)
    tcp_options {
      min = 6443
      max = 6443
    }
    description = "Allow Kubernetes API (6443) from anywhere"
  }
  ingress_security_rules {
    protocol  = "all" # Allow all from private subnets (for K8s control plane communication)
    source    = var.private_worker_node_subnet_cidr
    description = "Allow all traffic from Private Worker Node Subnet"
  }
  ingress_security_rules {
    protocol  = "all" # Allow all from private subnets (for K8s control plane communication)
    source    = var.private_pod_subnet_cidr
    description = "Allow all traffic from Private Pod Subnet"
  }

  # Egress Rules (Default: Allow all egress)
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Allow all egress traffic"
  }
}
# Security List for Public Load Balancer Subnet
resource "oci_core_security_list" "sl_lb" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.sl_lb_display_name
  freeform_tags  = local.oci_freeform_tags

  # Ingress Rules
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0" # Allow HTTP from anywhere
    tcp_options {
      min = 80
      max = 80
    }
    description = "Allow HTTP (80) from anywhere"
  }
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0" # Allow HTTPS from anywhere
    tcp_options {
      min = 443
      max = 443
    }
    description = "Allow HTTPS (443) from anywhere"
  }

  # Egress Rules (Default: Allow all egress)
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Allow all egress traffic"
  }
}
# Security List for Private Worker Node Subnet
# These rules allow worker nodes to function within OKE.
resource "oci_core_security_list" "sl_worker_node" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.sl_worker_node_display_name
  freeform_tags  = local.oci_freeform_tags

  # Ingress Rules (from K8s API, other worker nodes, pods)
  ingress_security_rules {
    protocol    = "all"
    source      = oci_core_subnet.public_kubernetes_api_subnet.cidr_block
    description = "Allow all traffic from K8s API Subnet"
  }
  ingress_security_rules {
    protocol    = "all"
    source      = var.private_worker_node_subnet_cidr
    description = "Allow all traffic within Worker Node Subnet"
  }
  ingress_security_rules {
    protocol    = "all"
    source      = var.private_pod_subnet_cidr
    description = "Allow all traffic from Pod Subnet"
  }
  # Allow CNI (e.g., Flannel/Calico) ports if custom CNI is used (usually handled by NSG)
  # Allow NodePort range (30000-32767) from Load Balancers/other subnets if needed
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = var.public_load_balancer_subnet_cidr
    tcp_options {
      min = 30000
      max = 32767
    }
    description = "Allow NodePort range from Load Balancer Subnet"
  }

  # Egress Rules (to K8s API, other worker nodes, pods, internet/OCI services)
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0" # To NAT GW/SGW for internet/OCI services
    description = "Allow all egress to Internet/OCI Services"
  }
  egress_security_rules {
    protocol    = "all"
    destination = oci_core_subnet.public_kubernetes_api_subnet.cidr_block
    description = "Allow all egress to K8s API Subnet"
  }
  egress_security_rules {
    protocol    = "all"
    destination = var.private_worker_node_subnet_cidr
    description = "Allow all egress within Worker Node Subnet"
  }
  egress_security_rules {
    protocol    = "all"
    destination = var.private_pod_subnet_cidr
    description = "Allow all egress to Pod Subnet"
  }
}
# Security List for Private Pod Subnet
# These rules allow pods to communicate within the cluster and with external services.
resource "oci_core_security_list" "sl_pod" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.sl_pod_display_name
  freeform_tags  = local.oci_freeform_tags

  # Ingress Rules (from K8s API, worker nodes, other pods, LBs)
  ingress_security_rules {
    protocol    = "all"
    source      = oci_core_subnet.public_kubernetes_api_subnet.cidr_block
    description = "Allow all traffic from K8s API Subnet"
  }
  ingress_security_rules {
    protocol    = "all"
    source      = var.private_worker_node_subnet_cidr
    description = "Allow all traffic from Worker Node Subnet"
  }
  ingress_security_rules {
    protocol    = "all"
    source      = var.private_pod_subnet_cidr
    description = "Allow all traffic within Pod Subnet"
  }
  ingress_security_rules {
    protocol    = "all"
    source      = var.public_load_balancer_subnet_cidr
    description = "Allow all traffic from Public Load Balancer Subnet (for services)"
  }

  # Egress Rules (to worker nodes, other pods, internet/OCI services, public LBs)
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0" # To NAT GW/SGW for internet/OCI services
    description = "Allow all egress to Internet/OCI Services"
  }
  egress_security_rules {
    protocol    = "all"
    destination = oci_core_subnet.public_kubernetes_api_subnet.cidr_block
    description = "Allow all egress to K8s API Subnet"
  }
  egress_security_rules {
    protocol    = "all"
    destination = var.private_worker_node_subnet_cidr
    description = "Allow all egress to Worker Node Subnet"
  }
  egress_security_rules {
    protocol    = "all"
    destination = var.private_pod_subnet_cidr
    description = "Allow all egress within Pod Subnet"
  }
  egress_security_rules {
    protocol    = "all"
    destination = var.public_load_balancer_subnet_cidr
    description = "Allow all egress to Public Load Balancer Subnet"
  }
}
# --- Network Security Groups (NSGs) - RECOMMENDED FOR OKE ---
# OKE heavily leverages NSGs. It's often easier to define security per resource type
# (e.g., all worker nodes, all LBs) rather than per subnet.
# You would then attach these NSGs to the OKE cluster, node pools, and load balancers.

# NSG for OKE Kubernetes API Endpoint
resource "oci_core_network_security_group" "nsg_k8s_api_endpoint" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.nsg_k8s_api_endpoint_display_name
  freeform_tags  = local.oci_freeform_tags
}

# NSG for OKE Worker Nodes
resource "oci_core_network_security_group" "nsg_worker_node" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.nsg_worker_node_display_name
  freeform_tags  = local.oci_freeform_tags
}

# NSG for OKE Internal Load Balancers
resource "oci_core_network_security_group" "nsg_internal_lb" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.nsg_internal_lb_display_name
  freeform_tags  = local.oci_freeform_tags
}
# NSG for OKE External/Public Load Balancers
resource "oci_core_network_security_group" "nsg_external_lb" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.nsg_external_lb_display_name
  freeform_tags  = local.oci_freeform_tags
}

# NSG for OKE Pods (used by CNI like Calico)
resource "oci_core_network_security_group" "nsg_pod" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = local.nsg_pod_display_name
  freeform_tags  = local.oci_freeform_tags
}

# NSG Rules (Example - you would add more comprehensive rules here)
# Example: Allow K8s API access to worker nodes via NSGs
resource "oci_core_network_security_group_security_rule" "nsg_worker_ingress_api" {
  network_security_group_id = oci_core_network_security_group.nsg_worker_node.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  source                    = oci_core_network_security_group.nsg_k8s_api_endpoint.id # Traffic from K8s API NSG
  source_type               = "NETWORK_SECURITY_GROUP"

  destination               = oci_core_network_security_group.nsg_k8s_api_endpoint.id # Traffic from K8s API NSG
  destination_type          = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 10250 # Kubelet port
      max = 10250
    }
  }
}

# 5. Public Subnet - for public resources
# Public Kubernetes API Subnet
resource "oci_core_subnet" "public_kubernetes_api_subnet" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  cidr_block     = var.public_kubernetes_api_subnet_cidr
  display_name   = local.public_kubernetes_api_subnet_display_name
  dns_label      = "k8sapi"
  route_table_id = oci_core_route_table.public_rt.id
  # Assign security lists below
  security_list_ids = [
    oci_core_security_list.sl_k8s_api.id,
    # Add other common SLs if necessary, like a default SL
  ]
  prohibit_public_ip_on_vnic = false # Public subnet
  freeform_tags              = local.oci_freeform_tags
  #defined_tags               = var.defined_tags
}
# Public Load Balancer Subnet
resource "oci_core_subnet" "public_load_balancer_subnet" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  cidr_block     = var.public_load_balancer_subnet_cidr
  display_name   = local.public_load_balancer_subnet_display_name
  dns_label      = "lb"
  route_table_id = oci_core_route_table.public_rt.id
  # Assign security lists below
  security_list_ids = [
    oci_core_security_list.sl_lb.id,
    # Add other common SLs if necessary
  ]
  prohibit_public_ip_on_vnic = false # Public subnet
  freeform_tags              = local.oci_freeform_tags
  #defined_tags               = var.defined_tags
}

# 6. Private Subnet - For resources that should not have direct public internet access
# Private Worker Node Subnet
resource "oci_core_subnet" "private_worker_node_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  cidr_block                 = var.private_worker_node_subnet_cidr
  display_name               = local.private_worker_node_subnet_display_name
  dns_label                  = "worker"
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_security_list.sl_worker_node.id] # Assign security lists
  prohibit_public_ip_on_vnic = true # Private subnet
  freeform_tags              = var.freeform_tags
}
# Private Pod Subnet
resource "oci_core_subnet" "private_pod_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  cidr_block                 = var.private_pod_subnet_cidr
  display_name               = local.private_pod_subnet_display_name
  dns_label                  = "pod"
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_security_list.sl_pod.id] # Assign security lists
  prohibit_public_ip_on_vnic = true # Private subnet
  freeform_tags              = var.freeform_tags
}
resource "oci_core_subnet" "private_subnet" {
  provider       = oci
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${local.environment_name}-private-subnet"
  cidr_block     = var.private_subnet_cidr

  # Route traffic for private subnet through NAT Gateway for internet, and Service Gateway for OCI services
  route_table_id = oci_core_route_table.private_rt.id

  # Security Lists
  #security_list_ids = compact([lookup(oci_core_security_list.oke_sl, "private", {}).id])
  security_list_ids = [oci_core_security_list.sl_worker_node.id, oci_core_security_list.sl_pod.id]

  # Add tags
  freeform_tags = local.oci_freeform_tags
}

# 7. Route Tables
resource "oci_core_route_table" "public_rt" {
  provider       = oci
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${local.environment_name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }

  # Add tags
  freeform_tags = local.oci_freeform_tags
}

resource "oci_core_route_table" "private_rt" {
  provider       = oci
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${local.environment_name}-private-rt"

  # Route to NAT Gateway for internet access from private subnet
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gw.id
  }

  # Route to Service Gateway for OCI public services access from private subnet
  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block  #"all-${var.oci_region}-services-in-oracle-services-network"
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sgw.id
  }

  # Add tags
  freeform_tags = local.oci_freeform_tags
}

# Optional: VCN Flow Logs - log_config
resource "oci_logging_log" "vcn_flow_log" {
  count = var.flow_logs_enabled ? 1 : 0 # Only create if enabled

  provider         = oci
  display_name     = "${local.environment_name}-vcn-flow-log"
  log_group_id     = var.log_group_ocid
  is_enabled       = true
  log_type         = "VCNFLOW"
  configuration {
    #Required
    source {
       category = "flowlogs"
       resource = oci_core_vcn.vcn.id # Logs for the entire VCN
       service  = "flowlogs"
       source_type = "OCISERVICE"
    }
    compartment_id   = var.compartment_ocid
  }

  # Add tags
  freeform_tags = local.oci_freeform_tags
}





