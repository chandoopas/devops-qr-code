# ============================================================================
# main.tf - Main Terraform Configuration for Azure Kubernetes Service (AKS)
# ============================================================================
#
# This file defines the infrastructure for your Kubernetes cluster in Azure.
# It creates:
#   1. Resource Group (container for all resources)
#   2. AKS Cluster (Kubernetes environment)
#   3. Node Pool (1 × Standard_B2s VM - cost optimized)
#   4. ACR Integration (pull images from Container Registry)
#
# Cost: ~$0.042/hour (~$1/day if running 24/7)
# Strategy: Run terraform destroy when not using to save money
#
# ============================================================================

# ----------------------------------------------------------------------------
# SECTION 1: Terraform and Provider Configuration
# ----------------------------------------------------------------------------
# This section tells Terraform which cloud provider to use (Azure)
# and which version of the provider to download.

terraform {
  # Specify required providers
  required_providers {
    azurerm = {
      # Azure Resource Manager provider
      # This is the official provider for managing Azure resources
      source = "hashicorp/azurerm"

      # Version constraint: Use any 3.x version
      # ~> 3.0 means: >= 3.0 and < 4.0
      # This ensures compatibility while allowing minor updates
      version = "~> 3.0"
    }
  }

  # Minimum Terraform version required
  # This configuration works with Terraform 1.0 and above
  required_version = ">= 1.0"
}

# Configure the Azure Provider
provider "azurerm" {
  # Features block is required (even if empty)
  # This is where you'd enable/disable specific Azure features
  features {
    # We're using defaults for all features
    # You could customize specific behaviors here if needed
  }

  # Authentication is handled by Azure CLI (az login)
  # No need to specify credentials here - Terraform uses your active session
}

# ----------------------------------------------------------------------------
# SECTION 2: Resource Group
# ----------------------------------------------------------------------------
# A resource group is a container that holds related Azure resources.
# Think of it as a folder that organizes all your Kubernetes resources.
# When you delete the resource group, all resources inside are deleted too.

resource "azurerm_resource_group" "aks_rg" {
  # Resource type: azurerm_resource_group (Azure Resource Group)
  # Local name: aks_rg (used to reference this resource in Terraform)

  # Name of the resource group in Azure
  # This is what you'll see in Azure Portal
  # Value comes from variables.tf (e.g., "qr-code-k8s-rg")
  name = var.resource_group_name

  # Azure region where resources will be created
  # Should match your Container Registry location for best performance
  # Value comes from variables.tf (e.g., "eastus")
  location = var.location

  # Tags are metadata labels for organization and cost tracking
  # These appear in Azure Portal and cost reports
  tags = {
    # Identify the environment (Development, Staging, Production)
    Environment = "Development"

    # Project name for grouping related resources
    Project = "QR-Code-Generator"

    # How this resource was created (for tracking)
    ManagedBy = "Terraform"

    # You can add more tags as needed:
    # CostCenter  = "Engineering"
    # Owner       = "your-name"
  }
}

# ----------------------------------------------------------------------------
# SECTION 3: Data Source - Get Existing Container Registry Info
# ----------------------------------------------------------------------------
# This is a data source, NOT a resource
# Data sources READ information about existing resources
# They don't CREATE anything new
# We need this to get the ACR's ID for granting permissions later

data "azurerm_container_registry" "acr" {
  # Name of your existing Container Registry
  # This is the ACR you created earlier: qrappregistry2026
  # Value comes from variables.tf
  name = var.acr_name

  # Resource group where the ACR exists
  # This is where you created your ACR (e.g., "qr-code-project-rg")
  # Value comes from variables.tf
  resource_group_name = var.acr_resource_group

  # Terraform will query Azure to get this ACR's details
  # We can then reference: data.azurerm_container_registry.acr.id
}

# ----------------------------------------------------------------------------
# SECTION 4: Azure Kubernetes Service (AKS) Cluster
# ----------------------------------------------------------------------------
# This is the main resource - the Kubernetes cluster itself
# It takes 10-15 minutes to create
# This is where your containers will run

resource "azurerm_kubernetes_cluster" "aks" {
  # Resource type: azurerm_kubernetes_cluster (AKS Cluster)
  # Local name: aks (used to reference this cluster in Terraform)

  # Name of the Kubernetes cluster in Azure
  # This is what you'll see in Azure Portal
  # Value comes from variables.tf (e.g., "qr-code-aks-cluster")
  name = var.cluster_name

  # Location: Use the same location as the resource group
  # Syntax: resource_type.local_name.attribute
  # azurerm_resource_group.aks_rg.location reads the location value
  # This creates an implicit dependency: resource group must exist first
  location = azurerm_resource_group.aks_rg.location

  # Resource group: Put the cluster in the resource group we created
  # Another implicit dependency: resource group → cluster
  resource_group_name = azurerm_resource_group.aks_rg.name

  # DNS prefix for the cluster's API server
  # Results in: {dns_prefix}-{random}.hcp.{location}.azmk8s.io
  # Used when connecting with kubectl
  # Value comes from variables.tf (e.g., "qr-code-k8s")
  dns_prefix = var.dns_prefix

  # Kubernetes version to use
  # null means: use the default version (latest stable)
  # You can specify a version like "1.28.3" if needed
  kubernetes_version = null

  # --------------------------------------------------------------------
  # Default Node Pool Configuration
  # --------------------------------------------------------------------
  # Node pool = group of VMs that run your containers
  # "default" pool is required and created with the cluster
  # You can add more node pools later if needed

  default_node_pool {
    # Name of the node pool
    # Must be lowercase alphanumeric, max 12 characters
    # Can't be changed after creation
    name = "default"

    # Number of nodes (VMs) to create
    # COST OPTIMIZATION: Using 1 node instead of 2
    # Value comes from variables.tf (recommended: 1)
    # Each node can run multiple pods (containers)
    node_count = var.node_count

    # VM size (type of virtual machine)
    # COST OPTIMIZATION: Using Standard_B2s (cheaper option)
    # Standard_B2s specs:
    #   - 2 vCPU
    #   - 4 GB RAM
    #   - Cost: ~$0.042/hour (~$1/day)
    # Alternative: Standard_D2s_v3 (2 vCPU, 8 GB RAM, ~$0.096/hour)
    vm_size = var.node_vm_size

    # Auto-scaling configuration
    # COST OPTIMIZATION: Disabled for fixed cost
    # false = Always use exactly node_count nodes
    # true = Can scale between min_count and max_count
    # We set this to false to avoid surprise costs
    enable_auto_scaling = false

    # If enable_auto_scaling was true, you'd set:
    # min_count = 1
    # max_count = 5

    # OS disk size for each node
    # This is the disk space for the VM's operating system
    # 30 GB is minimal but sufficient for:
    #   - Operating system (~10 GB)
    #   - Docker images (~10-15 GB)
    #   - Kubernetes system pods (~5 GB)
    # Default is 128 GB (unnecessary for learning)
    os_disk_size_gb = 30

    # OS disk type
    # Managed = Azure manages the disk (recommended)
    # You could also specify SSD type if needed, but default is fine
    # os_disk_type = "Managed"

    # Type of nodes
    # VirtualMachineScaleSets = modern, supports auto-scaling
    # This is the default and recommended option
    type = "VirtualMachineScaleSets"

    # Availability zones
    # null = Azure chooses (fine for learning)
    # You could specify [1, 2, 3] for high availability
    # zones = null

    # Node labels (Kubernetes labels for pod scheduling)
    # You can add custom labels if needed:
    # node_labels = {
    #   "workload" = "general"
    # }

    # Tags for the nodes (Azure tags, not Kubernetes labels)
    tags = {
      Environment = "Development"
      Project     = "QR-Code-Generator"
      NodePool    = "default"
    }
  }

  # --------------------------------------------------------------------
  # Identity Configuration
  # --------------------------------------------------------------------
  # Managed identity for the cluster
  # This gives the cluster its own "user account" in Azure
  # Used to authenticate with Azure services (ACR, Load Balancer, etc.)

  identity {
    # Type of identity
    # SystemAssigned = Azure creates and manages the identity automatically
    # When cluster is deleted, identity is deleted too
    # Alternative: UserAssigned (more complex, not needed for this)
    type = "SystemAssigned"
  }

  # After creation, you can access:
  # azurerm_kubernetes_cluster.aks.identity[0].principal_id
  # azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  # --------------------------------------------------------------------
  # Network Configuration
  # --------------------------------------------------------------------
  # Controls how networking works in the cluster

  network_profile {
    # Network plugin to use
    # azure = Azure CNI (Container Network Interface)
    #   - Each pod gets an IP from the virtual network
    #   - Better integration with Azure networking
    #   - Uses more IPs but not a problem for our use case
    # Alternative: kubenet (simpler, fewer IPs, less features)
    network_plugin = "azure"

    # Load balancer SKU
    # IMPORTANT UPDATE: Azure now requires "standard" for new AKS clusters
    # "basic" is no longer supported (as of recent Azure updates)
    # 
    # standard = $0.025/hour (~$0.60/day, ~$18/month)
    # 
    # Note: This is slightly more expensive than "basic" was, but it's required
    # Standard load balancer offers:
    #   - Better performance
    #   - More features (zone redundancy, more rules)
    #   - Required for production workloads
    # 
    # Cost impact on your budget:
    #   - Before (with basic): ~$0.047/hour
    #   - Now (with standard): ~$0.067/hour
    #   - Difference: ~$0.02/hour (~$0.48/day)
    #   - Still very affordable with destroy strategy!
    load_balancer_sku = "standard"

    # Network policy
    # null = no network policy (simplest)
    # You could enable "azure" or "calico" for pod-to-pod rules
    # network_policy = null

    # Service CIDR (IP range for Kubernetes services)
    # Default is fine for most cases
    # service_cidr = "10.0.0.0/16"

    # DNS service IP
    # Must be within service_cidr range
    # dns_service_ip = "10.0.0.10"
  }

  # --------------------------------------------------------------------
  # Additional Cluster Settings
  # --------------------------------------------------------------------

  # Automatic channel upgrades
  # null = manual upgrades (you control when to upgrade)
  # Other options: "patch", "stable", "rapid"
  # For learning, manual is fine
  automatic_channel_upgrade = null

  # HTTP application routing (simple ingress)
  # false = disabled (we'll set up ingress manually if needed)
  # true = enables basic ingress (not recommended for production)
  http_application_routing_enabled = false

  # Azure Policy integration
  # false = disabled (simpler for learning)
  # true = enables Azure Policy enforcement
  azure_policy_enabled = false

  # Role-based access control (RBAC)
  # This is enabled by default and is good for security
  # RBAC controls who can do what in the cluster
  role_based_access_control_enabled = true

  # Tags for the cluster resource
  # These appear in Azure Portal and cost reports
  tags = {
    Environment = "Development"
    Project     = "QR-Code-Generator"
    ManagedBy   = "Terraform"
    CostCenter  = "Learning"
  }

  # Note: Cluster creation takes 10-15 minutes
  # Azure provisions:
  #   - Control plane (free, managed by Azure)
  #   - Node pool (the VMs you're paying for)
  #   - Virtual network
  #   - Load balancer
  #   - System node pool (for Kubernetes system pods)
}

# ----------------------------------------------------------------------------
# SECTION 5: Role Assignment - Grant ACR Access to AKS
# ----------------------------------------------------------------------------
# This gives the Kubernetes cluster permission to pull images from ACR
# Without this, you'd need to manually provide docker credentials
# This is the "magic" that connects AKS and ACR

resource "azurerm_role_assignment" "acr_pull" {
  # Resource type: azurerm_role_assignment (Azure RBAC permission)
  # Local name: acr_pull (indicates this is for pulling from ACR)

  # WHO gets the permission
  # principal_id = The identity that needs access
  # We're using the cluster's kubelet identity (the identity used by nodes)
  # Syntax breakdown:
  #   - azurerm_kubernetes_cluster.aks: our cluster resource
  #   - .kubelet_identity: the node identity
  #   - [0]: first (and only) identity
  #   - .object_id: the ID Azure uses for permissions
  principal_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  # WHAT permission to grant
  # AcrPull = Can pull (download) images from ACR
  # This is a built-in Azure role
  # Other roles available:
  #   - AcrPush: Can also push images (not needed)
  #   - AcrDelete: Can delete images (not needed)
  #   - Contributor: Full access (too much)
  role_definition_name = "AcrPull"

  # WHERE the permission applies (scope)
  # This is the ACR resource ID
  # data.azurerm_container_registry.acr.id = ID of your existing ACR
  # Format: /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
  # Permission is limited to ONLY this ACR
  scope = data.azurerm_container_registry.acr.id

  # Skip validation check for service principals
  # Required when using system-assigned identities
  # This is a technical requirement, don't worry about the details
  skip_service_principal_aad_check = true

  # What this achieves:
  # 1. AKS nodes can authenticate to ACR
  # 2. Can pull backend and frontend images
  # 3. No manual docker login needed
  # 4. Automatic and secure

  # Implicit dependency:
  # This role assignment depends on the cluster (needs kubelet_identity)
  # Terraform will create the cluster first, then this role assignment
}

# ============================================================================
# END OF MAIN.TF
# ============================================================================
#
# SUMMARY OF WHAT THIS FILE CREATES:
#
# 1. Resource Group: qr-code-k8s-rg
#    - Container for all resources
#    - Easy to delete everything at once
#
# 2. AKS Cluster: qr-code-aks-cluster
#    - Kubernetes environment
#    - Control plane (free, managed by Azure)
#    - 1 node (Standard_B2s VM)
#    - Basic load balancer
#    - System-assigned identity
#
# 3. Role Assignment:
#    - Grants AcrPull permission
#    - Cluster can pull images from your ACR
#    - Automatic authentication
#
# COST BREAKDOWN:
# - Resource Group: FREE
# - Control Plane: FREE (managed by Azure)
# - 1 × Standard_B2s Node: $0.042/hour
# - Standard Load Balancer: $0.025/hour (required by Azure)
# - Virtual Network: FREE
# - Role Assignment: FREE
# 
# Total: ~$0.067/hour (~$1.61/day if running 24/7)
#
# COST OPTIMIZATION STRATEGY:
# Run: terraform destroy when done for the day
# Next day: terraform apply (ready in 15 minutes)
# Cost with this strategy (4 hours/day): ~$0.27/day (~$1.89/week)
#
# Note: Slightly higher than originally planned due to Azure requiring 
# standard load balancer, but still well within your $100/week budget!
#
# NEXT STEPS AFTER APPLYING:
# 1. Run: terraform apply
# 2. Wait: 10-15 minutes
# 3. Get kubeconfig: terraform output -raw kube_config > ~/.kube/config
# 4. Test: kubectl get nodes
# 5. Deploy your application!
#
# ============================================================================
