# 第2章：VPC網路教學 - 成本優化版本 ($5預算)
# 本範例展示如何設計和實現複雜的VPC網路架構，但控制在$5預算內

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
}

# 創建主VPC網路
resource "google_compute_network" "main_vpc" {
  name                    = "${var.project_name}-main-vpc"
  auto_create_subnetworks = false
  description             = "Main VPC for ${var.project_name} with custom subnets (Budget Version)"
}

# 創建公共子網路 (DMZ) - 簡化版本
resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.project_name}-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.main_vpc.id
  
  # 啟用私有IP Google訪問
  private_ip_google_access = true
}

# 創建私有子網路 (應用層) - 簡化版本
resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.project_name}-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.main_vpc.id
  
  # 啟用私有IP Google訪問
  private_ip_google_access = true
}

# 創建數據庫子網路 (數據層) - 簡化版本
resource "google_compute_subnetwork" "database_subnet" {
  name          = "${var.project_name}-database-subnet"
  ip_cidr_range = var.database_subnet_cidr
  region        = var.region
  network       = google_compute_network.main_vpc.id
  
  # 啟用私有IP Google訪問
  private_ip_google_access = true
}

# 防火牆規則 - 允許SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["ssh"]
}

# 防火牆規則 - 允許HTTP/HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.project_name}-allow-http-https"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http", "https"]
}

# 防火牆規則 - 允許內部通信
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["1-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["1-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.public_subnet_cidr,
    var.private_subnet_cidr,
    var.database_subnet_cidr
  ]
}

# 防火牆規則 - 允許數據庫訪問
resource "google_compute_firewall" "allow_database" {
  name    = "${var.project_name}-allow-database"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3306", "5432", "6379"]
  }

  source_ranges = [var.private_subnet_cidr]
  target_tags   = ["database"]
}

# 創建Web服務器實例 (Public Subnet) - 只有1個實例
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
    echo "<h1>Hello from VPC Web Server!</h1>" > /var/www/html/index.html
    echo "<p>This is a budget-friendly VPC deployment.</p>" >> /var/www/html/index.html
  EOF

  # 網路介面
  network_interface {
    network    = google_compute_network.main_vpc.id
    subnetwork = google_compute_subnetwork.public_subnet.id

    # 分配外部IP
    access_config {
      // 自動分配外部IP
    }
  }

  # 啟動磁碟
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  # 標籤
  tags = ["ssh", "http", "https"]

  # 服務帳戶
  service_account {
    email  = google_service_account.web_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# 創建App服務器實例 (Private Subnet) - 只有1個實例
resource "google_compute_instance" "app_server" {
  name         = "${var.project_name}-app-server"
  machine_type = var.machine_type
  zone         = var.zone

  # 啟動腳本
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Hello from VPC App Server!</h1>" > /var/www/html/index.html
    echo "<p>This is a private app server in the VPC.</p>" >> /var/www/html/index.html
  EOF

  # 網路介面
  network_interface {
    network    = google_compute_network.main_vpc.id
    subnetwork = google_compute_subnetwork.private_subnet.id

    # 不分配外部IP (私有實例)
  }

  # 啟動磁碟
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  # 標籤
  tags = ["ssh"]

  # 服務帳戶
  service_account {
    email  = google_service_account.app_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# 創建Web服務器服務帳戶
resource "google_service_account" "web_sa" {
  account_id   = "${var.project_name}-web-sa"
  display_name = "Web Server Service Account for ${var.project_name}"
  description  = "Service account for web servers"
}

# 創建App服務器服務帳戶
resource "google_service_account" "app_sa" {
  account_id   = "${var.project_name}-app-sa"
  display_name = "App Server Service Account for ${var.project_name}"
  description  = "Service account for app servers"
}
