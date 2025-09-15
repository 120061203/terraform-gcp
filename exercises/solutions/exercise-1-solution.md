# 練習題 1 解答

## 解答說明

本解答展示了如何創建基本的GCP基礎設施，包括VPC、Compute Engine實例和Storage Bucket。

## 文件結構

```
exercise-1-solution/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── README.md
```

## 解答代碼

### main.tf

```hcl
# 練習題 1 解答 - 基礎GCP資源
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 創建VPC網路
resource "google_compute_network" "main" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "VPC for learning exercise"
}

# 創建子網路
resource "google_compute_subnetwork" "main" {
  name          = "${var.vpc_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
  
  private_ip_google_access = true
}

# 創建防火牆規則 - SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.vpc_name}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["ssh"]
  
  description = "Allow SSH access"
}

# 創建防火牆規則 - HTTP
resource "google_compute_firewall" "allow_http" {
  name    = "${var.vpc_name}-allow-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http"]
  
  description = "Allow HTTP access"
}

# 創建防火牆規則 - HTTPS
resource "google_compute_firewall" "allow_https" {
  name    = "${var.vpc_name}-allow-https"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https"]
  
  description = "Allow HTTPS access"
}

# 創建服務帳戶
resource "google_service_account" "instance_sa" {
  account_id   = "${var.project_name}-instance-sa"
  display_name = "Instance Service Account"
  description  = "Service account for Compute Engine instances"
}

# 創建Compute Engine實例
resource "google_compute_instance" "web_server" {
  name         = "${var.project_name}-web-server"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      // 自動分配外部IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Hello from Exercise 1!</h1>" > /var/www/html/index.html
  EOF

  service_account {
    email  = google_service_account.instance_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["ssh", "http", "https"]
  
  labels = {
    environment = var.environment
    project     = var.project_name
    exercise    = "exercise-1"
  }
}

# 創建Storage Bucket
resource "google_storage_bucket" "data_bucket" {
  name          = "${var.project_name}-data-bucket-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true
  
  labels = {
    environment = var.environment
    project     = var.project_name
    exercise    = "exercise-1"
  }
}

# 隨機ID用於bucket名稱唯一性
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

### variables.tf

```hcl
# 練習題 1 變數定義

# 專案相關變數
variable "project_id" {
  description = "GCP專案ID"
  type        = string
}

variable "project_name" {
  description = "專案名稱前綴"
  type        = string
  default     = "exercise-1"
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "專案名稱只能包含小寫字母、數字和連字符"
  }
}

variable "region" {
  description = "GCP區域"
  type        = string
  default     = "us-central1"
  
  validation {
    condition = can(regex("^[a-z]+-[a-z]+[0-9]+$", var.region))
    error_message = "區域格式必須符合 GCP 區域命名規範"
  }
}

variable "zone" {
  description = "GCP可用區"
  type        = string
  default     = "us-central1-a"
  
  validation {
    condition = can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", var.zone))
    error_message = "可用區格式必須符合 GCP 可用區命名規範"
  }
}

# 網路配置
variable "vpc_name" {
  description = "VPC網路名稱"
  type        = string
  default     = "my-learning-vpc"
}

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
  description = "磁碟大小（GB）"
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
```

### outputs.tf

```hcl
# 練習題 1 輸出定義

# 網路相關輸出
output "vpc_id" {
  description = "VPC網路ID"
  value       = google_compute_network.main.id
}

output "vpc_name" {
  description = "VPC網路名稱"
  value       = google_compute_network.main.name
}

output "subnet_id" {
  description = "子網路ID"
  value       = google_compute_subnetwork.main.id
}

output "subnet_cidr" {
  description = "子網路CIDR區塊"
  value       = google_compute_subnetwork.main.ip_cidr_range
}

# Compute Engine相關輸出
output "instance_id" {
  description = "虛擬機器實例ID"
  value       = google_compute_instance.web_server.id
}

output "instance_name" {
  description = "虛擬機器實例名稱"
  value       = google_compute_instance.web_server.name
}

output "instance_external_ip" {
  description = "虛擬機器外部IP地址"
  value       = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}

output "instance_internal_ip" {
  description = "虛擬機器內部IP地址"
  value       = google_compute_instance.web_server.network_interface[0].network_ip
}

# Storage相關輸出
output "bucket_name" {
  description = "Storage Bucket名稱"
  value       = google_storage_bucket.data_bucket.name
}

output "bucket_url" {
  description = "Storage Bucket URL"
  value       = google_storage_bucket.data_bucket.url
}

# 服務帳戶相關輸出
output "service_account_email" {
  description = "服務帳戶電子郵件"
  value       = google_service_account.instance_sa.email
}

# 連接信息輸出
output "ssh_command" {
  description = "SSH連接命令"
  value       = "gcloud compute ssh ${google_compute_instance.web_server.name} --zone=${google_compute_instance.web_server.zone}"
}

output "web_url" {
  description = "網站訪問URL"
  value       = "http://${google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip}"
}

# 資源摘要輸出
output "resource_summary" {
  description = "創建的資源摘要"
  value = {
    vpc_created        = true
    subnet_created     = true
    instance_created   = true
    bucket_created     = true
    firewalls_created  = 3
    total_resources    = 6
  }
}
```

### terraform.tfvars.example

```hcl
# 練習題 1 變數範例文件
# 複製此文件為 terraform.tfvars 並填入您的實際值

# 必要變數
project_id = "your-gcp-project-id"

# 可選變數
project_name = "exercise-1"
region      = "us-central1"
zone        = "us-central1-a"

# 網路配置
vpc_name    = "my-learning-vpc"
subnet_cidr = "10.0.1.0/24"

# Compute Engine配置
machine_type = "e2-micro"
image        = "ubuntu-os-cloud/ubuntu-2004-lts"
disk_size    = 20
disk_type    = "pd-standard"

# 安全配置
allowed_ssh_cidrs = ["0.0.0.0/0"]

# 環境標籤
environment = "learning"
```

### README.md

```markdown
# 練習題 1 解答

## 概述

本解答創建了基本的GCP基礎設施，包括：
- VPC網路和子網路
- 防火牆規則
- Compute Engine實例
- Cloud Storage Bucket

## 創建的資源

1. **VPC網路** (`google_compute_network`)
   - 自定義VPC網路
   - 不自動創建子網路

2. **子網路** (`google_compute_subnetwork`)
   - CIDR: 10.0.1.0/24
   - 啟用私有IP Google訪問

3. **防火牆規則** (`google_compute_firewall`)
   - SSH (port 22)
   - HTTP (port 80)
   - HTTPS (port 443)

4. **Compute Engine實例** (`google_compute_instance`)
   - e2-micro機器類型
   - Ubuntu 20.04 LTS
   - 自動安裝Nginx

5. **Storage Bucket** (`google_storage_bucket`)
   - 版本控制啟用
   - 7天後自動刪除

6. **服務帳戶** (`google_service_account`)
   - 實例身份驗證

## 使用方法

1. 複製 `terraform.tfvars.example` 為 `terraform.tfvars`
2. 編輯 `terraform.tfvars`，填入您的專案ID
3. 運行以下命令：

```bash
terraform init
terraform plan
terraform apply
```

## 測試

1. 獲取實例外部IP：
```bash
terraform output instance_external_ip
```

2. 訪問網站：
```bash
curl http://$(terraform output -raw instance_external_ip)
```

3. SSH到實例：
```bash
gcloud compute ssh $(terraform output -raw instance_name) --zone=$(terraform output -raw zone)
```

## 清理

```bash
terraform destroy
```

## 學習要點

1. **資源依賴**：子網路依賴VPC，實例依賴子網路
2. **變數使用**：提高代碼可重用性
3. **安全配置**：使用服務帳戶和防火牆規則
4. **標籤管理**：便於資源管理和計費
```

## 評分說明

### 優秀 (90-100分)
- 所有資源成功創建
- 代碼結構清晰，遵循最佳實踐
- 實施適當的安全措施
- 提供完整的文檔

### 良好 (80-89分)
- 大部分資源成功創建
- 代碼結構良好
- 基本安全措施到位
- 文檔基本完整

### 及格 (70-79分)
- 基本功能實現
- 代碼可以運行
- 安全措施基本到位
- 有基本文檔

### 不及格 (<70分)
- 資源創建失敗
- 代碼有明顯錯誤
- 缺乏安全措施
- 文檔不完整

## 常見錯誤

1. **資源名稱衝突**：使用隨機後綴確保唯一性
2. **變數未定義**：確保所有變數都有定義
3. **依賴關係錯誤**：注意資源間的依賴關係
4. **安全配置缺失**：不要忘記服務帳戶和防火牆規則

## 進階挑戰

完成基本要求後，可以嘗試：
1. 添加更多防火牆規則
2. 創建多個實例
3. 配置負載平衡器
4. 添加監控和日誌
