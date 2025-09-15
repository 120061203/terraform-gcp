# 第3章：Compute Engine教學
# 本範例展示Compute Engine的各種配置和最佳實踐

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
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  description             = "VPC for Compute Engine examples"
}

# 創建子網路
resource "google_compute_subnetwork" "main" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
  
  private_ip_google_access = true
}

# 創建防火牆規則
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "${var.project_name}-allow-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "allow_custom_ports" {
  name    = "${var.project_name}-allow-custom"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = var.custom_ports
  }

  source_ranges = var.allowed_custom_cidrs
  target_tags   = ["custom-app"]
}

# 創建服務帳戶
resource "google_service_account" "compute_sa" {
  account_id   = "${var.project_name}-compute-sa"
  display_name = "Compute Engine Service Account"
  description  = "Service account for Compute Engine instances"
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
    
    # 磁碟加密
    disk_encryption_key {
      kms_key_self_link = var.enable_disk_encryption ? google_kms_crypto_key.disk_key[0].id : null
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      // 自動分配外部IP
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup_script.sh", {
    project_name = var.project_name
    environment  = var.environment
  })

  service_account {
    email  = google_service_account.compute_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["web-server", "ssh"]

  lifecycle {
    create_before_destroy = true
  }
}

# 創建實例組管理器
resource "google_compute_instance_group_manager" "web_igm" {
  name = "${var.project_name}-web-igm"
  zone = var.zone

  version {
    instance_template = google_compute_instance_template.web_template.id
    name              = "primary"
  }

  base_instance_name = "${var.project_name}-web"
  target_size        = var.instance_count

  # 自動修復
  auto_healing_policies {
    health_check      = google_compute_health_check.web_health_check.id
    initial_delay_sec = 300
  }

  # 更新策略
  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action              = "REPLACE"
    max_surge_fixed             = 2
    max_unavailable_fixed       = 1
  }
}

# 創建健康檢查
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

# 創建自動擴展策略
resource "google_compute_autoscaler" "web_autoscaler" {
  name   = "${var.project_name}-web-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.web_igm.id

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }

    load_balancing_utilization {
      target = 0.8
    }
  }
}

# 創建負載平衡器
resource "google_compute_global_address" "lb_ip" {
  name = "${var.project_name}-lb-ip"
}

resource "google_compute_backend_service" "web_backend" {
  name        = "${var.project_name}-web-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10

  health_checks = [google_compute_health_check.web_health_check.id]

  backend {
    group = google_compute_instance_group_manager.web_igm.instance_group
  }

  # 會話親和性
  session_affinity = var.enable_session_affinity ? "CLIENT_IP" : "NONE"
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

# 創建單獨的實例（用於特殊用途）
resource "google_compute_instance" "special_instance" {
  count        = var.create_special_instance ? 1 : 0
  name         = "${var.project_name}-special-instance"
  machine_type = var.special_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.special_disk_size
      type  = var.special_disk_type
    }
  }

  # 額外的數據磁碟
  attached_disk {
    source      = google_compute_disk.data_disk[0].id
    device_name = "data-disk"
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
    
    # 掛載數據磁碟
    mkdir -p /mnt/data
    mount /dev/sdb1 /mnt/data
    echo "/dev/sdb1 /mnt/data ext4 defaults 0 0" >> /etc/fstab
    
    echo "<h1>Special Instance - Data Disk Mounted</h1>" > /var/www/html/index.html
    echo "<h1>Healthy</h1>" > /var/www/html/health
  EOF

  service_account {
    email  = google_service_account.compute_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["custom-app", "ssh"]

  depends_on = [google_compute_disk.data_disk]
}

# 創建數據磁碟
resource "google_compute_disk" "data_disk" {
  count = var.create_special_instance ? 1 : 0
  name  = "${var.project_name}-data-disk"
  type  = var.data_disk_type
  zone  = var.zone
  size  = var.data_disk_size

  # 磁碟加密
  disk_encryption_key {
    kms_key_self_link = var.enable_disk_encryption ? google_kms_crypto_key.disk_key[0].id : null
  }
}

# 創建預留實例（可選）
resource "google_compute_reservation" "reservation" {
  count = var.create_reservation ? 1 : 0
  name  = "${var.project_name}-reservation"
  zone  = var.zone

  specific_reservation {
    count = var.reservation_count
    instance_properties {
      machine_type     = var.machine_type
      min_cpu_platform = var.min_cpu_platform
    }
  }
}

# 創建KMS密鑰（用於磁碟加密）
resource "google_kms_key_ring" "disk_key_ring" {
  count    = var.enable_disk_encryption ? 1 : 0
  name     = "${var.project_name}-disk-key-ring"
  location = var.region
}

resource "google_kms_crypto_key" "disk_key" {
  count           = var.enable_disk_encryption ? 1 : 0
  name            = "${var.project_name}-disk-key"
  key_ring        = google_kms_key_ring.disk_key_ring[0].id
  rotation_period = "7776000s" # 90 days
}

# 創建監控和日誌
resource "google_logging_project_sink" "compute_logs" {
  count = var.enable_logging ? 1 : 0
  name  = "${var.project_name}-compute-logs"

  destination = "storage.googleapis.com/${google_storage_bucket.log_bucket[0].name}"

  filter = "resource.type=\"gce_instance\""
}

resource "google_storage_bucket" "log_bucket" {
  count    = var.enable_logging ? 1 : 0
  name     = "${var.project_name}-logs-${random_id.bucket_suffix[0].hex}"
  location = var.region

  lifecycle_rule {
    condition {
      age = var.log_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

resource "random_id" "bucket_suffix" {
  count       = var.enable_logging ? 1 : 0
  byte_length = 4
}

# 創建監控警報
resource "google_monitoring_alert_policy" "high_cpu" {
  count        = var.enable_monitoring ? 1 : 0
  display_name = "${var.project_name} High CPU Usage"
  combiner     = "OR"

  conditions {
    display_name = "High CPU usage"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels
}

# 創建快照策略
resource "google_compute_resource_policy" "snapshot_policy" {
  count = var.enable_snapshots ? 1 : 0
  name  = "${var.project_name}-snapshot-policy"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }
    retention_policy {
      max_retention_days = var.snapshot_retention_days
    }
    snapshot_properties {
      guest_flush = true
    }
  }
}
