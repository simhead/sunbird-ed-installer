# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These parameters must be supplied when consuming this module.
# ---------------------------------------------------------------------------------------------------------------------
variable "environment" {
    type        = string
    description = "environment name. All resources will be prefixed with this value."
}

variable "building_block" {
    type        = string
    description = "Building block name. All resources will be prefixed with this value."
}
variable "project" {
  description = "The name of the GCP Project where all resources will be launched."
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment where resources are created."
  type        = string
}

variable "tenancy_ocid" {
  description = "The OCID of the tenancy where resources are created."
  type        = string
}

variable "oci_dynamic_group" {
  description = "dynamic group."
  type        = string
}

variable "oci_dynamic_group_ocid" {
  description = "dynamic group."
  type        = string
}

variable "oci_object_storage_namespace" {
  description = "The name of your OCI tenancy (Object Storage Namespace)."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_service_account_description" {
  description = "Description for the OCI Dynamic Group for OKE nodes."
  type        = string
  default     = "Dynamic Group for OKE worker nodes"
}

variable "service_account_roles" {
  description = "List of OCI IAM policy statements for the OKE nodes."
  type        = list(string)
  default     = null
}

variable "enable_oke_workload_identity" {
  description = "Set to true to configure OKE Workload Identity. Requires K8s service account details."
  type        = bool
  default     = false
}

variable "k8s_service_account_name" {
  description = "Kubernetes Service Account name for Workload Identity."
  type        = string
  default     = "default" # Or your specific K8s SA
}

variable "k8s_service_account_namespace" {
  description = "Kubernetes Service Account namespace for Workload Identity."
  type        = string
  default     = "default" # Or your specific K8s namespace
}

# Variable for storing keys, if you must (not recommended for SA keys)
variable "sa_key_store_bucket" {
  description = "OCI Object Storage bucket name to store sensitive files (e.g., generated keys)."
  type        = string
  default     = null # Make it optional
}
