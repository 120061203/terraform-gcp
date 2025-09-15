# Cloud SQL教學變數定義

# 專案相關變數
variable "project_id" {
  description = "GCP專案ID"
  type        = string
}

variable "project_name" {
  description = "專案名稱前綴，用於資源命名"
  type        = string
  default     = "database-learning"
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

# PostgreSQL配置
variable "postgres_version" {
  description = "PostgreSQL版本"
  type        = string
  default     = "POSTGRES_14"
  
  validation {
    condition = contains([
      "POSTGRES_13", "POSTGRES_14", "POSTGRES_15", "POSTGRES_16"
    ], var.postgres_version)
    error_message = "PostgreSQL版本必須是有效的版本"
  }
}

variable "postgres_tier" {
  description = "PostgreSQL機器類型"
  type        = string
  default     = "db-f1-micro"
  
  validation {
    condition = contains([
      "db-f1-micro", "db-g1-small", "db-n1-standard-1", "db-n1-standard-2",
      "db-n1-standard-4", "db-n1-standard-8", "db-n1-standard-16",
      "db-n1-standard-32", "db-n1-standard-64", "db-n1-highmem-2",
      "db-n1-highmem-4", "db-n1-highmem-8", "db-n1-highmem-16",
      "db-n1-highmem-32", "db-n1-highmem-64"
    ], var.postgres_tier)
    error_message = "PostgreSQL機器類型必須是有效的Cloud SQL機器類型"
  }
}

variable "postgres_availability_type" {
  description = "PostgreSQL可用性類型"
  type        = string
  default     = "ZONAL"
  
  validation {
    condition = contains(["ZONAL", "REGIONAL"], var.postgres_availability_type)
    error_message = "可用性類型必須是 ZONAL 或 REGIONAL"
  }
}

variable "postgres_disk_type" {
  description = "PostgreSQL磁碟類型"
  type        = string
  default     = "PD_SSD"
  
  validation {
    condition = contains(["PD_SSD", "PD_STANDARD"], var.postgres_disk_type)
    error_message = "磁碟類型必須是 PD_SSD 或 PD_STANDARD"
  }
}

variable "postgres_disk_size" {
  description = "PostgreSQL磁碟大小（GB）"
  type        = number
  default     = 20
  
  validation {
    condition = var.postgres_disk_size >= 10 && var.postgres_disk_size <= 65536
    error_message = "磁碟大小必須在10GB到65536GB之間"
  }
}

variable "postgres_max_disk_size" {
  description = "PostgreSQL最大磁碟大小（GB）"
  type        = number
  default     = 100
  
  validation {
    condition = var.postgres_max_disk_size >= var.postgres_disk_size
    error_message = "最大磁碟大小必須大於等於初始磁碟大小"
  }
}

variable "postgres_database_name" {
  description = "PostgreSQL數據庫名稱"
  type        = string
  default     = "mydb"
}

variable "postgres_username" {
  description = "PostgreSQL用戶名"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "PostgreSQL密碼"
  type        = string
  sensitive   = true
}

# MySQL配置
variable "enable_mysql" {
  description = "是否啟用MySQL"
  type        = bool
  default     = false
}

variable "mysql_version" {
  description = "MySQL版本"
  type        = string
  default     = "MYSQL_8_0"
  
  validation {
    condition = contains([
      "MYSQL_5_7", "MYSQL_8_0"
    ], var.mysql_version)
    error_message = "MySQL版本必須是有效的版本"
  }
}

variable "mysql_tier" {
  description = "MySQL機器類型"
  type        = string
  default     = "db-f1-micro"
}

variable "mysql_availability_type" {
  description = "MySQL可用性類型"
  type        = string
  default     = "ZONAL"
}

variable "mysql_disk_type" {
  description = "MySQL磁碟類型"
  type        = string
  default     = "PD_SSD"
}

variable "mysql_disk_size" {
  description = "MySQL磁碟大小（GB）"
  type        = number
  default     = 20
}

variable "mysql_max_disk_size" {
  description = "MySQL最大磁碟大小（GB）"
  type        = number
  default     = 100
}

variable "mysql_database_name" {
  description = "MySQL數據庫名稱"
  type        = string
  default     = "mydb"
}

variable "mysql_username" {
  description = "MySQL用戶名"
  type        = string
  default     = "root"
}

variable "mysql_password" {
  description = "MySQL密碼"
  type        = string
  sensitive   = true
}

# SQL Server配置
variable "enable_sqlserver" {
  description = "是否啟用SQL Server"
  type        = bool
  default     = false
}

variable "sqlserver_version" {
  description = "SQL Server版本"
  type        = string
  default     = "SQLSERVER_2019_STANDARD"
  
  validation {
    condition = contains([
      "SQLSERVER_2017_STANDARD", "SQLSERVER_2017_ENTERPRISE",
      "SQLSERVER_2019_STANDARD", "SQLSERVER_2019_ENTERPRISE",
      "SQLSERVER_2022_STANDARD", "SQLSERVER_2022_ENTERPRISE"
    ], var.sqlserver_version)
    error_message = "SQL Server版本必須是有效的版本"
  }
}

variable "sqlserver_tier" {
  description = "SQL Server機器類型"
  type        = string
  default     = "db-custom-1-3840"
}

variable "sqlserver_availability_type" {
  description = "SQL Server可用性類型"
  type        = string
  default     = "ZONAL"
}

variable "sqlserver_disk_type" {
  description = "SQL Server磁碟類型"
  type        = string
  default     = "PD_SSD"
}

variable "sqlserver_disk_size" {
  description = "SQL Server磁碟大小（GB）"
  type        = number
  default     = 20
}

variable "sqlserver_max_disk_size" {
  description = "SQL Server最大磁碟大小（GB）"
  type        = number
  default     = 100
}

variable "sqlserver_database_name" {
  description = "SQL Server數據庫名稱"
  type        = string
  default     = "mydb"
}

variable "sqlserver_username" {
  description = "SQL Server用戶名"
  type        = string
  default     = "sqlserver"
}

variable "sqlserver_password" {
  description = "SQL Server密碼"
  type        = string
  sensitive   = true
}

# 讀取副本配置
variable "enable_read_replica" {
  description = "是否啟用讀取副本"
  type        = bool
  default     = false
}

# SQL代理配置
variable "enable_sql_proxy" {
  description = "是否啟用SQL代理實例"
  type        = bool
  default     = false
}

variable "proxy_machine_type" {
  description = "代理實例機器類型"
  type        = string
  default     = "e2-micro"
}

variable "proxy_image" {
  description = "代理實例映像"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2004-lts"
}

variable "proxy_disk_size" {
  description = "代理實例磁碟大小（GB）"
  type        = number
  default     = 20
}

variable "proxy_disk_type" {
  description = "代理實例磁碟類型"
  type        = string
  default     = "pd-standard"
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
