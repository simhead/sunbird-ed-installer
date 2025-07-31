# Add/update these OCI-specific variables
variable "oci_compartment_ocid" {
  description = "The OCID of the OCI compartment for resources."
  type        = string
}

variable "oci_storage_bucket_public" {
  description = "The name of the OCI Object Storage public bucket."
  type        = string
}

variable "oci_storage_bucket_private" {
  description = "The name of the OCI Object Storage private bucket."
  type        = string
}

# Keep these if they are still relevant for your global config
variable "env" {
  description = "Short environment abbreviation (e.g., dev, prd)."
  type        = string
}

variable "environment" {
  description = "Full environment name (e.g., development, production)."
  type        = string
}

variable "building_block" {
  description = "The building block name (e.g., app, db)."
  type        = string
}

variable "storage_class" {
  description = "The desired storage class for Kubernetes (e.g., oci-bv)."
  type        = string
}

variable "cloud_storage_provider" {
  description = "The cloud storage provider (should be OCI now)."
  type        = string
  default     = "OCI" # Update default
}

variable "cloud_storage_region" {
  description = "The cloud storage region."
  type        = string
}

variable "oke_cluster_endpoint" {
  description = "The OKE cluster endpoint (public or private)."
  type        = string
}
variable "oke_cluster_name" {
  description = "The OKE cluster name."
  type        = string
}

# Variables for the template to get OCI-specific details
variable "oci_object_storage_namespace" {
  description = "The OCI Object Storage namespace (usually your tenancy name)."
  type        = string
}

variable "storage_container_public" {
    type        = string
    description = "Public storage container name with blob access."
}

variable "storage_container_private" {
    type        = string
    description = "Private storage container name."
}

variable "oci_dial_state_bucket_public" {
    type        = string
    description = "Dial state bucket."
}

variable "base_location" {
    type        = string
    description = "Location of terrafrom execution folder."
}

variable "random_string" {
    type        = string
    description = "This string will be used to encrypt / mask various values. Use a strong random string in order to secure the applications. The string should be between 12 and 24 characters in length. If you forget the string, the application will stop working and the string cannot be retrieved."
    validation {
      condition     = length(var.random_string) >= 12 || length(var.random_string) <= 24
      error_message = "The string must have a length ranging from 12 to 24 characters."
  }
}

variable "private_ingressgateway_ip" {
    type        = string
    description = "Private LB IP."
}

variable "dial_state_container_public" {
    type        = string
    description = "Public storage container name with blob access."
}

