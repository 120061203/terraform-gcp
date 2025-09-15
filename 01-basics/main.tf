# 第1章：Terraform基礎教學
# 本範例展示Terraform的基本概念和GCP資源創建

# 配置Terraform版本要求
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# 配置Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 創建VPC網路
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  description             = "Main VPC for ${var.project_name}"
}

# 創建子網路
resource "google_compute_subnetwork" "main" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
  
  # 啟用私有IP Google訪問
  private_ip_google_access = true
}

# 創建防火牆規則 - 允許SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

# 創建防火牆規則 - 允許HTTP
resource "google_compute_firewall" "allow_http" {
  name    = "${var.project_name}-allow-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http"]
}

# 創建防火牆規則 - 允許HTTPS
resource "google_compute_firewall" "allow_https" {
  name    = "${var.project_name}-allow-https"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https"]
}

# 創建Compute Engine實例
resource "google_compute_instance" "web_server" {
  name         = "${var.project_name}-web-server"
  machine_type = var.machine_type
  zone         = var.zone

  # 啟動腳本
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
  EOF

  # 網路介面
  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.main.id

    # 分配外部IP
    access_config {
      // 自動分配外部IP
    }
  }

  # 啟動磁碟
  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  # 標籤
  tags = ["ssh", "http", "https"]

  # 服務帳戶
  service_account {
    email  = google_service_account.instance_sa.email
    scopes = ["cloud-platform"]
  }
}

# 創建服務帳戶
resource "google_service_account" "instance_sa" {
  account_id   = "${var.project_name}-instance-sa"
  display_name = "Instance Service Account for ${var.project_name}"
  description  = "Service account for Compute Engine instances"
}

# Storage Bucket 已移除以節省費用
# 如果需要Storage功能，請在完成基本學習後再添加

# 註釋掉的Storage資源：
# resource "google_storage_bucket" "data_bucket" {
#   name          = "${var.project_name}-data-bucket-${random_id.bucket_suffix.hex}"
#   location      = var.region
#   force_destroy = true
#   versioning { enabled = true }
#   lifecycle_rule {
#     condition { age = 30 }
#     action { type = "Delete" }
#   }
#   uniform_bucket_level_access = true
# }
# 
# resource "random_id" "bucket_suffix" {
#   byte_length = 4
# }
# 
# resource "google_storage_bucket_iam_binding" "bucket_public_read" {
#   bucket = google_storage_bucket.data_bucket.name
#   role   = "roles/storage.objectViewer"
#   members = ["allUsers"]
# }
