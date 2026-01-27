# ============================================================================
# SYSTEM VARIABLES (MANDATORY)
# ============================================================================

variable "deployment_id" {
  description = "Unique deployment identifier"
  type        = string
  
  validation {
    condition     = length(var.deployment_id) > 0
    error_message = "deployment_id must not be empty."
  }
}

variable "use_mock_provider" {
  description = "Use mock provider for testing"
  type        = bool
  default     = false
}

variable "app_name" {
  type        = string
  description = "Name of the Application"
  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.app_name))
    error_message = "app_name: Nur Kleinbuchstaben, Zahlen und Bindestrich erlaubt (3-20 Zeichen)."
  }
}
# ============================================================================
# USER INPUTS (VALIDATED CONTRACT)
# ============================================================================

variable "student_emails" {
  description = "List of student email addresses"
  type        = list(string)
  
  validation {
    condition     = length(var.student_emails) > 0
    error_message = "At least one student email is required."
  }
  
  validation {
    condition = alltrue([
      for email in var.student_emails : can(regex("^\\S+@\\S+\\.\\S+$", email))
    ])
    error_message = "All items in student_emails must be valid email addresses."
  }
}

variable "admin_email" {
  description = "Email address of the admin"
  type        = string

  validation {
    # Regex aus template.yaml
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.admin_email))
    error_message = "The admin_email is invalid."
  }
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2

  validation {
    condition     = var.cpu_cores >= 2 && var.cpu_cores <= 8
    error_message = "cpu_cores must be between 2 and 8."
  }
}

variable "ram_mb" {
  description = "RAM in megabytes"
  type        = number
  default     = 4096

  validation {
    condition     = var.ram_mb >= 2048 && var.ram_mb <= 16384
    error_message = "ram_mb must be between 2048 and 16384 MB."
  }
}

variable "disk_gb" {
  description = "Disk size in gigabytes"
  type        = number
  default     = 20

  validation {
    condition     = var.disk_gb >= 10 && var.disk_gb <= 100
    error_message = "disk_gb must be between 10 and 100 GB."
  }
}

variable "enable_gpu" {
  description = "Enable GPU support"
  type        = bool
  default     = false
}

# ============================================================================
# APP CONFIGURATION
# ============================================================================

variable "python_packages" {
  description = "Additional Python packages"
  type        = list(string)
  default = ["pandas", "numpy", "matplotlib", "scikit-learn", "seaborn"]
}

variable "notebook_directory" {
  description = "Directory for notebooks"
  type        = string
  default     = "exercises"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.notebook_directory))
    error_message = "notebook_directory must be a simple directory name (no paths)."
  }
}

variable "enable_git_sync" {
  description = "Enable Git sync"
  type        = bool
  default     = false
}

variable "git_repo_url" {
  description = "Git repository URL"
  type        = string
  default     = ""
}

# ============================================================================
# INFRASTRUCTURE DEFAULTS
# ============================================================================

variable "image_name" {
  type    = string
  default = "Ubuntu 22.04"
}

variable "network_name" {
  type    = string
  default = "NAT"
}

variable "external_network_name" {
  type    = string
  default = "DHBW"
}

variable "floating_ip_pool" {
  type    = string
  default = "DHBW"
}

variable "flavor_name" {
  type    = string
  default = "gp1.medium"
}