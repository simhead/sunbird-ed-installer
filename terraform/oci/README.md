### OCI

Follow this document if you are setting up Sunbird-Ed on GCP

#### Required tools and permissions
1. OCI Account details as below:
```
  user=ocid1.user.oc1..<unique_ID>
  fingerprint=<your_fingerprint>
  key_file=~/.oci/oci_api_key.pem
  tenancy=ocid1.tenancy.oc1..<unique_ID>
  region=<e.g. us-ashburn-1>
```
2. Provision OKE environment by either using [OCI OKE Terraform Intro](https://docs.oracle.com/en/learn/terraform-oci-oke-cluster/index.html#introduction) OR using Oracle's provided [landingzone](https://docs.oracle.com/en-us/iaas/Content/cloud-adoption-framework/oci-landing-zones-overview.htm) concept.

3. As ususal, copy the template directory
```
cd terraform/oci
cp -r template demo
cd demo
```

NOTE: all main's README prerequisites are needed

### Redis backup Authentication

This is managed by this new helm chart configmap:

```
helmcharts/monitoring/charts/redis-backup/templates/oci-config-cm.yaml
```

### S3 Compartibility API [link](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm)

```
  # OCI S3 Compartible API Details
  s3_access_key: "access key"
  s3_secret_key: "secret key"
  s3_secret_id: "secret id"
  s3_endpoint: "https://<namespace>.compat.objectstorage.<region>.oraclecloud.com"
  s3_path_style_access: "true"
  s3_region: "e.g. us-ashburn-1"
```

### OCI Infra Setup

Update the `terraform/oci/<env>/global-values.yaml` file with the variables as per your environment:

```
building_block: "" # building block name
env: ""
environment: "" # use lowercase alphanumeric string between 1-9 characters
gke_cluster_location: ""
zone: ""
gke_node_pool_instance_type: ""
domain: ""
sunbird_google_captcha_site_key: ""
google_captcha_private_key: ""
sunbird_google_oauth_clientId: ""
sunbird_google_oauth_clientSecret: ""
mail_server_from_email: ""
mail_server_password: ""
mail_server_host: smtp.sendgrid.net
mail_server_port: "587"
mail_server_username: apikey
sunbird_msg_91_auth: ""
sunbird_msg_sender: ""
youtube_apikey: ""
object_storage_endpoint: "idnlppwjcf2n.compat.objectstorage.us-ashburn-1.oraclecloud.com"
checkpoint_store_type: "s3" # oci is using aws s3-compatible API
druid_storage_provider: "s3"
cloud_storage_provider: "oci"
cloud_service_provider: "oracle"
sunbird_cloud_storage_provider: "aws" # oci is using aws s3-compatible API
cloud_storage_region: "us-ashburn-1"
proxy_private_key: |
 <private_key_generated_when_setting_up_ssl>
proxy_certificate: |
 <certificate_generated_when_setting_up_ssl>
```

Then run the following install commands:

```
cd terraform/oci/<env>
./install.sh install_helm_components
./install.sh restart_workloads_using_keys
./install.sh certificate_config
./install.sh dns_mapping
./install.sh generate_postman_env
./install.sh run_post_install
./install.sh create_client_forms
```

