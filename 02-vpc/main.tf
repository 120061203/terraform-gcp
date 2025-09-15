# 第2章：VPC網路教學
# 本範例展示如何設計和實現複雜的VPC網路架構

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
  description             = "Main VPC for ${var.project_name} with custom subnets"
  
  # 啟用UDP負載平衡日誌記錄
  enable_ula_internal_ipv6 = false
}

# 創建公共子網路 (DMZ)
resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.project_name}-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.main_vpc.id
  
  # 啟用私有IP Google訪問
  private_ip_google_access = true
  
  # 日誌配置
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

# 創建私有子網路 (應用層)
resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.project_name}-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.main_vpc.id
  
  # 啟用私有IP Google訪問
  private_ip_google_access = true
  
  # 日誌配置
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

# 創建數據庫子網路 (數據層)
resource "google_compute_subnetwork" "database_subnet" {
  name          = "${var.project_name}-database-subnet"
  ip_cidr_range = var.database_subnet_cidr
  region        = var.region
  network       = google_compute_network.main_vpc.id
  
  # 啟用私有IP Google訪問
  private_ip_google_access = true
  
  # 日誌配置
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

# 創建Cloud NAT (用於私有子網路的出站連接)
resource "google_compute_router" "nat_router" {
  name    = "${var.project_name}-nat-router"
  region  = var.region
  network = google_compute_network.main_vpc.id
  
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_name}-nat"
  router                            = google_compute_router.nat_router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# 防火牆規則 - 允許SSH (僅從特定IP)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["ssh"]
  
  description = "Allow SSH access from specified IP ranges"
}

# 防火牆規則 - 允許HTTP/HTTPS (公共訪問)
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.project_name}-allow-http-https"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  
  description = "Allow HTTP and HTTPS traffic"
}

# 防火牆規則 - 允許內部通信
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.public_subnet_cidr,
    var.private_subnet_cidr,
    var.database_subnet_cidr
  ]
  
  target_tags = ["internal"]
  
  description = "Allow internal communication between subnets"
}

# 防火牆規則 - 允許數據庫訪問 (僅從應用層)
resource "google_compute_firewall" "allow_database" {
  name    = "${var.project_name}-allow-database"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3306", "5432", "6379"]  # MySQL, PostgreSQL, Redis
  }

  source_ranges = [var.private_subnet_cidr]
  target_tags   = ["database"]
  
  description = "Allow database access from application layer"
}

# 防火牆規則 - 拒絕所有其他流量
resource "google_compute_firewall" "deny_all" {
  name    = "${var.project_name}-deny-all"
  network = google_compute_network.main_vpc.name

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["deny-all"]
  
  description = "Deny all other traffic"
  
  priority = 65534
}

# 創建負載平衡器 (HTTP)
resource "google_compute_global_address" "lb_ip" {
  name = "${var.project_name}-lb-ip"
}

resource "google_compute_health_check" "web_health_check" {
  name = "${var.project_name}-web-health-check"

  http_health_check {
    port         = 80
    request_path = "/health"
  }

  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

resource "google_compute_backend_service" "web_backend" {
  name        = "${var.project_name}-web-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10

  health_checks = [google_compute_health_check.web_health_check.id]

  backend {
    group = google_compute_instance_group.web_servers.id
  }
}

resource "google_compute_url_map" "web_url_map" {
  name            = "${var.project_name}-web-url-map"
  default_service = google_compute_backend_service.web_backend.id
}

resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "${var.project_name}-web-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name       = "${var.project_name}-web-forwarding-rule"
  target     = google_compute_target_http_proxy.web_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.lb_ip.address
}

# 創建實例模板
resource "google_compute_instance_template" "web_template" {
  name_prefix  = "${var.project_name}-web-template-"
  machine_type  = var.machine_type
  region        = var.region

  disk {
    source_image = var.image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size
    disk_type    = var.disk_type
  }

  network_interface {
    network    = google_compute_network.main_vpc.id
    subnetwork = google_compute_subnetwork.public_subnet.id

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
    
    # 創建健康檢查端點
    echo "<h1>Healthy</h1>" > /var/www/html/health
    echo "<h1>Hello from Terraform VPC!</h1>" > /var/www/html/index.html
  EOF

  service_account {
    email  = google_service_account.web_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["web-server", "ssh"]

  lifecycle {
    create_before_destroy = true
  }
}

# 創建實例組
resource "google_compute_instance_group" "web_servers" {
  name        = "${var.project_name}-web-servers"
  description = "Web servers instance group"
  zone        = var.zone

  instances = [
    google_compute_instance.web_server_1.id,
    google_compute_instance.web_server_2.id
  ]

  named_port {
    name = "http"
    port = 80
  }
}

# 創建Web服務器實例
resource "google_compute_instance" "web_server_1" {
  name         = "${var.project_name}-web-server-1"
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
    network    = google_compute_network.main_vpc.id
    subnetwork = google_compute_subnetwork.public_subnet.id

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
    echo "<h1>Web Server 1 - Hello from Terraform VPC!</h1>" > /var/www/html/index.html
    echo "<h1>Healthy</h1>" > /var/www/html/health
  EOF

  service_account {
    email  = google_service_account.web_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["web-server", "ssh"]
}

resource "google_compute_instance" "web_server_2" {
  name         = "${var.project_name}-web-server-2"
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
    network    = google_compute_network.main_vpc.id
    subnetwork = google_compute_subnetwork.public_subnet.id

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
    echo "<h1>Web Server 2 - Hello from Terraform VPC!</h1>" > /var/www/html/index.html
    echo "<h1>Healthy</h1>" > /var/www/html/health
  EOF

  service_account {
    email  = google_service_account.web_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["web-server", "ssh"]
}

# 創建應用服務器 (私有子網路)
resource "google_compute_instance" "app_server" {
  name         = "${var.project_name}-app-server"
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
    network    = google_compute_network.main_vpc.id
    subnetwork = google_compute_subnetwork.private_subnet.id
    # 沒有access_config，所以沒有外部IP
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>App Server - Private Subnet</h1>" > /var/www/html/index.html
  EOF

  service_account {
    email  = google_service_account.app_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["internal", "app-server"]
}

# 創建服務帳戶
resource "google_service_account" "web_sa" {
  account_id   = "${var.project_name}-web-sa"
  display_name = "Web Server Service Account"
  description  = "Service account for web servers"
}

resource "google_service_account" "app_sa" {
  account_id   = "${var.project_name}-app-sa"
  display_name = "App Server Service Account"
  description  = "Service account for application servers"
}
