# Authentication
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

# Compartment
variable "compartment_ocid" {}

# Availability Domain
variable "availability_domain" {
  default = "DAcm:EU-FRANKFURT-1-AD-1"
}

# SSH
variable "ssh_public_key" {}

# Network
variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  default     = "10.0.0.0/16"
}
variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  default     = "10.0.0.0/24"
}

# Compute
variable "instance_shape" {
  description = "Shape for the free tier instance"
  default     = "VM.Standard.E2.1.Micro"
}
variable "instance_os" {
  description = "Operating system for the instance"
  default     = "Canonical Ubuntu"
}
variable "instance_os_version" {
  description = "Operating system version for the instance"
  default     = "24.04"
}

variable "existing_compartment_id" {
  description = "OCID of the existing compartment"
  type        = string
}