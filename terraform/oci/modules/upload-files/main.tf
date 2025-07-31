# main.tf (or relevant .tf files)

locals {
  # This path remains the same
  template_files = fileset("${path.module}/sunbird-rc/schemas", "*.json")

  upload_directory = "${path.module}/files_to_upload"
}

resource "local_sensitive_file" "rclone_config" {
  content  = templatefile("${path.module}/config.tfpl", {
    # OCI-specific variables for the 'ownaccount' rclone remote
    oci_region = var.oci_region
    namespace = var.oci_object_storage_namespace
  })
  filename = pathexpand("~/.config/rclone/rclone.conf")
  # Ensure the directory exists:
  directory_permission = "0700"
  file_permission      = "0600"
}

#resource "null_resource" "copy_from_sunbird_container" {
#  triggers = {
#    command = "${timestamp()}"
#    # Add a trigger for the rclone config file itself if it might change
#    rclone_config_hash = filemd5(local_sensitive_file.rclone_config.filename)
#  }
#  provisioner "local-exec" {
#    # rclone command for OCI Object Storage.
#    # Format: remote_name:namespace@bucket_name
#    # Assuming 'sunbird' is the Azure remote, and 'ownaccount' is the OCI remote.
#    # If 'sunbird' is also OCI, adjust source path.
#    command = "rclone copy sunbird:${var.sunbird_public_artifacts_container} ownaccount:${var.oci_object_storage_namespace}@${var.oci_storage_bucket_public} --transfers 600 --checkers 600 --exclude .terragrunt-source-manifest"
#  }
#  depends_on = [
#    local_sensitive_file.rclone_config #,
#    # Ensure the target OCI bucket is created before copying
#    #oci_objectstorage_bucket.oci_storage_bucket_public # Assuming you have this resource
#  ]
#}

resource "local_file" "output_files" {
  for_each = toset(local.template_files)
  content  = templatefile("${path.module}/sunbird-rc/schemas/${each.value}", {
    # Construct OCI Object Storage URL.
    # Format: https://objectstorage.<region>.oraclecloud.com/n/<namespace>/b/<bucket_name>/o/<object_path>
    cloud_storage_schema_url = "https://objectstorage.${var.oci_region}.oraclecloud.com/n/${var.oci_object_storage_namespace}/b/${var.oci_storage_bucket_public}/o/schemas/${each.value}"
  })
  filename = "${path.module}/sunbird-rc/schemas/${each.value}"
  # Ensure the directory exists:
  directory_permission = "0755"
  file_permission      = "0644"
}

resource "null_resource" "upload_rc_schemas_to_public_bucket" {
  triggers = {
    command = "${timestamp()}"
    # Trigger if any of the schema files change content
    # schemas_hash = sha256(join("", [for f in local_file.output_files : filemd5(f.filename)]))
    schemas_hash = sha256(jsonencode([for f in local_file.output_files : f.id]))
  }

  provisioner "local-exec" {
    # rclone command for OCI Object Storage
    # Format: remote_name:namespace@bucket_name
    command = "rclone copy ${path.module}/sunbird-rc/schemas ownaccount:${var.oci_storage_bucket_public}/schemas --transfers 25 --checkers 25 --exclude .terragrunt-source-manifest"
  }
  depends_on = [
    local_sensitive_file.rclone_config,
    local_file.output_files #, # Depends on local files being generated
    #oci_objectstorage_bucket.oci_storage_bucket_public # Ensure target OCI bucket exists
  ]
}

resource "null_resource" "bulk_upload_files" {
  triggers = {
    command = "${timestamp()}"
  }
  
  provisioner "local-exec" {
    # Use a heredoc for multi-line shell commands for readability
    command = <<-EOT
      # Check if the source directory exists. If not, print a message and skip.
      if [ ! -d "${local.upload_directory}" ]; then
        echo "INFO: Source directory '${local.upload_directory}' does not exist. Skipping bulk upload."
        exit 0 # Exit successfully, as there's nothing to upload
      fi

      echo "INFO: Performing bulk upload from '${local.upload_directory}' to bucket '${var.oci_storage_bucket_public}'..."
      # The 'oci os object bulk-upload' command uploads all files from src-dir.
      # --overwrite will replace existing objects with the same name in the bucket.
      oci os object bulk-upload \
        --bucket-name "${var.oci_storage_bucket_public}" \
        --src-dir "${local.upload_directory}" \
        --namespace "${var.oci_object_storage_namespace}" \
        --overwrite
      echo "INFO: Bulk upload completed for bucket '${var.oci_storage_bucket_public}'."
    EOT
    interpreter = ["bash", "-c"] # Explicitly use bash for the multi-line command
  }

  #depends_on = [ local_sensitive_file.global_cloud_values_yaml ]
}
