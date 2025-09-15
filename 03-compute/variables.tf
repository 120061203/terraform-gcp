# Compute Engine教學變數定義

# 專案相關變數
variable "project_id" {
  description = "GCP專案ID"
  type        = string
}

variable "project_name" {
  description = "專案名稱前綴，用於資源命名"
  type        = string
  default     = "compute-learning"
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

# Compute Engine配置
variable "machine_type" {
  description = "虛擬機器類型"
  type        = string
  default     = "e2-micro"
  
  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium", "e2-standard-2", 
      "e2-standard-4", "e2-standard-8", "e2-standard-16",
      "n1-standard-1", "n1-standard-2", "n1-standard-4",
      "c2-standard-4", "c2-standard-8", "c2-standard-16"
    ], var.machine_type)
    error_message = "機器類型必須是有效的GCP機器類型"
  }
}

variable "image" {
  description = "虛擬機器映像"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2004-lts"
}

variable "disk_size" {
  description = "啟動磁碟大小（GB）"
  type        = number
  default     = 20
  
  validation {
    condition = var.disk_size >= 10 && var.disk_size <= 2000
    error_message = "磁碟大小必須在10GB到2000GB之間"
  }
}

variable "disk_type" {
  description = "磁碟類型"
  type        = string
  default     = "pd-standard"
  
  validation {
    condition = contains([
      "pd-standard", "pd-ssd", "pd-balanced", "pd-extreme"
    ], var.disk_type)
    error_message = "磁碟類型必須是有效的GCP磁碟類型"
  }
}

# 實例組配置
variable "instance_count" {
  description = "初始實例數量"
  type        = number
  default     = 2
  
  validation {
    condition = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "實例數量必須在1到10之間"
  }
}

variable "min_replicas" {
  description = "自動擴展最小實例數"
  type        = number
  default     = 1
  
  validation {
    condition = var.min_replicas >= 1
    error_message = "最小實例數必須至少為1"
  }
}

variable "max_replicas" {
  description = "自動擴展最大實例數"
  type        = number
  default     = 5
  
  validation {
    condition = var.max_replicas >= var.min_replicas
    error_message = "最大實例數必須大於等於最小實例數"
  }
}

# 特殊實例配置
variable "create_special_instance" {
  description = "是否創建特殊用途實例"
  type        = bool
  default     = false
}

variable "special_machine_type" {
  description = "特殊實例機器類型"
  type        = string
  default     = "e2-small"
}

variable "special_disk_size" {
  description = "特殊實例磁碟大小（GB）"
  type        = number
  default     = 30
}

variable "special_disk_type" {
  description = "特殊實例磁碟類型"
  type        = string
  default     = "pd-ssd"
}

# 數據磁碟配置
variable "data_disk_size" {
  description = "數據磁碟大小（GB）"
  type        = number
  default     = 50
  
  validation {
    condition = var.data_disk_size >= 10 && var.data_disk_size <= 2000
    error_message = "數據磁碟大小必須在10GB到2000GB之間"
  }
}

variable "data_disk_type" {
  description = "數據磁碟類型"
  type        = string
  default     = "pd-standard"
}

# 預留實例配置
variable "create_reservation" {
  description = "是否創建預留實例"
  type        = bool
  default     = false
}

variable "reservation_count" {
  description = "預留實例數量"
  type        = number
  default     = 1
  
  validation {
    condition = var.reservation_count >= 1 && var.reservation_count <= 10
    error_message = "預留實例數量必須在1到10之間"
  }
}

variable "min_cpu_platform" {
  description = "最小CPU平台"
  type        = string
  default     = "Intel Skylake"
}

# 安全配置
variable "allowed_ssh_cidrs" {
  description = "允許SSH訪問的CIDR區塊列表"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "custom_ports" {
  description = "自定義端口列表"
  type        = list(string)
  default     = ["8080", "9090"]
}

variable "allowed_custom_cidrs" {
  description = "允許自定義端口訪問的CIDR區塊"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# 加密配置
variable "enable_disk_encryption" {
  description = "是否啟用磁碟加密"
  type        = bool
  default     = false
}

# 負載平衡配置
variable "enable_session_affinity" {
  description = "是否啟用會話親和性"
  type        = bool
  default     = false
}

# 監控和日誌配置
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

variable "log_retention_days" {
  description = "日誌保留天數"
  type        = number
  default     = 30
  
  validation {
    condition = var.log_retention_days >= 1 && var.log_retention_days <= 365
    error_message = "日誌保留天數必須在1到365天之間"
  }
}

variable "notification_channels" {
  description = "監控通知頻道列表"
  type        = list(string)
  default     = []
}

# 快照配置
variable "enable_snapshots" {
  description = "是否啟用快照"
  type        = bool
  default     = false
}

variable "snapshot_retention_days" {
  description = "快照保留天數"
  type        = number
  default     = 7
  
  validation {
    condition = var.snapshot_retention_days >= 1 && var.snapshot_retention_days <= 365
    error_message = "快照保留天數必須在1到365天之間"
  }
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

# 性能配置
variable "enable_preemptible" {
  description = "是否使用可搶占實例"
  type        = bool
  default     = false
}

variable "enable_spot_instances" {
  description = "是否使用Spot實例"
  type        = bool
  default     = false
}
