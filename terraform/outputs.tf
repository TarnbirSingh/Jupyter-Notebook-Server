# ============================================================================
# SYSTEM OUTPUTS (MANDATORY)
# ============================================================================

output "instance_id" {
  description = "MANDATORY: VM ID for Backend Management"
  value       = var.use_mock_provider ? "mock-id-123" : (
    length(openstack_compute_instance_v2.jupyter_server) > 0 ?
    openstack_compute_instance_v2.jupyter_server[0].id :
    "unknown"
  )
}

output "app_name" {
  description = "MANDATORY: Application Name"
  value       = var.app_name
}
# ============================================================================
# PUBLIC OUTPUTS
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
  description = "Server Configuration Info"
  value = {
    deployment_id = var.deployment_id
    cpu_cores     = var.cpu_cores
    ram_mb        = var.ram_mb
  }
}

output "installed_packages" {
  description = "List of installed Python packages"
  value       = var.python_packages
}

output "jupyter_version" {
  description = "Installed JupyterHub version"
  value       = "4.0.2"
}

# ============================================================================
# SENSITIVE OUTPUTS (CREDENTIALS)
# ============================================================================

output "admin_credentials" {
  description = "Administrator login credentials"
  sensitive   = true
  value = {
    username  = var.admin_email
    password  = random_password.admin_password.result
    api_token = random_string.jupyterhub_api_token.result
  }
}

output "student_credentials" {
  description = "Student login credentials"
  sensitive   = true
  value = {
    for email in var.student_emails : email => {
      username     = email
      password     = random_password.student_passwords[email].result
      notebook_url = "${var.use_mock_provider ? "https://mock" : "https://${try(openstack_networking_floatingip_v2.jupyter_fip[0].address, "ip")}"}/user/${email}/"
    }
  }
}

output "ssh_private_key" {
  description = "SSH private key for server access"
  sensitive   = true
  value       = tls_private_key.jupyter_ssh_key.private_key_openssh
}

