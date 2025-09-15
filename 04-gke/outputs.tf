# GKE教學輸出定義

# 網路相關輸出
output "vpc_id" {
  description = "VPC網路ID"
  value       = google_compute_network.gke_network.id
}

output "vpc_name" {
  description = "VPC網路名稱"
  value       = google_compute_network.gke_network.name
}

output "subnet_id" {
  description = "子網路ID"
  value       = google_compute_subnetwork.gke_subnet.id
}

output "subnet_cidr" {
  description = "子網路CIDR區塊"
  value       = google_compute_subnetwork.gke_subnet.ip_cidr_range
}

output "pods_cidr" {
  description = "Pod CIDR區塊"
  value       = var.pods_cidr
}

output "services_cidr" {
  description = "服務CIDR區塊"
  value       = var.services_cidr
}

# GKE集群相關輸出
output "cluster_id" {
  description = "GKE集群ID"
  value       = google_container_cluster.gke_cluster.id
}

output "cluster_name" {
  description = "GKE集群名稱"
  value       = google_container_cluster.gke_cluster.name
}

output "cluster_endpoint" {
  description = "GKE集群端點"
  value       = google_container_cluster.gke_cluster.endpoint
}

output "cluster_location" {
  description = "GKE集群位置"
  value       = google_container_cluster.gke_cluster.location
}

output "cluster_version" {
  description = "GKE集群版本"
  value       = google_container_cluster.gke_cluster.min_master_version
}

output "cluster_ca_certificate" {
  description = "GKE集群CA證書"
  value       = google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

# 節點池相關輸出
output "node_pool" {
  description = "主節點池信息"
  value = {
    id           = google_container_node_pool.gke_node_pool.id
    name         = google_container_node_pool.gke_node_pool.name
    node_count   = google_container_node_pool.gke_node_pool.node_count
    machine_type = google_container_node_pool.gke_node_pool.node_config[0].machine_type
    disk_size    = google_container_node_pool.gke_node_pool.node_config[0].disk_size_gb
    disk_type    = google_container_node_pool.gke_node_pool.node_config[0].disk_type
  }
}

output "spot_node_pool" {
  description = "Spot節點池信息"
  value = var.enable_spot_nodes ? {
    id           = google_container_node_pool.gke_spot_pool[0].id
    name         = google_container_node_pool.gke_spot_pool[0].name
    machine_type = google_container_node_pool.gke_spot_pool[0].node_config[0].machine_type
    max_nodes    = google_container_node_pool.gke_spot_pool[0].autoscaling[0].max_node_count
  } : null
}

# 自動擴展相關輸出
output "cluster_autoscaling" {
  description = "集群自動擴展配置"
  value = {
    enabled = google_container_cluster.gke_cluster.cluster_autoscaling[0].enabled
    cpu_min = google_container_cluster.gke_cluster.cluster_autoscaling[0].resource_limits[0].minimum
    cpu_max = google_container_cluster.gke_cluster.cluster_autoscaling[0].resource_limits[0].maximum
    memory_min = google_container_cluster.gke_cluster.cluster_autoscaling[0].resource_limits[1].minimum
    memory_max = google_container_cluster.gke_cluster.cluster_autoscaling[0].resource_limits[1].maximum
  }
}

output "node_pool_autoscaling" {
  description = "節點池自動擴展配置"
  value = {
    min_node_count = google_container_node_pool.gke_node_pool.autoscaling[0].min_node_count
    max_node_count = google_container_node_pool.gke_node_pool.autoscaling[0].max_node_count
  }
}

# Ingress相關輸出
output "ingress_ip" {
  description = "Ingress外部IP地址"
  value       = google_compute_global_address.ingress_ip.address
}

output "ingress_url" {
  description = "Ingress URL"
  value       = "http://${google_compute_global_address.ingress_ip.address}"
}

# Kubernetes資源相關輸出
output "kubernetes_resources" {
  description = "Kubernetes資源信息"
  value = {
    namespace = {
      name = kubernetes_namespace.app_namespace.metadata[0].name
    }
    deployment = {
      name     = kubernetes_deployment.nginx_deployment.metadata[0].name
      replicas = kubernetes_deployment.nginx_deployment.spec[0].replicas
    }
    service = {
      name = kubernetes_service.nginx_service.metadata[0].name
      type = kubernetes_service.nginx_service.spec[0].type
    }
    ingress = {
      name = kubernetes_ingress.nginx_ingress.metadata[0].name
      host = var.ingress_host
    }
    hpa = {
      name         = kubernetes_horizontal_pod_autoscaler.nginx_hpa.metadata[0].name
      min_replicas = kubernetes_horizontal_pod_autoscaler.nginx_hpa.spec[0].min_replicas
      max_replicas = kubernetes_horizontal_pod_autoscaler.nginx_hpa.spec[0].max_replicas
    }
    pdb = {
      name = kubernetes_pod_disruption_budget.nginx_pdb.metadata[0].name
    }
  }
}

# 服務帳戶相關輸出
output "service_account" {
  description = "GKE服務帳戶信息"
  value = {
    email = google_service_account.gke_sa.email
    id    = google_service_account.gke_sa.id
  }
}

# 防火牆規則相關輸出
output "firewall_rules" {
  description = "防火牆規則信息"
  value = {
    ssh = {
      name = google_compute_firewall.allow_ssh.name
      id   = google_compute_firewall.allow_ssh.id
    }
    http_https = {
      name = google_compute_firewall.allow_http_https.name
      id   = google_compute_firewall.allow_http_https.id
    }
  }
}

# NAT相關輸出
output "nat_router" {
  description = "NAT路由器信息"
  value = {
    id   = google_compute_router.gke_router.id
    name = google_compute_router.gke_router.name
  }
}

output "nat_gateway" {
  description = "NAT網關信息"
  value = {
    id   = google_compute_router_nat.gke_nat.id
    name = google_compute_router_nat.gke_nat.name
  }
}

# 連接命令輸出
output "kubectl_commands" {
  description = "kubectl連接命令"
  value = {
    get_credentials = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --region ${google_container_cluster.gke_cluster.location}"
    get_nodes       = "kubectl get nodes"
    get_pods        = "kubectl get pods -A"
    get_services     = "kubectl get services -A"
    get_ingress      = "kubectl get ingress -A"
  }
}

# 集群狀態輸出
output "cluster_status" {
  description = "集群狀態信息"
  value = {
    status = google_container_cluster.gke_cluster.status
    endpoint = google_container_cluster.gke_cluster.endpoint
    master_version = google_container_cluster.gke_cluster.master_version
    node_count = google_container_node_pool.gke_node_pool.node_count
    private_cluster = google_container_cluster.gke_cluster.private_cluster_config[0].enable_private_nodes
  }
}

# 資源摘要輸出
output "resource_summary" {
  description = "創建的資源摘要"
  value = {
    vpc_created              = true
    subnet_created           = true
    cluster_created          = true
    node_pool_created        = true
    spot_node_pool_created   = var.enable_spot_nodes
    ingress_created          = true
    kubernetes_resources_created = true
    monitoring_enabled       = var.enable_monitoring
    logging_enabled          = var.enable_logging
    network_policy_enabled  = var.enable_network_policy
    workload_identity_enabled = var.enable_workload_identity
  }
}

# 架構信息輸出
output "architecture_info" {
  description = "架構信息"
  value = {
    project_name     = var.project_name
    region          = var.region
    cluster_name    = google_container_cluster.gke_cluster.name
    kubernetes_version = var.kubernetes_version
    release_channel = var.release_channel
    node_machine_type = var.node_machine_type
    min_nodes       = var.min_node_count
    max_nodes       = var.max_node_count
    environment     = var.environment
  }
}

# 成本估算輸出
output "estimated_monthly_cost" {
  description = "預估月度成本（美元）"
  value = {
    cluster_management = "~$73"        # GKE集群管理費
    nodes              = "~$${var.node_count * 15}-$${var.node_count * 30}"  # 節點費用
    load_balancer      = "~$18"        # HTTP負載平衡器
    nat_gateway        = "~$45"        # Cloud NAT
    ingress_ip         = "~$1.5"       # 靜態IP
    spot_nodes         = var.enable_spot_nodes ? "~$${var.max_spot_nodes * 5}-$${var.max_spot_nodes * 10}" : "$0"
    total_estimate     = "~$${137 + (var.node_count * 15)}-$${137 + (var.node_count * 30)}"
  }
}
