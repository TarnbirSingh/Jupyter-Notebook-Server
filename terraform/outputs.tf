# ============================================================================
# SYSTEM OUTPUTS (MANDATORY)
# ============================================================================

output "instance_id" {
  description = "VM ID for backend management"
  value = var.use_mock_provider ? "mock-id-123" : (
    length(openstack_compute_instance_v2.jupyter_server) > 0 ?
    openstack_compute_instance_v2.jupyter_server[0].id :
    "unknown"
  )
}

output "app_name" {
  description = "Application Name"
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

output "ssh_command" {
  description = "SSH command for VM access"
  value       = "ssh -i <private_key> ubuntu@${var.use_mock_provider ? "mock-ip" : try(openstack_networking_floatingip_v2.jupyter_fip[0].address, "ip")}"
}

output "jupyter_version" {
  description = "Installed JupyterHub version"
  value       = "4.0.2"
}

# ============================================================================
# SENSITIVE OUTPUTS
# ============================================================================

output "admin_credentials" {
  description = "Administrator login credentials"
  sensitive   = true
  value = {
    username     = local.email_to_username[var.admin_username]
    email        = var.admin_username
    password     = random_password.admin_password.result
    api_token    = random_string.jupyterhub_api_token.result
    notebook_url = "${var.use_mock_provider ? "https://mock" : "https://${try(openstack_networking_floatingip_v2.jupyter_fip[0].address, "ip")}"}/user/${local.email_to_username[var.admin_username]}/"
  }
}

output "student_credentials" {
  description = "Student login credentials"
  sensitive   = true
  value = {
    for email in local.resolved_students : email => {
      username     = local.email_to_username[email]
      email        = email
      password     = random_password.student_passwords[email].result
      notebook_url = "${var.use_mock_provider ? "https://mock" : "https://${try(openstack_networking_floatingip_v2.jupyter_fip[0].address, "ip")}"}/user/${local.email_to_username[email]}/"
    }
  }
}

output "ssh_private_key" {
  description = "SSH private key for server access"
  sensitive   = true
  value       = tls_private_key.jupyter_ssh_key.private_key_openssh
}
