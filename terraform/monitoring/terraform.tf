/*
Store infrastructure state in a remote store (instead of local machine):
https://www.terraform.io/docs/state/purpose.html
*/
terraform {

  backend "s3" {
    bucket  = "530003481352-terraform-state"
    key     = "production/monitoring.tfstate" # Currently we only monitor production, but the naming convention should support monitoring other environments
    region  = "eu-west-2"
    encrypt = "true"
  }
}
