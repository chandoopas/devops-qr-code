# ============================================================================
# variables.tf - Variable Definitions for Terraform Configuration
# ============================================================================
#
# This file DEFINES variables (declares them) but doesn't set their values
# Actual values are set in terraform.tfvars
#
# Think of it like this:
#   variables.tf = "I need a variable called 'cluster_name'"
#   terraform.tfvars = "The cluster_name is 'qr-code-aks-cluster'"
#
# Why separate files?
#   - variables.tf is committed to Git (it's configuration)
#   - terraform.tfvars can be kept private (it has your specific values)
#
# ============================================================================

# ----------------------------------------------------------------------------
# Resource Group Variables
# ----------------------------------------------------------------------------

variable "resource_group_name" {
  # Human-readable description
  # This appears in documentation and helps others understand what this variable is for
  description = "Name of the Azure Resource Group that will contain all Kubernetes resources"

  # Data type
  # string = text value (not a number or boolean)
  # Other types: number, bool, list, map, object
  type = string

  # Default value (optional)
  # If you don't provide a value in terraform.tfvars, this default is used
  # If no default is set, Terraform will prompt you to enter a value
  # For required variables, it's often better to NOT set a default
  # This forces you to provide a value explicitly
  default = "qr-code-k8s-rg"

  # Validation rules (optional)
  # Ensures the value meets certain criteria before Terraform runs
  # This prevents errors by catching invalid values early
  validation {
    # Condition: must be true for the value to be valid
    # This checks:
    #   - length > 0: not empty
    #   - length <= 90: Azure resource group name limit
    #   - regex: only lowercase letters, numbers, hyphens, underscores, periods, parentheses
    condition = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90 && can(regex("^[a-zA-Z0-9-_().]+$", var.resource_group_name))

    # Error message shown if validation fails
    error_message = "Resource group name must be 1-90 characters and can only contain letters, numbers, hyphens, underscores, periods, and parentheses."
  }
}

variable "location" {
  # Description
  description = "Azure region where resources will be created (e.g., eastus, westus2, centralus)"

  # Type
  type = string

  # Default value
  # Common regions:
  #   - eastus: East US (Virginia)
  #   - westus2: West US 2 (Washington)
  #   - centralus: Central US (Iowa)
  #   - westeurope: West Europe (Netherlands)
  #   - southeastasia: Southeast Asia (Singapore)
  # 
  # TIP: Use the same region as your Container Registry for:
  #   - Faster image pulls
  #   - Lower latency
  #   - No cross-region data transfer charges
  default = "eastus"

  # Validation
  # This ensures you use a valid Azure region
  # List includes most common regions
  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "westus3",
      "centralus", "northcentralus", "southcentralus",
      "westcentralus", "canadacentral", "canadaeast",
      "brazilsouth", "northeurope", "westeurope", "uksouth",
      "ukwest", "francecentral", "germanywestcentral",
      "norwayeast", "switzerlandnorth", "swedencentral",
      "australiaeast", "australiasoutheast", "southeastasia",
      "eastasia", "japaneast", "japanwest", "koreacentral",
      "koreasouth", "southindia", "centralindia", "westindia"
    ], var.location)

    error_message = "Location must be a valid Azure region. Use 'az account list-locations -o table' to see available regions."
  }
}

# ----------------------------------------------------------------------------
# AKS Cluster Variables
# ----------------------------------------------------------------------------

variable "cluster_name" {
  # Description
  description = "Name of the Azure Kubernetes Service (AKS) cluster"

  # Type
  type = string

  # Default
  default = "qr-code-aks-cluster"

  # Validation
  # AKS cluster name requirements:
  #   - 1-63 characters
  #   - Alphanumeric and hyphens only
  #   - Must start and end with alphanumeric character
  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 63 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.cluster_name))
    error_message = "Cluster name must be 1-63 characters, contain only lowercase letters, numbers, and hyphens, and must start and end with a letter or number."
  }
}

variable "dns_prefix" {
  # Description
  description = "DNS prefix for the AKS cluster. Used to create the cluster's FQDN (Fully Qualified Domain Name)"

  # Type
  type = string

  # Default
  # This will result in: qr-code-k8s-{random}.hcp.{location}.azmk8s.io
  default = "qr-code-k8s"

  # Validation
  # DNS prefix requirements:
  #   - 1-54 characters
  #   - Alphanumeric and hyphens only
  #   - Must start with a letter
  #   - Must end with alphanumeric character
  validation {
    condition     = length(var.dns_prefix) > 0 && length(var.dns_prefix) <= 54 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.dns_prefix))
    error_message = "DNS prefix must be 1-54 characters, start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

# ----------------------------------------------------------------------------
# Node Pool Variables (The VMs that run your containers)
# ----------------------------------------------------------------------------

variable "node_count" {
  # Description
  description = "Number of nodes (VMs) in the default node pool. Each node can run multiple pods (containers)."

  # Type
  # number = integer value (not string or decimal)
  type = number

  # Default
  # COST OPTIMIZATION: Using 1 node instead of 2
  # 1 node is sufficient for learning and saves 50% on costs
  # Each node can run multiple pods, so your backend and frontend can both run on 1 node
  # 
  # Trade-offs:
  #   - 1 node: Cheaper, no redundancy
  #   - 2 nodes: More expensive, has redundancy (one can fail)
  default = 1

  # Validation
  # At least 1 node required
  # Max 100 nodes (Azure limit, but you'd never need this many for learning)
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 100
    error_message = "Node count must be between 1 and 100."
  }
}

variable "node_vm_size" {
  # Description
  description = "Azure VM size for nodes. Determines CPU, RAM, and cost."

  # Type
  type = string

  # Default
  # COST OPTIMIZATION: Using Standard_B2s (cheaper option)
  # 
  # Standard_B2s specs:
  #   - 2 vCPU
  #   - 4 GB RAM
  #   - Burstable (can use more CPU when available)
  #   - Cost: ~$0.042/hour (~$1/day, ~$30/month per node)
  # 
  # Other common options:
  #   - Standard_B2s: 2 vCPU, 4 GB RAM, ~$0.042/hour (cheapest, good for learning)
  #   - Standard_D2s_v3: 2 vCPU, 8 GB RAM, ~$0.096/hour (more RAM, production-ready)
  #   - Standard_D4s_v3: 4 vCPU, 16 GB RAM, ~$0.192/hour (more power, expensive)
  # 
  # Recommendation: Start with Standard_B2s, upgrade if needed
  default = "Standard_B2s"

  # Validation
  # This list includes common VM sizes
  # You can add more sizes if needed
  validation {
    condition = contains([
      "Standard_B2s", "Standard_B2ms", "Standard_B4ms",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3",
      "Standard_DS2_v2", "Standard_DS3_v2", "Standard_DS4_v2",
      "Standard_E2s_v3", "Standard_E4s_v3"
    ], var.node_vm_size)
    error_message = "Node VM size must be a valid Azure VM size. Common options: Standard_B2s (cheap), Standard_D2s_v3 (balanced), Standard_D4s_v3 (powerful)."
  }
}

# ----------------------------------------------------------------------------
# Container Registry Variables (Your existing ACR)
# ----------------------------------------------------------------------------

variable "acr_name" {
  # Description
  description = "Name of the existing Azure Container Registry. This is where your Docker images are stored."

  # Type
  type = string

  # Default
  # This is your existing ACR: qrappregistry2026
  # Change this if you used a different name
  default = "qrappregistry2026"

  # Validation
  # ACR name requirements:
  #   - 5-50 characters
  #   - Alphanumeric only (no hyphens or special characters)
  #   - Must be globally unique across all of Azure
  validation {
    condition     = length(var.acr_name) >= 5 && length(var.acr_name) <= 50 && can(regex("^[a-z0-9]+$", var.acr_name))
    error_message = "ACR name must be 5-50 characters and contain only lowercase letters and numbers."
  }
}

variable "acr_resource_group" {
  # Description
  description = "Name of the resource group where the Container Registry exists"

  # Type
  type = string

  # Default
  # This is where you created your ACR earlier
  # Find it with: az acr show --name qrappregistry2026 --query resourceGroup -o tsv
  # Common names: qr-code-project-rg, devops-qr-code-rg
  default = "qr-code-project-rg"

  # Note: If you don't remember your ACR resource group, run:
  #   az acr show --name qrappregistry2026 --query resourceGroup -o tsv
}

# ============================================================================
# END OF VARIABLES.TF
# ============================================================================
#
# SUMMARY OF VARIABLES:
#
# Resource Group:
#   - resource_group_name: Name of the new resource group for Kubernetes
#   - location: Azure region (should match your ACR)
#
# AKS Cluster:
#   - cluster_name: Name of the Kubernetes cluster
#   - dns_prefix: DNS prefix for cluster access
#
# Node Pool:
#   - node_count: Number of VMs (recommended: 1 for cost optimization)
#   - node_vm_size: VM size (recommended: Standard_B2s for learning)
#
# Container Registry:
#   - acr_name: Your existing ACR name
#   - acr_resource_group: Where your ACR exists
#
# HOW TO USE:
# 1. Review these variable definitions
# 2. Set actual values in terraform.tfvars
# 3. Run terraform plan to preview
# 4. Run terraform apply to create
#
# COST IMPACT OF VARIABLES:
# - node_count = 1: ~$0.042/hour (single node)
# - node_count = 2: ~$0.084/hour (double cost)
# - node_vm_size = "Standard_B2s": ~$0.042/hour (cheap)
# - node_vm_size = "Standard_D2s_v3": ~$0.096/hour (more expensive)
#
# VALIDATION BENEFITS:
# - Catches typos before deployment
# - Prevents invalid Azure resource names
# - Ensures cost-conscious defaults
# - Saves time by failing fast
#
# ============================================================================
