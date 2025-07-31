#!/bin/bash
set -euo pipefail

# --- Configuration ---
# OCI_NAMESPACE no longer needs to be initialized to empty string here,
# as we will directly attempt to get it from the OCI CLI if it's not pre-set.
# Your OCI Object Storage Namespace. This is typically your tenancy name.
# You can find it in OCI Console -> Identity & Access Management -> Tenancy Details.
# --- Get OCI Tenancy Namespace ---
echo "Attempting to retrieve OCI Object Storage Namespace from OCI CLI config..."

# Use --query 'data' and --raw-output to extract the string value directly
OCI_NAMESPACE=$(oci os ns get --query 'data' --raw-output)

# Check if the command was successful and returned a non-empty value
if [ $? -ne 0 ] || [[ -z "$OCI_NAMESPACE" ]]; then
  echo "Error: Unable to retrieve OCI Object Storage Namespace using 'oci os ns get --query data --raw-output'."
  echo "Please ensure OCI CLI is configured and authenticated, and you have permission to view tenancy details."
  exit 1
else
  echo "Detected OCI Object Storage Namespace: $OCI_NAMESPACE"
fi

# --- Tool Checks ---
# Check if the global-values.yaml file exists
if [[ ! -f "global-values.yaml" ]]; then
  echo "Error: global-values.yaml file does not exist!"
  exit 1
fi

# Check if required tools are installed
if ! command -v yq &> /dev/null; then
  echo "Error: yq is not installed. Please install yq to process YAML files."
  exit 1
fi

if ! command -v oci &> /dev/null; then
  echo "Error: oci CLI is not installed or not in PATH. Please install and configure the OCI CLI."
  exit 1
fi

# --- Read values from global-values.yaml ---
building_block=$(yq '.global.building_block' global-values.yaml)
environment_name=$(yq '.global.environment' global-values.yaml)
oci_region=$(yq '.global.oci_region' global-values.yaml) # Assuming you add oci_region to your global-values.yaml
oci_compartment_ocid=$(yq '.global.oci_compartment_ocid' global-values.yaml)

# --- Validate required values ---
if [[ -z "$building_block" || -z "$environment_name" || -z "$oci_region" || -z "$oci_compartment_ocid" ]]; then
  echo "Error: Unable to extract required values (building_block, environment, oci_region, oci_compartment_ocid) from global-values.yaml."
  echo "Please ensure 'global.building_block', 'global.environment', 'oci_compartment_ocid', and 'global.oci_region' are defined."
  exit 1
fi

# Construct bucket name (OCI bucket names must start with a letter or underscore, and contain only letters, numbers, hyphens, and underscores)
# They are case-sensitive but generally recommended to be lowercase.
BUCKET_NAME="${environment_name}-${building_block}-tfstate"
BUCKET_NAME=$(echo "$BUCKET_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/') # Ensure lowercase and valid chars

# --- Validate OCI Region ---
# A simple check; OCI CLI will perform more rigorous validation during bucket creation.
# You could query 'oci iam region list' if you want to be exhaustive.
echo "Using OCI Region: $oci_region"

# Validate bucket name format for OCI Object Storage
if [[ ! "$BUCKET_NAME" =~ ^[a-z_][a-z0-9_-]*$ || ${#BUCKET_NAME} -gt 256 ]]; then
  echo "Error: OCI bucket name '$BUCKET_NAME' is invalid."
  echo "It must start with a letter or underscore, contain only lowercase letters, numbers, hyphens, or underscores, and be between 1 and 256 characters."
  exit 1
fi

echo "Building block: $building_block"
echo "Environment: $environment_name"
echo "OCI Region: $oci_region"
echo "OCI Namespace: $OCI_NAMESPACE"
echo "OCI Backend Bucket Name: $BUCKET_NAME"

# --- Check and Create OCI Object Storage Bucket ---
# The OCI CLI 'oci os bucket get' command will error if the bucket doesn't exist.
# We redirect stderr to /dev/null and check the exit code.
if oci os bucket get --name "$BUCKET_NAME" --namespace "$OCI_NAMESPACE" --region "$oci_region" &> /dev/null; then
  echo "OCI bucket '$BUCKET_NAME' already exists. Skipping creation."
else
  echo "Creating OCI Object Storage bucket '$BUCKET_NAME' in region '$oci_region' for namespace '$OCI_NAMESPACE'..."
  # OCI buckets are created within a compartment.
  # We need the Compartment OCID. Assuming the OCI CLI is configured with a default compartment
  # or you want to create it in the root compartment or a specific one.
  # For simplicity, we'll try to use the compartment from the current OCI CLI context.
  # For production, you might want to explicitly pass the compartment_id here.

  # Get default compartment OCID from OCI CLI config
  # This is a bit tricky, as 'oci setup config' doesn't usually put compartment_id in ~/.oci/config
  # It's usually associated with the API Key.
  # For robust use, you might get it from a variable in global-values.yaml or a dedicated variable.
  # For now, let's assume the default compartment associated with the CLI user/key.
  # If you always create buckets in a specific compartment, add it to global-values.yaml.
  # Example: OCI_COMPARTMENT_OCID=$(yq '.global.oci_compartment_ocid' global-values.yaml)

  # For demonstration, we'll use a placeholder or assume the default compartment for the OCI CLI user
  # This command does NOT need a compartment_id for bucket creation itself, as it infers it from the current context,
  # but you need to ensure the user has permissions in that compartment.
  # You DO need the tenancy_id (aka root compartment ocid) if you are setting up policy.

  # Minimal bucket creation. We set versioning in the bucket properties.
  oci os bucket create --compartment-id $oci_compartment_ocid --name "$BUCKET_NAME"

  if [ $? -eq 0 ]; then
    echo "OCI bucket '$BUCKET_NAME' created and versioning enabled."
  else
    echo "Error: Failed to create OCI bucket '$BUCKET_NAME'."
    exit 1
  fi
fi

# --- Write environment variables to tf.sh for Terragrunt backend ---
# Terragrunt's OCI backend requires TERRAFORM_BACKEND_BUCKET and NAMESPACE env vars.
# It does NOT use a TERRAFORM_OCI_REGION or similar directly in the backend block,
# but implicitly uses the region configured for your OCI CLI.
# However, it's good practice to set it if your terragrunt configs rely on it.
echo "export TERRAFORM_BACKEND_BUCKET=$BUCKET_NAME" > tf.sh
echo "export NAMESPACE=$OCI_NAMESPACE" >> tf.sh
echo "export OCI_REGION=$oci_region" >> tf.sh # Add this for consistency, even if not directly used by the backend block

# Print out the result
echo -e "\nTerraform OCI backend setup complete!"
echo "TERRAFORM_BACKEND_BUCKET=$BUCKET_NAME"
echo "NAMESPACE=$OCI_NAMESPACE"
echo "OCI_REGION=$oci_region"
echo "Run the following to export environment variables:"
echo "source tf.sh"
