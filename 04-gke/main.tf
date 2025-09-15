# 第4章：Google Kubernetes Engine (GKE) 教學
# 本範例展示如何創建和管理GKE集群

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 創建VPC網路
resource "google_compute_network" "gke_network" {
  name                    = "${var.project_name}-gke-network"
  auto_create_subnetworks = false
  description             = "VPC network for GKE cluster"
}

# 創建子網路
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${var.project_name}-gke-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.gke_network.id
  
  # 啟用私有IP Google訪問
  private_ip_google_access = true
  
  # 次要IP範圍用於Pod和服務
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }
  
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

# 創建Cloud NAT
resource "google_compute_router" "gke_router" {
  name    = "${var.project_name}-gke-router"
  region  = var.region
  network = google_compute_network.gke_network.id
  
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "gke_nat" {
  name                               = "${var.project_name}-gke-nat"
  router                            = google_compute_router.gke_router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# 創建防火牆規則
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-gke-allow-ssh"
  network = google_compute_network.gke_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["gke-node"]
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.project_name}-gke-allow-http-https"
  network = google_compute_network.gke_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-node"]
}

# 創建服務帳戶
resource "google_service_account" "gke_sa" {
  account_id   = "${var.project_name}-gke-sa"
  display_name = "GKE Service Account"
  description  = "Service account for GKE cluster"
}

# 分配必要權限
resource "google_project_iam_member" "gke_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# 創建GKE集群
resource "google_container_cluster" "gke_cluster" {
  name     = "${var.project_name}-gke-cluster"
  location = var.region
  
  # 移除默認節點池
  remove_default_node_pool = true
  initial_node_count       = 0
  
  # 網路配置
  network    = google_compute_network.gke_network.name
  subnetwork = google_compute_subnetwork.gke_subnet.name
  
  # 集群IP範圍
  cluster_ipv4_cidr = var.cluster_cidr
  
  # 私有集群配置
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }
  
  # 主授權網路
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.subnet_cidr
      display_name = "subnet-cidr"
    }
  }
  
  # 網路策略
  network_policy {
    enabled = true
  }
  
  # 集群自動擴展
  cluster_autoscaling {
    enabled = true
    
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 10
    }
    
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 20
    }
  }
  
  # 維護策略
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
  
  # 版本配置
  min_master_version = var.kubernetes_version
  
  # 日誌配置
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  
  # 監控配置
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
  }
  
  # 工作負載身份
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # 發布策略
  release_channel {
    channel = var.release_channel
  }
  
  # 資源標籤
  resource_labels = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# 創建節點池
resource "google_container_node_pool" "gke_node_pool" {
  name       = "${var.project_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.gke_cluster.name
  node_count = var.node_count
  
  # 自動擴展配置
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  
  # 管理配置
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  # 升級策略
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
  
  # 節點配置
  node_config {
    # 機器類型
    machine_type = var.node_machine_type
    
    # 映像類型
    image_type = var.node_image_type
    
    # 磁碟配置
    disk_size_gb = var.node_disk_size
    disk_type    = var.node_disk_type
    
    # 預留實例
    preemptible = var.enable_preemptible_nodes
    
    # 服務帳戶
    service_account = google_service_account.gke_sa.email
    
    # OAuth範圍
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    # 元數據
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    # 標籤
    tags = ["gke-node"]
    
    # 工作負載身份
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    # 污點
    dynamic "taint" {
      for_each = var.node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
    
    # 標籤
    labels = {
      environment = var.environment
      project     = var.project_name
    }
  }
}

# 創建額外的節點池（用於特殊工作負載）
resource "google_container_node_pool" "gke_spot_pool" {
  count    = var.enable_spot_nodes ? 1 : 0
  name     = "${var.project_name}-spot-pool"
  location = var.region
  cluster  = google_container_cluster.gke_cluster.name
  
  # 自動擴展配置
  autoscaling {
    min_node_count = 0
    max_node_count = var.max_spot_nodes
  }
  
  # 管理配置
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  # 節點配置
  node_config {
    machine_type = var.spot_machine_type
    image_type   = var.node_image_type
    
    disk_size_gb = var.node_disk_size
    disk_type    = var.node_disk_type
    
    # Spot實例
    spot = true
    
    service_account = google_service_account.gke_sa.email
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    tags = ["gke-node", "spot"]
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    labels = {
      environment = var.environment
      project     = var.project_name
      node_type   = "spot"
    }
  }
}

# 配置Kubernetes Provider
provider "kubernetes" {
  host  = "https://${google_container_cluster.gke_cluster.endpoint}"
  token = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate
  )
}

# 獲取當前客戶端配置
data "google_client_config" "current" {}

# 創建Kubernetes命名空間
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.app_namespace
    
    labels = {
      environment = var.environment
      project     = var.project_name
    }
  }
}

# 創建示例應用部署
resource "kubernetes_deployment" "nginx_deployment" {
  metadata {
    name      = "nginx-deployment"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    
    labels = {
      app = "nginx"
    }
  }
  
  spec {
    replicas = var.app_replicas
    
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      
      spec {
        container {
          name  = "nginx"
          image = "nginx:1.21"
          
          port {
            container_port = 80
          }
          
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
          
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          
          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# 創建服務
resource "kubernetes_service" "nginx_service" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }
  
  spec {
    selector = {
      app = "nginx"
    }
    
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    
    type = "ClusterIP"
  }
}

# 創建Ingress
resource "kubernetes_ingress" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    
    annotations = {
      "kubernetes.io/ingress.class"                = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.ingress_ip.name
    }
  }
  
  spec {
    rule {
      host = var.ingress_host
      
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          
          backend {
            service {
              name = kubernetes_service.nginx_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# 創建Ingress IP
resource "google_compute_global_address" "ingress_ip" {
  name = "${var.project_name}-ingress-ip"
}

# 創建ConfigMap
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }
  
  data = {
    environment = var.environment
    project     = var.project_name
    region      = var.region
  }
}

# 創建Secret
resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }
  
  data = {
    database_url = base64encode("postgresql://user:password@db:5432/mydb")
    api_key      = base64encode("your-api-key-here")
  }
  
  type = "Opaque"
}

# 創建HorizontalPodAutoscaler
resource "kubernetes_horizontal_pod_autoscaler" "nginx_hpa" {
  metadata {
    name      = "nginx-hpa"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }
  
  spec {
    max_replicas = var.hpa_max_replicas
    min_replicas = var.hpa_min_replicas
    
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.nginx_deployment.metadata[0].name
    }
    
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 50
        }
      }
    }
  }
}

# 創建PodDisruptionBudget
resource "kubernetes_pod_disruption_budget" "nginx_pdb" {
  metadata {
    name      = "nginx-pdb"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }
  
  spec {
    min_available = "50%"
    
    selector {
      match_labels = {
        app = "nginx"
      }
    }
  }
}
