# Add/update these OCI-specific variables
variable "oci_object_storage_namespace" {
  description = "The Object Storage namespace (usually your tenancy name)."
  type        = string
}

variable "oci_compartment_ocid" {
  description = "The OCID of the compartment where the target OCI bucket resides."
  type        = string
}

variable "oci_region" {
  description = "The OCI region where the target OCI bucket resides."
  type        = string
}

# Keep your existing variables related to the *source* (Azure/Sunbird) if it remains Azure.
# If "sunbird" is now an OCI bucket, these would change.
variable "sunbird_public_artifacts_account" {
  description = "The source account/container name (e.g., Azure storage account name or OCI bucket name if Sunbird is in OCI)."
  type        = string
  default     = "dummy"
}

# Assuming your target OCI buckets are defined elsewhere (e.g., `oci_objectstorage_bucket.storage_container_public`)
variable "oci_storage_bucket_public" {
  description = "The name of the target OCI public storage container."
  type        = string
}

variable "oci_storage_bucket_private" {
  description = "The name of the target OCI private storage container."
  type        = string
}

# Variable for the domain, used in schema URL
variable "domain" {
  description = "The base domain for constructing public cloud storage URLs."
  type        = string
  default     = ""
}

variable "sunbird_public_artifacts_account_sas_url" {
    type        = string
    description = "The readonly sas token url for the sunbird public account."
    default     = "https://downloadableartifacts.blob.core.windows.net/?sv=2022-11-02&ss=bf&srt=co&sp=rlitfx&se=2026-08-30T20:37:29Z&st=2024-07-10T12:37:29Z&spr=https&sig=hcXksbrbR%2BJgCB0EKxiwHCSsQ6r2eSlyOVnqnjxFOH0%3D"
}

variable "sunbird_public_artifacts_container" {
    type        = string
    description = "The container name dedicated for this release which holds the storage artifatcs."
    default     = "release700"
}


