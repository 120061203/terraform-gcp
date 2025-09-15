# 第5章：Cloud SQL教學
# 本範例展示如何創建和管理Cloud SQL實例

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
resource "google_compute_network" "database_network" {
  name                    = "${var.project_name}-database-network"
  auto_create_subnetworks = false
  description             = "VPC network for Cloud SQL instances"
}

# 創建子網路
resource "google_compute_subnetwork" "database_subnet" {
  name          = "${var.project_name}-database-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.database_network.id
  
  private_ip_google_access = true
}

# 創建私有服務連接
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "${var.project_name}-private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.database_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.database_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

# 創建Cloud NAT
resource "google_compute_router" "database_router" {
  name    = "${var.project_name}-database-router"
  region  = var.region
  network = google_compute_network.database_network.id
  
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "database_nat" {
  name                               = "${var.project_name}-database-nat"
  router                            = google_compute_router.database_router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# 創建防火牆規則
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-database-allow-ssh"
  network = google_compute_network.database_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["database-client"]
}

# 創建服務帳戶
resource "google_service_account" "database_sa" {
  account_id   = "${var.project_name}-database-sa"
  display_name = "Database Service Account"
  description  = "Service account for database operations"
}

# 分配必要權限
resource "google_project_iam_member" "database_sa_sql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.database_sa.email}"
}

resource "google_project_iam_member" "database_sa_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.database_sa.email}"
}

# 創建KMS密鑰環
resource "google_kms_key_ring" "database_key_ring" {
  name     = "${var.project_name}-database-key-ring"
  location = var.region
}

resource "google_kms_crypto_key" "database_key" {
  name            = "${var.project_name}-database-key"
  key_ring        = google_kms_key_ring.database_key_ring.id
  rotation_period = "7776000s" # 90 days
  
  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }
}

# 分配KMS權限
resource "google_kms_crypto_key_iam_member" "database_sa_kms" {
  crypto_key_id = google_kms_crypto_key.database_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudsql.iam.gserviceaccount.com"
}

# 獲取專案信息
data "google_project" "current" {
  project_id = var.project_id
}

# 創建Cloud SQL實例 (PostgreSQL)
resource "google_sql_database_instance" "postgres_instance" {
  name             = "${var.project_name}-postgres-instance"
  database_version = var.postgres_version
  region           = var.region
  
  # 刪除保護
  deletion_protection = var.enable_deletion_protection
  
  # 設置標籤
  settings {
    # 機器類型
    tier = var.postgres_tier
    
    # 可用性類型
    availability_type = var.postgres_availability_type
    
    # 磁碟配置
    disk_type = var.postgres_disk_type
    disk_size = var.postgres_disk_size
    disk_autoresize {
      enabled = true
      max_disk_size = var.postgres_max_disk_size
    }
    
    # 備份配置
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }
    
    # 維護窗口
    maintenance_window {
      day          = 7  # Sunday
      hour         = 3
      update_track = "stable"
    }
    
    # IP配置
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.database_network.id
      enable_private_path_for_google_cloud_services = true
      require_ssl                                   = true
    }
    
    # 數據庫標誌
    database_flags {
      name  = "log_statement"
      value = "all"
    }
    
    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"
    }
    
    # 用戶標籤
    user_labels = {
      environment = var.environment
      project     = var.project_name
      database    = "postgresql"
    }
  }
  
  # 加密配置
  encryption_key_name = google_kms_crypto_key.database_key.id
  
  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_kms_crypto_key_iam_member.database_sa_kms
  ]
}

# 創建PostgreSQL數據庫
resource "google_sql_database" "postgres_database" {
  name     = var.postgres_database_name
  instance = google_sql_database_instance.postgres_instance.name
}

# 創建PostgreSQL用戶
resource "google_sql_user" "postgres_user" {
  name     = var.postgres_username
  instance = google_sql_database_instance.postgres_instance.name
  password = var.postgres_password
  
  deletion_policy = "ABANDON"
}

# 創建Cloud SQL實例 (MySQL)
resource "google_sql_database_instance" "mysql_instance" {
  count            = var.enable_mysql ? 1 : 0
  name             = "${var.project_name}-mysql-instance"
  database_version = var.mysql_version
  region           = var.region
  
  deletion_protection = var.enable_deletion_protection
  
  settings {
    tier = var.mysql_tier
    
    availability_type = var.mysql_availability_type
    
    disk_type = var.mysql_disk_type
    disk_size = var.mysql_disk_size
    disk_autoresize {
      enabled = true
      max_disk_size = var.mysql_max_disk_size
    }
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }
    
    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }
    
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.database_network.id
      enable_private_path_for_google_cloud_services = true
      require_ssl                                   = true
    }
    
    database_flags {
      name  = "slow_query_log"
      value = "on"
    }
    
    database_flags {
      name  = "long_query_time"
      value = "2"
    }
    
    user_labels = {
      environment = var.environment
      project     = var.project_name
      database    = "mysql"
    }
  }
  
  encryption_key_name = google_kms_crypto_key.database_key.id
  
  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_kms_crypto_key_iam_member.database_sa_kms
  ]
}

# 創建MySQL數據庫
resource "google_sql_database" "mysql_database" {
  count    = var.enable_mysql ? 1 : 0
  name     = var.mysql_database_name
  instance = google_sql_database_instance.mysql_instance[0].name
}

# 創建MySQL用戶
resource "google_sql_user" "mysql_user" {
  count    = var.enable_mysql ? 1 : 0
  name     = var.mysql_username
  instance = google_sql_database_instance.mysql_instance[0].name
  password = var.mysql_password
  
  deletion_policy = "ABANDON"
}

# 創建Cloud SQL實例 (SQL Server)
resource "google_sql_database_instance" "sqlserver_instance" {
  count            = var.enable_sqlserver ? 1 : 0
  name             = "${var.project_name}-sqlserver-instance"
  database_version = var.sqlserver_version
  region           = var.region
  
  deletion_protection = var.enable_deletion_protection
  
  settings {
    tier = var.sqlserver_tier
    
    availability_type = var.sqlserver_availability_type
    
    disk_type = var.sqlserver_disk_type
    disk_size = var.sqlserver_disk_size
    disk_autoresize {
      enabled = true
      max_disk_size = var.sqlserver_max_disk_size
    }
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }
    
    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }
    
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.database_network.id
      enable_private_path_for_google_cloud_services = true
      require_ssl                                   = true
    }
    
    user_labels = {
      environment = var.environment
      project     = var.project_name
      database    = "sqlserver"
    }
  }
  
  encryption_key_name = google_kms_crypto_key.database_key.id
  
  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_kms_crypto_key_iam_member.database_sa_kms
  ]
}

# 創建SQL Server數據庫
resource "google_sql_database" "sqlserver_database" {
  count    = var.enable_sqlserver ? 1 : 0
  name     = var.sqlserver_database_name
  instance = google_sql_database_instance.sqlserver_instance[0].name
}

# 創建SQL Server用戶
resource "google_sql_user" "sqlserver_user" {
  count    = var.enable_sqlserver ? 1 : 0
  name     = var.sqlserver_username
  instance = google_sql_database_instance.sqlserver_instance[0].name
  password = var.sqlserver_password
  
  deletion_policy = "ABANDON"
}

# 創建讀取副本 (PostgreSQL)
resource "google_sql_database_instance" "postgres_read_replica" {
  count            = var.enable_read_replica ? 1 : 0
  name             = "${var.project_name}-postgres-read-replica"
  master_instance_name = google_sql_database_instance.postgres_instance.name
  region           = var.region
  
  replica_configuration {
    failover_target = false
  }
  
  settings {
    tier = var.postgres_tier
    
    disk_type = var.postgres_disk_type
    disk_size = var.postgres_disk_size
    
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.database_network.id
      enable_private_path_for_google_cloud_services = true
      require_ssl                                   = true
    }
    
    user_labels = {
      environment = var.environment
      project     = var.project_name
      database    = "postgresql"
      role        = "read-replica"
    }
  }
  
  encryption_key_name = google_kms_crypto_key.database_key.id
  
  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_kms_crypto_key_iam_member.database_sa_kms
  ]
}

# 創建Cloud SQL代理實例
resource "google_compute_instance" "sql_proxy" {
  count        = var.enable_sql_proxy ? 1 : 0
  name         = "${var.project_name}-sql-proxy"
  machine_type = var.proxy_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.proxy_image
      size  = var.proxy_disk_size
      type  = var.proxy_disk_type
    }
  }

  network_interface {
    network    = google_compute_network.database_network.id
    subnetwork = google_compute_subnetwork.database_subnet.id
  }

  metadata_startup_script = templatefile("${path.module}/sql_proxy_startup.sh", {
    project_id = var.project_id
    postgres_instance = google_sql_database_instance.postgres_instance.name
    mysql_instance = var.enable_mysql ? google_sql_database_instance.mysql_instance[0].name : ""
    sqlserver_instance = var.enable_sqlserver ? google_sql_database_instance.sqlserver_instance[0].name : ""
  })

  service_account {
    email  = google_service_account.database_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["database-client", "sql-proxy"]
}

# 創建監控警報
resource "google_monitoring_alert_policy" "database_cpu_alert" {
  count        = var.enable_monitoring ? 1 : 0
  display_name = "${var.project_name} Database High CPU Usage"
  combiner     = "OR"

  conditions {
    display_name = "High CPU usage"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND resource.label.instance_name=\"${google_sql_database_instance.postgres_instance.name}\""
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

resource "google_monitoring_alert_policy" "database_disk_alert" {
  count        = var.enable_monitoring ? 1 : 0
  display_name = "${var.project_name} Database High Disk Usage"
  combiner     = "OR"

  conditions {
    display_name = "High disk usage"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND resource.label.instance_name=\"${google_sql_database_instance.postgres_instance.name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.9
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels
}

# 創建日誌接收器
resource "google_logging_project_sink" "database_logs" {
  count = var.enable_logging ? 1 : 0
  name  = "${var.project_name}-database-logs"

  destination = "storage.googleapis.com/${google_storage_bucket.database_log_bucket[0].name}"

  filter = "resource.type=\"gce_instance\" AND resource.label.instance_name=~\"${var.project_name}-.*-instance\""
}

resource "google_storage_bucket" "database_log_bucket" {
  count    = var.enable_logging ? 1 : 0
  name     = "${var.project_name}-database-logs-${random_id.bucket_suffix[0].hex}"
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
