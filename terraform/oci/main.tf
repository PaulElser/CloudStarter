# Configure the OCI provider with authentication details
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# new compartment within the tenancy
#resource "oci_identity_compartment" "free_tier_compartment" {
#  compartment_id = var.tenancy_ocid
#  description    = "Oracle Cloud Free Tier compartment"
#  name           = "free-tier-vm"
#  enable_delete  = true

#  freeform_tags = {
#    "purpose" = "free-tier-resources"
#  }
#}

data "oci_identity_compartment" "free_tier_compartment" {
  id = var.existing_compartment_id  # You'll need to add this variable
}


# Virtual Cloud Network (VCN)
resource "oci_core_vcn" "free_tier_vcn" {
  compartment_id = data.oci_identity_compartment.free_tier_compartment.id
  cidr_block     = var.vcn_cidr
  display_name   = "free-tier-vcn"

  freeform_tags = {
    "purpose" = "free-tier-network"
  }
}

# subnet within the VCN
resource "oci_core_subnet" "free_tier_subnet" {
  compartment_id = data.oci_identity_compartment.free_tier_compartment.id
  vcn_id         = oci_core_vcn.free_tier_vcn.id
  cidr_block     = var.subnet_cidr
  display_name   = "free-tier-subnet"

  freeform_tags = {
    "purpose" = "free-tier-network"
  }
}

# Internet Gateway for the VCN
resource "oci_core_internet_gateway" "free_tier_internet_gateway" {
  compartment_id = data.oci_identity_compartment.free_tier_compartment.id
  display_name   = "free-tier-internet-gateway"
  vcn_id         = oci_core_vcn.free_tier_vcn.id

  freeform_tags = {
    "purpose" = "free-tier-network"
  }
}

# Route Table for the VCN
resource "oci_core_default_route_table" "free_tier_route_table" {
  manage_default_resource_id = oci_core_vcn.free_tier_vcn.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.free_tier_internet_gateway.id
  }

  freeform_tags = {
    "purpose" = "free-tier-network"
  }
}

# Security List for the VCN
resource "oci_core_default_security_list" "free_tier_security_list" {
  manage_default_resource_id = oci_core_vcn.free_tier_vcn.default_security_list_id

  # Allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # Allow inbound SSH traffic
  ingress_security_rules {
    protocol = "6"  # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  freeform_tags = {
    "purpose" = "free-tier-network"
  }
}

# Compute Instance
resource "oci_core_instance" "free_tier_instance" {
  compartment_id      = data.oci_identity_compartment.free_tier_compartment.id
  availability_domain = var.availability_domain
  shape               = var.instance_shape
  display_name        = "free-tier-instance"

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.free_tier_subnet.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  freeform_tags = {
    "purpose" = "free-tier-compute"
  }
}

# Data source to get the latest Ubuntu image
data "oci_core_images" "ubuntu" {
  compartment_id           = data.oci_identity_compartment.free_tier_compartment.id
  operating_system         = var.instance_os
  operating_system_version = var.instance_os_version
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

