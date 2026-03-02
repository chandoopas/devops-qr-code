# ============================================================================
# outputs.tf - Output Definitions for Terraform
# ============================================================================
#
# Outputs display important information after terraform apply completes
# They're useful for:
#   - Showing resource IDs, names, and endpoints
#   - Passing values to other Terraform modules
#   - Documenting what was created
#   - Getting connection information
#
# You can view outputs anytime with: terraform output
# You can get a specific output with: terraform output <name>
# You can get raw output with: terraform output -raw <name>
#
# ============================================================================

# ----------------------------------------------------------------------------
# Kubernetes Configuration File (kubeconfig)
# ----------------------------------------------------------------------------

output "kube_config" {
  # Human-readable description
  # This appears when you run terraform output
  description = "Kubernetes configuration file (kubeconfig) for connecting to the cluster with kubectl"

  # The actual value to output
  # azurerm_kubernetes_cluster.aks: our cluster resource
  # .kube_config_raw: the raw kubeconfig content (not base64 encoded)
  # This is a multi-line YAML file containing:
  #   - Cluster API server endpoint
  #   - Cluster certificate
  #   - User credentials
  #   - Context information
  value = azurerm_kubernetes_cluster.aks.kube_config_raw

  # Mark as sensitive
  # When true, Terraform will:
  #   - Show "(sensitive value)" instead of the actual content
  #   - Hide it from console output
  #   - Prevent accidental exposure in logs
  # This is important because kubeconfig contains credentials
  sensitive = true

  # How to use this output:
  # terraform output -raw kube_config > ~/.kube/config
  # 
  # This saves the kubeconfig to the default kubectl location
  # Then you can use kubectl commands:
  #   kubectl get nodes
  #   kubectl get pods
  #   kubectl apply -f deployment.yaml
}

# ----------------------------------------------------------------------------
# Cluster Information Outputs
# ----------------------------------------------------------------------------

output "cluster_name" {
  # Description
  description = "Name of the AKS cluster"

  # Value
  # Returns the cluster name (e.g., "qr-code-aks-cluster")
  value = azurerm_kubernetes_cluster.aks.name

  # This is useful for:
  #   - Confirming what was created
  #   - Using in scripts or other automation
  #   - Documenting the deployment
}

output "cluster_id" {
  # Description
  description = "Azure Resource ID of the AKS cluster"

  # Value
  # Returns the full resource ID
  # Format: /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.ContainerService/managedClusters/{name}
  value = azurerm_kubernetes_cluster.aks.id

  # This is useful for:
  #   - Azure CLI commands that need the resource ID
  #   - Azure Portal direct links
  #   - Other Terraform configurations that reference this cluster
}

output "cluster_fqdn" {
  # Description
  description = "Fully Qualified Domain Name (FQDN) of the cluster's API server"

  # Value
  # Returns the DNS name for the Kubernetes API server
  # Format: {dns_prefix}-{random}.hcp.{location}.azmk8s.io
  # Example: qr-code-k8s-abc123.hcp.eastus.azmk8s.io
  value = azurerm_kubernetes_cluster.aks.fqdn

  # This is useful for:
  #   - Knowing the API server endpoint
  #   - Troubleshooting connectivity
  #   - Configuring firewall rules
}

output "kubernetes_version" {
  # Description
  description = "Kubernetes version running on the cluster"

  # Value
  # Returns the actual Kubernetes version
  # Example: "1.28.3"
  value = azurerm_kubernetes_cluster.aks.kubernetes_version

  # This is useful for:
  #   - Verifying the version
  #   - Planning upgrades
  #   - Compatibility checking for deployments
}

# ----------------------------------------------------------------------------
# Resource Group Information
# ----------------------------------------------------------------------------

output "resource_group_name" {
  # Description
  description = "Name of the resource group containing the AKS cluster"

  # Value
  # Returns the resource group name (e.g., "qr-code-k8s-rg")
  value = azurerm_resource_group.aks_rg.name

  # This is useful for:
  #   - Finding resources in Azure Portal
  #   - Azure CLI commands
  #   - Organizing resources
}

output "resource_group_location" {
  # Description
  description = "Azure region where resources are deployed"

  # Value
  # Returns the location (e.g., "eastus")
  value = azurerm_resource_group.aks_rg.location

  # This is useful for:
  #   - Confirming deployment location
  #   - Multi-region deployments
  #   - Latency considerations
}

# ----------------------------------------------------------------------------
# Node Pool Information
# ----------------------------------------------------------------------------

output "node_resource_group" {
  # Description
  description = "Name of the auto-created resource group containing node resources"

  # Value
  # Azure automatically creates a second resource group for node-level resources
  # This includes: VMs, disks, NICs, NSGs
  # Format: MC_{your-rg}_{cluster-name}_{location}
  # Example: MC_qr-code-k8s-rg_qr-code-aks-cluster_eastus
  value = azurerm_kubernetes_cluster.aks.node_resource_group

  # This is useful for:
  #   - Finding node-level resources in Azure Portal
  #   - Understanding Azure's resource organization
  #   - Troubleshooting node issues
  # 
  # Note: This resource group is managed by Azure
  # Don't manually modify resources in this group
  # They're automatically created/deleted with the cluster
}

output "node_count" {
  # Description
  description = "Number of nodes in the default node pool"

  # Value
  # Returns how many VMs are in the cluster
  value = azurerm_kubernetes_cluster.aks.default_node_pool[0].node_count

  # This is useful for:
  #   - Confirming node count
  #   - Cost calculations
  #   - Capacity planning
}

output "node_vm_size" {
  # Description
  description = "VM size (type) of nodes in the default node pool"

  # Value
  # Returns the VM size (e.g., "Standard_B2s")
  value = azurerm_kubernetes_cluster.aks.default_node_pool[0].vm_size

  # This is useful for:
  #   - Confirming VM size
  #   - Cost calculations (different sizes have different costs)
  #   - Performance expectations
}

# ----------------------------------------------------------------------------
# Identity Information
# ----------------------------------------------------------------------------

output "kubelet_identity_object_id" {
  # Description
  description = "Object ID of the kubelet managed identity (used for node permissions)"

  # Value
  # Returns the object ID of the cluster's system-assigned identity
  # This identity is used by nodes to authenticate with Azure services
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  # This is useful for:
  #   - Granting additional permissions to the cluster
  #   - Troubleshooting authentication issues
  #   - Understanding cluster security
}

output "cluster_identity_principal_id" {
  # Description
  description = "Principal ID of the cluster's system-assigned identity"

  # Value
  # Returns the principal ID of the cluster's managed identity
  value = azurerm_kubernetes_cluster.aks.identity[0].principal_id

  # This is useful for:
  #   - Azure RBAC assignments
  #   - Identity-based access control
  #   - Security auditing
}

# ----------------------------------------------------------------------------
# Network Information
# ----------------------------------------------------------------------------

output "network_plugin" {
  # Description
  description = "Network plugin used by the cluster"

  # Value
  # Returns "azure" or "kubenet"
  # We're using "azure" (Azure CNI)
  value = azurerm_kubernetes_cluster.aks.network_profile[0].network_plugin

  # This is useful for:
  #   - Understanding networking configuration
  #   - Troubleshooting network issues
  #   - Planning network policies
}

output "load_balancer_sku" {
  # Description
  description = "SKU (tier) of the load balancer"

  # Value
  # Returns "standard" (Azure now requires standard for new AKS clusters)
  # "basic" is no longer supported as of recent Azure updates
  value = azurerm_kubernetes_cluster.aks.network_profile[0].load_balancer_sku

  # This is useful for:
  #   - Understanding load balancer capabilities
  #   - Cost tracking (standard: ~$0.025/hour ~$18/month)
  #   - Feature availability
}

# ----------------------------------------------------------------------------
# Cost Information (Calculated)
# ----------------------------------------------------------------------------

output "estimated_monthly_cost" {
  # Description
  description = "Estimated monthly cost if running 24/7 (excluding ACR and storage)"

  # Value
  # This is a calculated estimate based on VM size and count
  # Actual costs may vary based on:
  #   - Actual usage hours
  #   - Region
  #   - Disk usage
  #   - Egress traffic
  #
  # Cost estimates (with STANDARD load balancer - required by Azure):
  #   - 1 × Standard_B2s: ~$30/node/month + $18 LB = ~$48/month
  #   - 2 × Standard_B2s: ~$60/nodes/month + $18 LB = ~$78/month
  #   - 1 × Standard_D2s_v3: ~$70/node/month + $18 LB = ~$88/month
  #   - 2 × Standard_D2s_v3: ~$140/nodes/month + $18 LB = ~$158/month
  value = format("Approximately $%.2f per month if running 24/7 (1 × %s node + standard load balancer)",
    var.node_vm_size == "Standard_B2s" ? 48.00 : var.node_vm_size == "Standard_D2s_v3" ? 88.00 : 65.00,
    var.node_vm_size
  )

  # With destroy strategy (4 hours/day):
  #   - Hourly: ~$0.067 (node + load balancer)
  #   - Daily (4 hours): ~$0.27/day
  #   - Weekly: ~$1.89/week
  #   - Still very affordable! ✅
}

# ============================================================================
# END OF OUTPUTS.TF
# ============================================================================
#
# HOW TO VIEW OUTPUTS:
#
# After terraform apply:
#   terraform output                    # Shows all outputs
#   terraform output cluster_name       # Shows specific output
#   terraform output -raw kube_config   # Shows raw kubeconfig (no formatting)
#   terraform output -json              # Shows all outputs as JSON
#
# USING OUTPUTS:
#
# Save kubeconfig:
#   terraform output -raw kube_config > ~/.kube/config
#
# Use in scripts:
#   CLUSTER_NAME=$(terraform output -raw cluster_name)
#   az aks show --name $CLUSTER_NAME --resource-group $(terraform output -raw resource_group_name)
#
# EXAMPLE OUTPUT DISPLAY:
#
# After terraform apply completes, you'll see:
#
#   Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
#   
#   Outputs:
#   
#   cluster_fqdn = "qr-code-k8s-abc123.hcp.eastus.azmk8s.io"
#   cluster_id = "/subscriptions/12345.../qr-code-aks-cluster"
#   cluster_name = "qr-code-aks-cluster"
#   estimated_monthly_cost = "~$30.00 per month (node costs only, if running 24/7)"
#   kubernetes_version = "1.28.3"
#   node_count = 1
#   node_vm_size = "Standard_B2s"
#   resource_group_name = "qr-code-k8s-rg"
#   resource_group_location = "eastus"
#   
#   kube_config = <sensitive>
#
# IMPORTANT OUTPUTS FOR NEXT STEPS:
#
# 1. kube_config: Save this to connect with kubectl
# 2. cluster_name: Use for Azure CLI commands
# 3. resource_group_name: Find resources in Azure Portal
# 4. estimated_monthly_cost: Understand your spending
#
# ============================================================================
