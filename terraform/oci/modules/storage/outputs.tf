output "oci_public_bucket_name" {
  description = "The name of the OCI public Object Storage bucket."
  value       = oci_objectstorage_bucket.storage_container_public.name
}

output "oci_private_bucket_name" {
  description = "The name of the OCI private Object Storage bucket."
  value       = oci_objectstorage_bucket.storage_container_private.name
}

output "oci_dial_state_bucket_public_name" {
  description = "The name of the OCI public Object Storage bucket for dial state."
  value       = oci_objectstorage_bucket.dial_state_container_public.name
}

# You might also want to output the bucket OCIDs for referencing elsewhere
output "oci_public_bucket_id" {
  description = "The OCID of the OCI public Object Storage bucket."
  value       = oci_objectstorage_bucket.storage_container_public.id
}

output "oci_private_bucket_id" {
  description = "The OCID of the OCI private Object Storage bucket."
  value       = oci_objectstorage_bucket.storage_container_private.id
}

output "oci_dial_state_bucket_public_id" {
  description = "The OCID of the OCI public Object Storage bucket for dial state."
  value       = oci_objectstorage_bucket.dial_state_container_public.id
}

# And the Object Storage Namespace, as it's often needed with bucket names
output "oci_object_storage_namespace" {
  description = "The OCI Object Storage namespace (usually your tenancy name)."
  value       = var.oci_object_storage_namespace # Directly from variable, or from data source
}
