### OCI CLI Installation and Configuration

Follow this document if you are setting up Sunbird-Ed on OCI

#### Required tools and permissions
This section provides instructions for installing the Oracle Cloud Infrastructure (OCI) Command Line Interface (CLI) and configuring it for use with the Terraform project. The OCI CLI is essential for `rclone` and other `local-exec` provisioners within this Terraform configuration to interact with OCI services.

## Prerequisites

* **Python:** The OCI CLI requires Python. It's recommended to use Python 3.6 or later.
* **Operating System:** Instructions are provided for common operating systems.

## 1. Installing the OCI CLI

The recommended way to install the OCI CLI is by using the `pip` installer for Python.

### For macOS and Linux

1.  **Install Python (if not already present):**
    Ensure you have Python 3 installed. You can check your version with:
    ```bash
    python3 --version
    ```
    If not installed, use your system's package manager (e.g., `brew install python3` on macOS, `sudo apt-get install python3` on Debian/Ubuntu, `sudo yum install python3` on RHEL/CentOS).

2.  **Install the OCI CLI using pip:**
    It's highly recommended to install the CLI into a Python virtual environment to avoid conflicts with other Python packages.

    ```bash
    # Create a virtual environment
    python3 -m venv ~/oci-cli-venv

    # Activate the virtual environment
    source ~/oci-cli-venv/bin/activate

    # Install the OCI CLI
    pip install oci-cli

    # Verify the installation
    oci --version
    ```
    You will need to activate this virtual environment whenever you want to use the OCI CLI or run Terraform commands that rely on it (like `rclone` with `env_auth`).

### For Windows

1.  **Download and Run the Installer:**
    Oracle provides a standalone installer for Windows that includes Python. Download it from the official OCI CLI documentation:
    [OCI CLI Installation Guide for Windows](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#installingcli_topic_CLI_Installer_for_Windows)
    Follow the prompts in the installer.

2.  **Verify the Installation:**
    Open a new Command Prompt or PowerShell window and run:
    ```bash
    oci --version
    ```

## 2. Configuring the OCI CLI (`oci setup config`)

After installing the CLI, you need to configure it with your OCI user credentials and API signing keys.

1.  **Generate an API Signing Key Pair:**
    The OCI CLI uses API signing keys for authentication. If you don't have a key pair, you can generate one using the CLI:

    ```bash
    oci setup keys --file ~/.oci/oci_api_key
    ```
    * This command will generate two files: `~/.oci/oci_api_key.pem` (private key) and `~/.oci/oci_api_key_public.pem` (public key).
    * **Keep `~/.oci/oci_api_key.pem` secure and private.**
    * The command will also provide you with the public key's fingerprint. Copy this fingerprint, you will need it in the next step.

2.  **Upload the Public Key to OCI:**
    Log in to the OCI Console:
    * Navigate to **Identity & Security** > **Users**.
    * Click on your user name.
    * Under "API Keys", click **Add API Key**.
    * Select "Paste Public Key" and paste the content of `~/.oci/oci_api_key_public.pem`.
    * Click "Add". Verify that the fingerprint displayed in the Console matches the one from step 1.

3.  **Run the Configuration Tool:**
    Now, use the `oci setup config` command to create your configuration file (`~/.oci/config`).

    ```bash
    oci setup config
    ```
    The tool will prompt you for the following information:

    * **`User OCID`**: Your user's OCID (e.g., `ocid1.user.oc1..<unique_ID>`). You can find this in the OCI Console under **Identity & Security** > **Users**, by clicking on your user name.
    * **`Tenancy OCID`**: Your tenancy's OCID (e.g., `ocid1.tenancy.oc1..<unique_ID>`). You can find this in the OCI Console by clicking the "profile" icon (top right) and then "Tenancy: <Your_Tenancy_Name>".
    * **`Region`**: The OCI region you will primarily be working in (e.g., `us-ashburn-1`, `ap-sydney-1`). This should match the `oci_region` variable in your Terraform.
    * **`Path to API Key (usually ~/.oci/oci_api_key.pem)`**: Press Enter to accept the default, or provide the full path to your private key file.
    * **`API Key fingerprint`**: Paste the fingerprint you copied in step 1.

    After completing these steps, the `~/.oci/config` file will be created.

## 3. Verifying Your Configuration

You can verify your OCI CLI configuration by running a simple command, for example, listing your compartments:

```bash
oci iam compartment list
```

## 4. Copy the template directory
```
cd terraform/oci
cp -r template demo
cd demo
```

## 5. Copy rsa and jwt keys 
```
cp ../../../scripts/global-values-rsa-keys-v2.yaml .
cp ../../../scripts/global-values-jwt-tokens.yaml .
```

NOTE: all main's README prerequisites are needed

### Redis backup Authentication

This is managed by this new helm chart configmap:

```
helmcharts/monitoring/charts/redis-backup/templates/oci-config-cm.yaml
```

### S3 Compartibility API [link](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm)
Update the `terraform/gcp/<env>/global-values.yaml` file with the variables as per your environment:
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

NOTE: terraform script is based on https://github.com/oracle-terraform-modules/terraform-oci-oke/tree/v5.3.1

Update the `terraform/oci/<env>/global-values.yaml` file with the variables as per your environment:
```
building_block: "" # building block name
env: ""
environment: "" # use lowercase alphanumeric string between 1-9 characters
oke_cluster_location: ""
zone: ""
oke_node_pool_instance_type: ""
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
NOTE: Bucket name needs to be defined as an environment to run Terragrunt (e.g., export TERRAFORM_BACKEND_BUCKET="my-terraform-states").

```
cd terraform/oci/<env>
terragrunt init
terragrunt validate --all
terragrunt run-all plan
# Enter y in the next command
terragrunt run-all apply
```

NOTE:
```
ERROR: iptables v1.6.0: can't initialize iptables table nat': Table does not exist (do you need to insmod?)

Solution: ssh to worker node and do the followings:
      lsmod | grep iptable
      sudo modprobe iptable_nat
      sudo modprobe ip_tables
      echo "iptable_nat" | sudo tee -a /etc/modules-load.d/iptables.conf
      echo "ip_tables" | sudo tee -a /etc/modules-load.d/iptables.conf
```
```
Require these files in OCI public bucket's folder: artifacts-release-7.0.0
- spark-3.1.3-bin-hadoop2.7.tgz
- GeoLite2-City-CSV_20240105.zip
- cassandra-migration-0.0.1-SNAPSHOT-jar-with-dependencies.jar
- cassandra-migration-0.17-jar-with-dependencies.jar
- cassandra-migration-0.6.jar
```
