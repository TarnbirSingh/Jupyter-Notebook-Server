# ============================================================================
# Public Outputs (Non-Sensitive)
# ============================================================================

output "jupyterhub_url" {
  description = "JupyterHub login URL"
  value = var.use_mock_provider ? "https://mock-jupyter.dhbw.de" : (
    length(openstack_networking_floatingip_v2.jupyter_fip) > 0 ?
    "https://${openstack_networking_floatingip_v2.jupyter_fip[0].address}" :
    "https://internal-ip-only"
  )
}

output "server_info" {
  description = "JupyterHub server information"
  value = {
    deployment_id   = var.deployment_id
    server_name     = var.use_mock_provider ? "mock-jupyter-server" : (
      length(openstack_compute_instance_v2.jupyter_server) > 0 ?
      openstack_compute_instance_v2.jupyter_server[0].name :
      "unknown"
    )
    student_count   = length(var.student_emails)
    admin_email     = var.admin_email
    cpu_cores       = var.cpu_cores
    ram_mb          = var.ram_mb
    disk_gb         = var.disk_gb
    gpu_enabled     = var.enable_gpu
    git_sync_enabled = var.enable_git_sync
  }
}

output "installed_packages" {
  description = "List of installed Python packages"
  value       = var.python_packages
}

output "jupyter_version" {
  description = "Installed JupyterHub version"
  value       = "4.0.2"  # Update based on cloud-init installation
}

output "access_instructions" {
  description = "Instructions for accessing JupyterHub"
  value = <<-EOT
    JupyterHub Access Information:
    
    1. URL: ${var.use_mock_provider ? "https://mock-jupyter.dhbw.de" : (
      length(openstack_networking_floatingip_v2.jupyter_fip) > 0 ?
      "https://${openstack_networking_floatingip_v2.jupyter_fip[0].address}" :
      "https://internal-ip-only"
    )}
    
    2. Students: Login with your email and provided password
    
    3. Admin: Login with ${var.admin_email} and admin password (see sensitive outputs)
    
    4. SSH Access: ssh ubuntu@${var.use_mock_provider ? "mock-ip" : (
      length(openstack_networking_floatingip_v2.jupyter_fip) > 0 ?
      openstack_networking_floatingip_v2.jupyter_fip[0].address :
      "internal-ip"
    )}
  EOT
}

# ============================================================================
# Sensitive Outputs (Credentials)
# ============================================================================

output "admin_credentials" {
  description = "Administrator login credentials"
  sensitive   = true
  value = {
    username = var.admin_email
    password = random_password.admin_password.result
    api_token = random_string.jupyterhub_api_token.result
  }
}

output "student_credentials" {
  description = "Student login credentials"
  sensitive   = true
  value = {
    for email in var.student_emails : email => {
      username = email
      password = random_password.student_passwords[email].result
      notebook_url = "${var.use_mock_provider ? "https://mock-jupyter.dhbw.de" : (
        length(openstack_networking_floatingip_v2.jupyter_fip) > 0 ?
        "https://${openstack_networking_floatingip_v2.jupyter_fip[0].address}" :
        "https://internal-ip"
      )}/user/${email}/"
    }
  }
}

output "ssh_private_key" {
  description = "SSH private key for server access"
  sensitive   = true
  value       = tls_private_key.jupyter_ssh_key.private_key_openssh
}

# ============================================================================
# Technical Details
# ============================================================================

output "internal_ip" {
  description = "Internal IP address"
  value = var.use_mock_provider ? "192.168.100.10" : (
    length(openstack_compute_instance_v2.jupyter_server) > 0 ?
    openstack_compute_instance_v2.jupyter_server[0].access_ip_v4 :
    "unknown"
  )
}

output "floating_ip" {
  description = "Public floating IP address"
  value = var.use_mock_provider ? "203.0.113.42" : (
    length(openstack_networking_floatingip_v2.jupyter_fip) > 0 ?
    openstack_networking_floatingip_v2.jupyter_fip[0].address :
    null
  )
}