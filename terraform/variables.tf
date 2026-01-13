# ============================================================================
# System Variablen (vom CloudStore automatisch gesetzt)
# ============================================================================

variable "deployment_id" {
  description = "Unique deployment identifier from CloudStore"
  type        = string
}

variable "use_mock_provider" {
  description = "Use mock provider for testing (no real OpenStack resources)"
  type        = bool
  default     = false
}

# ============================================================================
# Benutzer-Inputs (müssen exakt zur template.yaml passen)
# ============================================================================

variable "student_emails" {
  description = "List of student email addresses"
  type        = list(string)
  
  # Terraform Validation ist ein guter "zweiter Check" nach dem Frontend
  validation {
    condition     = length(var.student_emails) > 0
    error_message = "At least one student email is required."
  }
}

variable "admin_email" {
  description = "Email address of the admin/instructor"
  type        = string
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "ram_mb" {
  description = "RAM in megabytes"
  type        = number
  default     = 4096
}

# WICHTIG: Hier heißt es "disk_gb", genau wie im template.yaml!
# In der Student-VM hieß es "volume_size". Das muss einheitlich sein.
variable "disk_gb" {
  description = "Disk size in gigabytes"
  type        = number
  default     = 20
}

variable "enable_gpu" {
  description = "Enable GPU support for deep learning"
  type        = bool
  default     = false
}

# ============================================================================
# App-Konfiguration (Optional im Template)
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
  default     = "exercises" # Relativ zum Home-Dir ist oft sicherer
}

variable "enable_git_sync" {
  description = "Enable automatic Git repository synchronization"
  type        = bool
  default     = false
}

variable "git_repo_url" {
  description = "Git repository URL"
  type        = string
  default     = ""
}
variable "external_network_name" {
  description = "Name des externen Netzwerks für Floating IPs"
  type        = string
  default     = "public"
}

# ============================================================================
# Infrastruktur-Defaults (Oft versteckt oder vom Admin gesetzt)
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

variable "floating_ip_pool" {
  description = "Floating IP pool name"
  type        = string
  default     = "public"
}

variable "flavor_name" {
  description = "Name des Flavors (Hardware-Größe) in OpenStack"
  type        = string
  default     = "m1.medium" # Standard-Name, den wir gleich in tfvars anpassen
}