# main.tf (or where your storage resources are defined)

resource "random_id" "bucket_id" {
  byte_length = 5 # Cloud-agnostic, remains
}

locals {
  unique_uuid = random_id.bucket_id.hex

  # OCI uses freeform_tags (simple key-value) and defined_tags (namespaced)
  oci_freeform_tags = {
    environment   = var.environment
    BuildingBlock = var.building_block
    unique_uuid   = local.unique_uuid
  }

  environment_name = "${var.building_block}-${var.environment}"
}

# --- Public Storage Container ---
resource "oci_objectstorage_bucket" "storage_container_public" {
  provider = oci

  # OCI-specific attributes
  namespace       = var.oci_object_storage_namespace
  compartment_id  = var.compartment_ocid
  name            = "${local.environment_name}-public-${local.unique_uuid}"
  # OCI buckets are regional, specified by the provider's region.
  # The 'location' argument is not directly used here.

  # Versioning
  versioning = "Enabled" # OCI: "Enabled", "Suspended"

  # Access type: "NoPublicAccess", "ObjectRead", "ObjectReadWithoutList"
  # Equivalent to public_access_prevention = "unspecified" and then granting public access via IAM.
  # For full "allUsers" access, you'd set this to "ObjectRead" or "ObjectReadWithoutList"
  # AND add a bucket policy (see below).
  access_type = "ObjectRead" # Allows unauthenticated (public) reads of objects

  # OCI freeform and defined tags
  freeform_tags = local.oci_freeform_tags
  # defined_tags = {} # If you use defined tags
}

# If you needed the equivalent of `roles/storage.admin` for `allUsers` (VERY DANGEROUS):
/*
resource "oci_objectstorage_bucket_bucket_policy" "storage_container_public_policy" {
  bucket_name = oci_objectstorage_bucket.storage_container_public.name
  namespace   = var.oci_object_storage_namespace

  # WARNING: This policy grants anonymous users (allUsers) full management of objects.
  # Only use if you understand the security implications.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicObjectManage",
        "Effect" : "Allow",
        "Principal" : "*", # Anonymous principal
        "Action" : [
          "oci-objectstorage-object-read",
          "oci-objectstorage-object-write",
          "oci-objectstorage-object-delete",
          "oci-objectstorage-object-manage",
          "oci-objectstorage-bucket-read", # Allow listing objects
          "oci-objectstorage-bucket-list"
        ],
        "Resource" : [
          "arn:oci:objectstorage:::${var.oci_object_storage_namespace}/${oci_objectstorage_bucket.storage_container_public.name}",
          "arn:oci:objectstorage:::${var.oci_object_storage_namespace}/${oci_objectstorage_bucket.storage_container_public.name}/*"
        ]
      }
    ]
  })
  # IMPORTANT: Public access via bucket policy should be very carefully controlled.
  # If you only need read, use `oci_objectstorage_bucket_public_access_management` with ObjectRead.
}
*/


# --- Private Storage Container ---
resource "oci_objectstorage_bucket" "storage_container_private" {
  provider = oci

  namespace      = var.oci_object_storage_namespace
  compartment_id = var.compartment_ocid
  name           = "${local.environment_name}-private-${local.unique_uuid}"

  versioning = "Enabled"

  # Uniform bucket-level access in GCP means ACLs are disabled, IAM only.
  # In OCI, this means setting access_type to "NoPublicAccess"
  # and relying purely on IAM policies applied to users/groups/dynamic groups.
  access_type = "NoPublicAccess" # Default and recommended for private buckets

  freeform_tags = local.oci_freeform_tags
}

# --- Dial State Container (assuming this also needs to be public for a service) ---
resource "oci_objectstorage_bucket" "dial_state_container_public" {
  provider = oci

  namespace      = var.oci_object_storage_namespace
  compartment_id = var.compartment_ocid
  name           = "${local.environment_name}-dial-${local.unique_uuid}"

  versioning = "Enabled"

  access_type = "ObjectRead" # Allows unauthenticated (public) reads of objects

  freeform_tags = local.oci_freeform_tags
}

/*
resource "null_resource" "upload_file_to_public_bucket" {
  # Example if you needed to upload a specific file to a public bucket
  # For the purpose of the original script, this was for a SA key, which we are not generating directly.
  # If you had other "objects" to upload to these buckets, this pattern applies.
  triggers = {
    command = "${timestamp()}"
    source_file_hash = filemd5("path/to/your/local/file.txt")
  }
  provisioner "local-exec" {
    command = "oci os object put -bn ${oci_objectstorage_bucket.storage_container_public.name} --name my-object.txt --file path/to/your/local/file.txt --namespace ${var.oci_object_storage_namespace}"
  }
}
*/
