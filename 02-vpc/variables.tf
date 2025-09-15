# VPC網路教學變數定義

# 專案相關變數
variable "project_id" {
  description = "GCP專案ID"
  type        = string
}

variable "project_name" {
  description = "專案名稱前綴，用於資源命名"
  type        = string
  default     = "vpc-learning"
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

# 網路CIDR配置
variable "public_subnet_cidr" {
  description = "公共子網路CIDR區塊 (DMZ層)"
  type        = string
  default     = "10.0.1.0/24"
  
  validation {
    condition = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "public_subnet_cidr 必須是有效的CIDR格式"
  }
}

variable "private_subnet_cidr" {
  description = "私有子網路CIDR區塊 (應用層)"
  type        = string
  default     = "10.0.2.0/24"
  
  validation {
    condition = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "private_subnet_cidr 必須是有效的CIDR格式"
  }
}

variable "database_subnet_cidr" {
  description = "數據庫子網路CIDR區塊 (數據層)"
  type        = string
  default     = "10.0.3.0/24"
  
  validation {
    condition = can(cidrhost(var.database_subnet_cidr, 0))
    error_message = "database_subnet_cidr 必須是有效的CIDR格式"
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
      "e2-standard-4", "e2-standard-8", "e2-standard-16"
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

# 安全配置
variable "allowed_ssh_cidrs" {
  description = "允許SSH訪問的CIDR區塊列表"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition = length(var.allowed_ssh_cidrs) > 0
    error_message = "至少需要指定一個允許SSH訪問的CIDR區塊"
  }
}

variable "enable_nat" {
  description = "是否啟用Cloud NAT"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "是否啟用VPC流日誌"
  type        = bool
  default     = true
}

# 負載平衡器配置
variable "enable_load_balancer" {
  description = "是否啟用負載平衡器"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "健康檢查路徑"
  type        = string
  default     = "/health"
}

variable "health_check_port" {
  description = "健康檢查端口"
  type        = number
  default     = 80
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

variable "log_retention_days" {
  description = "日誌保留天數"
  type        = number
  default     = 30
  
  validation {
    condition = var.log_retention_days >= 1 && var.log_retention_days <= 365
    error_message = "日誌保留天數必須在1到365天之間"
  }
}

# 網路性能配置
variable "enable_private_ip_google_access" {
  description = "是否啟用私有IP Google訪問"
  type        = bool
  default     = true
}

variable "flow_sampling" {
  description = "VPC流日誌採樣率 (0.0-1.0)"
  type        = number
  default     = 0.5
  
  validation {
    condition = var.flow_sampling >= 0.0 && var.flow_sampling <= 1.0
    error_message = "流採樣率必須在0.0到1.0之間"
  }
}
