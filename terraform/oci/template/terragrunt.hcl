generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "oci" {
    bucket    = "${get_env("TERRAFORM_BACKEND_BUCKET")}"
    key       = "${path_relative_to_include()}/terraform.tfstate"
    namespace = "${get_env("NAMESPACE")}"
  }
}
EOF
}
