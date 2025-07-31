# Add these OCI-specific variables if they don't exist
variable "compartment_ocid" {
  description = "The OCID of the compartment where Object Storage buckets will be created."
  type        = string
}

variable "oci_object_storage_namespace" {
  description = "The Object Storage namespace (usually your tenancy name)."
  type        = string
  # You can fetch this dynamically using a data source if preferred:
  # data "oci_identity_tenancy" "current" {}
  # value = data.oci_identity_tenancy.current.name
}

variable "oci_region" {
  description = "The OCI region where buckets will be created."
  type        = string
}

# Keep existing variables like environment, building_block, domain
variable "environment" {
  description = "The environment name (e.g., dev, prod)."
  type        = string
}

variable "building_block" {
  description = "The building block name (e.g., app, db)."
  type        = string
}

variable "domain" {
  description = "The domain name for CORS settings."
  type        = string
}

variable "project" {
  description = "The project ID where the bucket needs to be created"
  type        = string
}

variable "env" {
  type        = string
  description = "Environment name. All resources will be prefixed with this value."
}

variable "region" {
  description = "The region for cloud storage bucket"
  type        = string
}

