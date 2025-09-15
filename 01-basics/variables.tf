# 變數定義文件
# 定義所有可配置的變數及其預設值和描述

# 專案相關變數
variable "project_id" {
  description = "GCP專案ID"
  type        = string
  # 必須提供，無預設值
}

variable "project_name" {
  description = "專案名稱前綴，用於資源命名"
  type        = string
  default     = "terraform-learning"
}

# 地理位置變數
variable "region" {
  description = "GCP區域"
  type        = string
  default     = "asia-east1"
  
  validation {
    condition = can(regex("^[a-z]+-[a-z]+[0-9]+$", var.region))
    error_message = "區域格式必須符合 GCP 區域命名規範，例如：asia-east1, us-central1"
  }
}

variable "zone" {
  description = "GCP可用區"
  type        = string
  default     = "asia-east1-a"
  
  validation {
    condition = can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", var.zone))
    error_message = "可用區格式必須符合 GCP 可用區命名規範，例如：asia-east1-a, us-central1-a"
  }
}

# 網路配置變數
variable "subnet_cidr" {
  description = "子網路CIDR區塊"
  type        = string
  default     = "10.0.1.0/24"
  
  validation {
    condition = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr 必須是有效的CIDR格式"
  }
}

# Compute Engine配置變數
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

# 標籤變數
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

# 成本控制變數
variable "enable_external_ip" {
  description = "是否為實例分配外部IP"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "是否啟用刪除保護"
  type        = bool
  default     = false
}

# 安全相關變數
variable "allowed_ssh_cidrs" {
  description = "允許SSH訪問的CIDR區塊列表"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition = length(var.allowed_ssh_cidrs) > 0
    error_message = "至少需要指定一個允許SSH訪問的CIDR區塊"
  }
}

variable "allowed_http_cidrs" {
  description = "允許HTTP訪問的CIDR區塊列表"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# 監控和日誌變數
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
