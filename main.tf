
provider "aws" {
  region  = "ap-south-1"
  profile = <IAMName>
}

terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}


provider "openstack" {
  user_name   = <Username>
  tenant_name = <TenantName>
  password    = <YourPassword>
  auth_url    = "http://192.168.0.181:5000/v3"
  region      = "RegionOne"
}

module "myaws" {
  count  = terraform.workspace == "production" ? 1 : 0
  source = "./myaws"
}

module "nova" {
  count  = terraform.workspace == "testing" ? 1 : 0
  source = "./nova"

}

