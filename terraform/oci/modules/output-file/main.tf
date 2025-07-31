locals {
  global_values_cloud_file = "${var.base_location}/../global-cloud-values.yaml"
}

resource "local_sensitive_file" "global_cloud_values_yaml" {
content  = templatefile("${path.module}/global-cloud-values.yaml.tfpl", {
    env                                           = var.env,
    environment                                   = var.environment,
    building_block                                = var.building_block,

    oci_storage_bucket_public      = var.oci_storage_bucket_public,
    oci_storage_bucket_private     = var.oci_storage_bucket_private,
    oci_dial_state_bucket_public   = var.oci_dial_state_bucket_public,
    oci_object_storage_namespace   = var.oci_object_storage_namespace, # Required for OCI Object Storage
    oci_compartment_ocid           = var.oci_compartment_ocid,

    oci_public_container_name                     = var.storage_container_public,
    oci_private_container_name                    = var.storage_container_private,
    oci_dial_state_container_public               = var.dial_state_container_public,
    random_string                                 = var.random_string,
    private_ingressgateway_ip                     = var.private_ingressgateway_ip,
    oke_cluster_endpoint                          = var.oke_cluster_endpoint,
    oke_cluster_name                              = var.oke_cluster_name,
    storage_class                                 = var.storage_class,
    cloud_storage_provider                        = var.cloud_storage_provider,
    cloud_storage_region                          = var.cloud_storage_region
  })
  filename = local.global_values_cloud_file
}

resource "null_resource" "upload_global_cloud_values_yaml" {
  triggers = {
    command = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "oci os object put --force -bn ${var.oci_storage_bucket_private} --name ${var.environment}-global-cloud-values.yaml --file ${local.global_values_cloud_file} --namespace ${var.oci_object_storage_namespace}"

  }
  depends_on = [ local_sensitive_file.global_cloud_values_yaml ]
}
