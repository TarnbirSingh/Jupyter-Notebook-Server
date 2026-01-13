# ============================================================================
# Core Variables
# ============================================================================

variable "deployment_id" {
  description = "Unique deployment identifier"
  type        = string
}

variable "use_mock_provider" {
  description = "Use mock provider for testing (no real OpenStack resources)"
  type        = bool
  default     = false
}

# ============================================================================
# User Management
# ============================================================================

variable "student_emails" {
  description = "List of student email addresses for JupyterHub accounts"
  type        = list(string)
  
  validation {
    condition     = length(var.student_emails) > 0 && length(var.student_emails) <= 30
    error_message = "Must provide between 1 and 30 student emails."
  }
}

variable "admin_email" {
  description = "Email address of the admin/instructor"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.admin_email))
    error_message = "Admin email must be a valid email address."
  }
}

# ============================================================================
# Compute Resources
# ============================================================================

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
  
  validation {
    condition     = var.cpu_cores >= 2 && var.cpu_cores <= 16
    error_message = "CPU cores must be between 2 and 16."
  }
}

variable "ram_mb" {
  description = "RAM in megabytes"
  type        = number
  default     = 8192
  
  validation {
    condition     = var.ram_mb >= 4096 && var.ram_mb <= 32768
    error_message = "RAM must be between 4096 MB and 32768 MB."
  }
}

variable "disk_gb" {
  description = "Disk size in gigabytes"
  type        = number
  default     = 50
  
  validation {
    condition     = var.disk_gb >= 20 && var.disk_gb <= 500
    error_message = "Disk size must be between 20 GB and 500 GB."
  }
}

variable "enable_gpu" {
  description = "Enable GPU support for deep learning"
  type        = bool
  default     = false
}

# ============================================================================
# Python Environment
# ============================================================================

variable "python_packages" {
  description = "Additional Python packages to install"
  type        = list(string)
  default = [
    "pandas",
    "numpy",
    "matplotlib",
    "scikit-learn",
    "seaborn"
  ]
}

variable "notebook_directory" {
  description = "Directory path for exercise notebooks"
  type        = string
  default     = "/home/jovyan/exercises"
}

# ============================================================================
# Git Integration
# ============================================================================

variable "enable_git_sync" {
  description = "Enable automatic Git repository synchronization"
  type        = bool
  default     = false
}

variable "git_repo_url" {
  description = "Git repository URL for exercise materials"
  type        = string
  default     = ""
}

# ============================================================================
# OpenStack Configuration
# ============================================================================

variable "image_name" {
  description = "Name of the Ubuntu image to use"
  type        = string
  default     = "Ubuntu 22.04 LTS"
}

variable "network_name" {
  description = "Name of the OpenStack network"
  type        = string
  default     = "default-network"
}

variable "external_network_name" {
  description = "Name of the external network for floating IPs"
  type        = string
  default     = "public"
}

variable "floating_ip_pool" {
  description = "Floating IP pool name"
  type        = string
  default     = "public"
}