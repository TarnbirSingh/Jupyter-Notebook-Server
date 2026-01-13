terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  # Backend auskommentiert für lokales Testing
  # Für Production über CloudStore API wird das Backend dynamisch konfiguriert
  # backend "pg" {
  #   schema_name = "terraform_remote_state"
  # }
}

# ============================================================================
# Provider Configuration (Mock vs Production)
# ============================================================================

provider "openstack" {
  auth_url    = var.use_mock_provider ? "http://mock-openstack:5000/v3" : null
  user_name   = var.use_mock_provider ? "mock_user" : null
  tenant_name = var.use_mock_provider ? "mock_tenant" : null
  password    = var.use_mock_provider ? "mock_password" : null
  region      = var.use_mock_provider ? "mock_region" : null
  use_octavia = var.use_mock_provider ? false : true
}

# ============================================================================
# Data Sources (OpenStack Resources)
# ============================================================================

data "openstack_images_image_v2" "ubuntu" {
  count       = var.use_mock_provider ? 0 : 1
  name        = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "selected" {
  count = var.use_mock_provider ? 0 : 1
  vcpus = var.cpu_cores
  ram   = var.ram_mb
  disk  = var.disk_gb
}

data "openstack_networking_network_v2" "external" {
  count    = var.use_mock_provider ? 0 : 1
  name     = var.external_network_name
  external = true
}

# ============================================================================
# Random Password Generation for JupyterHub Users
# ============================================================================

resource "random_password" "student_passwords" {
  for_each = toset(var.student_emails)
  
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "random_password" "admin_password" {
  length  = 24
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "random_string" "jupyterhub_api_token" {
  length  = 64
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# ============================================================================
# SSH Key Generation
# ============================================================================

resource "tls_private_key" "jupyter_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "openstack_compute_keypair_v2" "jupyter_keypair" {
  count      = var.use_mock_provider ? 0 : 1
  name       = "jupyter-keypair-${var.deployment_id}"
  public_key = tls_private_key.jupyter_ssh_key.public_key_openssh
}

# ============================================================================
# Security Group Configuration
# ============================================================================

resource "openstack_networking_secgroup_v2" "jupyter_access" {
  count       = var.use_mock_provider ? 0 : 1
  name        = "jupyter-access-${var.deployment_id}"
  description = "Security group for Jupyter Notebook Server"
}

# HTTPS (JupyterHub)
resource "openstack_networking_secgroup_rule_v2" "https_ingress" {
  count             = var.use_mock_provider ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.jupyter_access[0].id
}

# HTTP (redirect to HTTPS)
resource "openstack_networking_secgroup_rule_v2" "http_ingress" {
  count             = var.use_mock_provider ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.jupyter_access[0].id
}

# SSH (Admin Access)
resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  count             = var.use_mock_provider ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.jupyter_access[0].id
}

# ============================================================================
# Compute Instance (JupyterHub Server)
# ============================================================================

resource "openstack_compute_instance_v2" "jupyter_server" {
  count       = var.use_mock_provider ? 0 : 1
  name        = "jupyter-server-${var.deployment_id}"
  image_id    = data.openstack_images_image_v2.ubuntu[0].id
  flavor_id   = data.openstack_compute_flavor_v2.selected[0].id
  key_pair    = openstack_compute_keypair_v2.jupyter_keypair[0].name

  security_groups = [
    openstack_networking_secgroup_v2.jupyter_access[0].name
  ]

  network {
    name = var.network_name
  }

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    student_emails      = var.student_emails
    student_passwords   = { for email in var.student_emails : email => random_password.student_passwords[email].result }
    admin_email         = var.admin_email
    admin_password      = random_password.admin_password.result
    api_token           = random_string.jupyterhub_api_token.result
    python_packages     = var.python_packages
    notebook_directory  = var.notebook_directory
    enable_git_sync     = var.enable_git_sync
    git_repo_url        = var.git_repo_url
    enable_gpu          = var.enable_gpu
  })

  metadata = {
    deployment_id = var.deployment_id
    template      = "jupyter-notebook-server"
    admin_email   = var.admin_email
  }
}

# ============================================================================
# Floating IP (Public Access)
# ============================================================================

resource "openstack_networking_floatingip_v2" "jupyter_fip" {
  count = var.use_mock_provider ? 0 : 1
  pool  = var.floating_ip_pool
}

resource "openstack_compute_floatingip_associate_v2" "jupyter_fip_assoc" {
  count       = var.use_mock_provider ? 0 : 1
  floating_ip = openstack_networking_floatingip_v2.jupyter_fip[0].address
  instance_id = openstack_compute_instance_v2.jupyter_server[0].id
}

# ============================================================================
# Mock Resources (Testing without OpenStack)
# ============================================================================

resource "null_resource" "mock_jupyter_server" {
  count = var.use_mock_provider ? 1 : 0

  triggers = {
    deployment_id   = var.deployment_id
    student_count   = length(var.student_emails)
    admin_email     = var.admin_email
    timestamp       = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'Mock JupyterHub Server created for ${length(var.student_emails)} students'"
  }
}