# GKE教學變數定義

# 專案相關變數
variable "project_id" {
  description = "GCP專案ID"
  type        = string
}

variable "project_name" {
  description = "專案名稱前綴，用於資源命名"
  type        = string
  default     = "gke-learning"
}

variable "region" {
  description = "GCP區域"
  type        = string
  default     = "asia-east1"
  
  validation {
    condition = can(regex("^[a-z]+-[a-z]+[0-9]+$", var.region))
    error_message = "區域格式必須符合 GCP 區域命名規範"
  }
}

variable "zone" {
  description = "GCP可用區"
  type        = string
  default     = "asia-east1-a"
  
  validation {
    condition = can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", var.zone))
    error_message = "可用區格式必須符合 GCP 可用區命名規範"
  }
}

# 網路配置
variable "subnet_cidr" {
  description = "子網路CIDR區塊"
  type        = string
  default     = "10.0.1.0/24"
  
  validation {
    condition = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr 必須是有效的CIDR格式"
  }
}

variable "pods_cidr" {
  description = "Pod CIDR區塊"
  type        = string
  default     = "10.1.0.0/16"
  
  validation {
    condition = can(cidrhost(var.pods_cidr, 0))
    error_message = "pods_cidr 必須是有效的CIDR格式"
  }
}

variable "services_cidr" {
  description = "服務CIDR區塊"
  type        = string
  default     = "10.2.0.0/20"
  
  validation {
    condition = can(cidrhost(var.services_cidr, 0))
    error_message = "services_cidr 必須是有效的CIDR格式"
  }
}

variable "cluster_cidr" {
  description = "集群CIDR區塊"
  type        = string
  default     = "10.3.0.0/16"
  
  validation {
    condition = can(cidrhost(var.cluster_cidr, 0))
    error_message = "cluster_cidr 必須是有效的CIDR格式"
  }
}

variable "master_cidr" {
  description = "主節點CIDR區塊"
  type        = string
  default     = "172.16.0.0/28"
  
  validation {
    condition = can(cidrhost(var.master_cidr, 0))
    error_message = "master_cidr 必須是有效的CIDR格式"
  }
}

# GKE集群配置
variable "kubernetes_version" {
  description = "Kubernetes版本"
  type        = string
  default     = "1.27"
  
  validation {
    condition = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Kubernetes版本格式必須為 X.Y"
  }
}

variable "release_channel" {
  description = "GKE發布頻道"
  type        = string
  default     = "REGULAR"
  
  validation {
    condition = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "發布頻道必須是 RAPID, REGULAR, 或 STABLE 之一"
  }
}

# 節點池配置
variable "node_count" {
  description = "初始節點數量"
  type        = number
  default     = 2
  
  validation {
    condition = var.node_count >= 1 && var.node_count <= 10
    error_message = "節點數量必須在1到10之間"
  }
}

variable "min_node_count" {
  description = "最小節點數量"
  type        = number
  default     = 1
  
  validation {
    condition = var.min_node_count >= 1
    error_message = "最小節點數量必須至少為1"
  }
}

variable "max_node_count" {
  description = "最大節點數量"
  type        = number
  default     = 5
  
  validation {
    condition = var.max_node_count >= var.min_node_count
    error_message = "最大節點數量必須大於等於最小節點數量"
  }
}

variable "node_machine_type" {
  description = "節點機器類型"
  type        = string
  default     = "e2-medium"
  
  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium", "e2-standard-2", 
      "e2-standard-4", "e2-standard-8", "e2-standard-16",
      "n1-standard-1", "n1-standard-2", "n1-standard-4",
      "c2-standard-4", "c2-standard-8", "c2-standard-16"
    ], var.node_machine_type)
    error_message = "節點機器類型必須是有效的GCP機器類型"
  }
}

variable "node_image_type" {
  description = "節點映像類型"
  type        = string
  default     = "COS_CONTAINERD"
  
  validation {
    condition = contains([
      "COS", "COS_CONTAINERD", "UBUNTU", "UBUNTU_CONTAINERD",
      "WINDOWS_SAC", "WINDOWS_LTSC"
    ], var.node_image_type)
    error_message = "節點映像類型必須是有效的GKE映像類型"
  }
}

variable "node_disk_size" {
  description = "節點磁碟大小（GB）"
  type        = number
  default     = 50
  
  validation {
    condition = var.node_disk_size >= 20 && var.node_disk_size <= 2000
    error_message = "節點磁碟大小必須在20GB到2000GB之間"
  }
}

variable "node_disk_type" {
  description = "節點磁碟類型"
  type        = string
  default     = "pd-standard"
  
  validation {
    condition = contains([
      "pd-standard", "pd-ssd", "pd-balanced", "pd-extreme"
    ], var.node_disk_type)
    error_message = "節點磁碟類型必須是有效的GCP磁碟類型"
  }
}

# Spot節點配置
variable "enable_spot_nodes" {
  description = "是否啟用Spot節點"
  type        = bool
  default     = false
}

variable "max_spot_nodes" {
  description = "最大Spot節點數量"
  type        = number
  default     = 3
  
  validation {
    condition = var.max_spot_nodes >= 0 && var.max_spot_nodes <= 10
    error_message = "最大Spot節點數量必須在0到10之間"
  }
}

variable "spot_machine_type" {
  description = "Spot節點機器類型"
  type        = string
  default     = "e2-small"
}

# 預留實例配置
variable "enable_preemptible_nodes" {
  description = "是否啟用預留實例節點"
  type        = bool
  default     = false
}

# 節點污點配置
variable "node_taints" {
  description = "節點污點列表"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# 應用配置
variable "app_namespace" {
  description = "應用命名空間"
  type        = string
  default     = "default"
}

variable "app_replicas" {
  description = "應用副本數量"
  type        = number
  default     = 2
  
  validation {
    condition = var.app_replicas >= 1 && var.app_replicas <= 10
    error_message = "應用副本數量必須在1到10之間"
  }
}

# HPA配置
variable "hpa_min_replicas" {
  description = "HPA最小副本數量"
  type        = number
  default     = 1
  
  validation {
    condition = var.hpa_min_replicas >= 1
    error_message = "HPA最小副本數量必須至少為1"
  }
}

variable "hpa_max_replicas" {
  description = "HPA最大副本數量"
  type        = number
  default     = 10
  
  validation {
    condition = var.hpa_max_replicas >= var.hpa_min_replicas
    error_message = "HPA最大副本數量必須大於等於最小副本數量"
  }
}

# Ingress配置
variable "ingress_host" {
  description = "Ingress主機名"
  type        = string
  default     = "gke-learning.example.com"
}

# 安全配置
variable "allowed_ssh_cidrs" {
  description = "允許SSH訪問的CIDR區塊列表"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# 環境標籤
variable "environment" {
  description = "環境標籤"
  type        = string
  default     = "learning"
  
  validation {
    condition = contains(["dev", "staging", "prod", "learning"], var.environment)
    error_message = "環境必須是 dev, staging, prod, 或 learning 之一"
  }
}

variable "owner" {
  description = "資源擁有者標籤"
  type        = string
  default     = "terraform-student"
}

# 成本控制
variable "enable_deletion_protection" {
  description = "是否啟用刪除保護"
  type        = bool
  default     = false
}

# 監控配置
variable "enable_monitoring" {
  description = "是否啟用監控"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "是否啟用日誌"
  type        = bool
  default     = true
}

# 網路策略配置
variable "enable_network_policy" {
  description = "是否啟用網路策略"
  type        = bool
  default     = true
}

# 工作負載身份配置
variable "enable_workload_identity" {
  description = "是否啟用工作負載身份"
  type        = bool
  default     = true
}
