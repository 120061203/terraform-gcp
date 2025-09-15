# Cloud SQL教學輸出定義

# 網路相關輸出
output "vpc_id" {
  description = "VPC網路ID"
  value       = google_compute_network.database_network.id
}

output "vpc_name" {
  description = "VPC網路名稱"
  value       = google_compute_network.database_network.name
}

output "subnet_id" {
  description = "子網路ID"
  value       = google_compute_subnetwork.database_subnet.id
}

output "subnet_cidr" {
  description = "子網路CIDR區塊"
  value       = google_compute_subnetwork.database_subnet.ip_cidr_range
}

output "private_ip_alloc" {
  description = "私有IP分配"
  value       = google_compute_global_address.private_ip_alloc.address
}

# PostgreSQL相關輸出
output "postgres_instance" {
  description = "PostgreSQL實例信息"
  value = {
    id           = google_sql_database_instance.postgres_instance.id
    name         = google_sql_database_instance.postgres_instance.name
    connection_name = google_sql_database_instance.postgres_instance.connection_name
    region       = google_sql_database_instance.postgres_instance.region
    database_version = google_sql_database_instance.postgres_instance.database_version
    tier         = google_sql_database_instance.postgres_instance.settings[0].tier
    availability_type = google_sql_database_instance.postgres_instance.settings[0].availability_type
    disk_size    = google_sql_database_instance.postgres_instance.settings[0].disk_size
    disk_type    = google_sql_database_instance.postgres_instance.settings[0].disk_type
    private_ip   = google_sql_database_instance.postgres_instance.private_ip_address
  }
}

output "postgres_database" {
  description = "PostgreSQL數據庫信息"
  value = {
    id   = google_sql_database.postgres_database.id
    name = google_sql_database.postgres_database.name
  }
}

output "postgres_user" {
  description = "PostgreSQL用戶信息"
  value = {
    id   = google_sql_user.postgres_user.id
    name = google_sql_user.postgres_user.name
  }
}

# MySQL相關輸出
output "mysql_instance" {
  description = "MySQL實例信息"
  value = var.enable_mysql ? {
    id           = google_sql_database_instance.mysql_instance[0].id
    name         = google_sql_database_instance.mysql_instance[0].name
    connection_name = google_sql_database_instance.mysql_instance[0].connection_name
    region       = google_sql_database_instance.mysql_instance[0].region
    database_version = google_sql_database_instance.mysql_instance[0].database_version
    tier         = google_sql_database_instance.mysql_instance[0].settings[0].tier
    availability_type = google_sql_database_instance.mysql_instance[0].settings[0].availability_type
    disk_size    = google_sql_database_instance.mysql_instance[0].settings[0].disk_size
    disk_type    = google_sql_database_instance.mysql_instance[0].settings[0].disk_type
    private_ip   = google_sql_database_instance.mysql_instance[0].private_ip_address
  } : null
}

output "mysql_database" {
  description = "MySQL數據庫信息"
  value = var.enable_mysql ? {
    id   = google_sql_database.mysql_database[0].id
    name = google_sql_database.mysql_database[0].name
  } : null
}

output "mysql_user" {
  description = "MySQL用戶信息"
  value = var.enable_mysql ? {
    id   = google_sql_user.mysql_user[0].id
    name = google_sql_user.mysql_user[0].name
  } : null
}

# SQL Server相關輸出
output "sqlserver_instance" {
  description = "SQL Server實例信息"
  value = var.enable_sqlserver ? {
    id           = google_sql_database_instance.sqlserver_instance[0].id
    name         = google_sql_database_instance.sqlserver_instance[0].name
    connection_name = google_sql_database_instance.sqlserver_instance[0].connection_name
    region       = google_sql_database_instance.sqlserver_instance[0].region
    database_version = google_sql_database_instance.sqlserver_instance[0].database_version
    tier         = google_sql_database_instance.sqlserver_instance[0].settings[0].tier
    availability_type = google_sql_database_instance.sqlserver_instance[0].settings[0].availability_type
    disk_size    = google_sql_database_instance.sqlserver_instance[0].settings[0].disk_size
    disk_type    = google_sql_database_instance.sqlserver_instance[0].settings[0].disk_type
    private_ip   = google_sql_database_instance.sqlserver_instance[0].private_ip_address
  } : null
}

output "sqlserver_database" {
  description = "SQL Server數據庫信息"
  value = var.enable_sqlserver ? {
    id   = google_sql_database.sqlserver_database[0].id
    name = google_sql_database.sqlserver_database[0].name
  } : null
}

output "sqlserver_user" {
  description = "SQL Server用戶信息"
  value = var.enable_sqlserver ? {
    id   = google_sql_user.sqlserver_user[0].id
    name = google_sql_user.sqlserver_user[0].name
  } : null
}

# 讀取副本相關輸出
output "postgres_read_replica" {
  description = "PostgreSQL讀取副本信息"
  value = var.enable_read_replica ? {
    id           = google_sql_database_instance.postgres_read_replica[0].id
    name         = google_sql_database_instance.postgres_read_replica[0].name
    connection_name = google_sql_database_instance.postgres_read_replica[0].connection_name
    region       = google_sql_database_instance.postgres_read_replica[0].region
    master_instance = google_sql_database_instance.postgres_read_replica[0].master_instance_name
    private_ip   = google_sql_database_instance.postgres_read_replica[0].private_ip_address
  } : null
}

# SQL代理相關輸出
output "sql_proxy_instance" {
  description = "SQL代理實例信息"
  value = var.enable_sql_proxy ? {
    id           = google_compute_instance.sql_proxy[0].id
    name         = google_compute_instance.sql_proxy[0].name
    external_ip  = google_compute_instance.sql_proxy[0].network_interface[0].access_config[0].nat_ip
    internal_ip  = google_compute_instance.sql_proxy[0].network_interface[0].network_ip
    zone         = google_compute_instance.sql_proxy[0].zone
  } : null
}

# 服務帳戶相關輸出
output "service_account" {
  description = "數據庫服務帳戶信息"
  value = {
    email = google_service_account.database_sa.email
    id    = google_service_account.database_sa.id
  }
}

# KMS相關輸出
output "kms_key" {
  description = "KMS密鑰信息"
  value = {
    key_ring = {
      id   = google_kms_key_ring.database_key_ring.id
      name = google_kms_key_ring.database_key_ring.name
    }
    crypto_key = {
      id   = google_kms_crypto_key.database_key.id
      name = google_kms_crypto_key.database_key.name
    }
  }
}

# 防火牆規則相關輸出
output "firewall_rules" {
  description = "防火牆規則信息"
  value = {
    ssh = {
      name = google_compute_firewall.allow_ssh.name
      id   = google_compute_firewall.allow_ssh.id
    }
  }
}

# NAT相關輸出
output "nat_router" {
  description = "NAT路由器信息"
  value = {
    id   = google_compute_router.database_router.id
    name = google_compute_router.database_router.name
  }
}

output "nat_gateway" {
  description = "NAT網關信息"
  value = {
    id   = google_compute_router_nat.database_nat.id
    name = google_compute_router_nat.database_nat.name
  }
}

# 監控相關輸出
output "monitoring" {
  description = "監控配置信息"
  value = var.enable_monitoring ? {
    cpu_alert = {
      id   = google_monitoring_alert_policy.database_cpu_alert[0].id
      name = google_monitoring_alert_policy.database_cpu_alert[0].display_name
    }
    disk_alert = {
      id   = google_monitoring_alert_policy.database_disk_alert[0].id
      name = google_monitoring_alert_policy.database_disk_alert[0].display_name
    }
  } : null
}

# 日誌相關輸出
output "logging" {
  description = "日誌配置信息"
  value = var.enable_logging ? {
    sink = {
      id   = google_logging_project_sink.database_logs[0].id
      name = google_logging_project_sink.database_logs[0].name
    }
    bucket = {
      id   = google_storage_bucket.database_log_bucket[0].id
      name = google_storage_bucket.database_log_bucket[0].name
      url  = google_storage_bucket.database_log_bucket[0].url
    }
  } : null
}

# 連接命令輸出
output "connection_commands" {
  description = "數據庫連接命令"
  value = {
    postgres = "gcloud sql connect ${google_sql_database_instance.postgres_instance.name} --user=${google_sql_user.postgres_user.name} --database=${google_sql_database.postgres_database.name}"
    mysql = var.enable_mysql ? "gcloud sql connect ${google_sql_database_instance.mysql_instance[0].name} --user=${google_sql_user.mysql_user[0].name} --database=${google_sql_database.mysql_database[0].name}" : null
    sqlserver = var.enable_sqlserver ? "gcloud sql connect ${google_sql_database_instance.sqlserver_instance[0].name} --user=${google_sql_user.sqlserver_user[0].name} --database=${google_sql_database.sqlserver_database[0].name}" : null
  }
}

output "proxy_connection_commands" {
  description = "通過代理的連接命令"
  value = var.enable_sql_proxy ? {
    postgres = "psql -h ${google_compute_instance.sql_proxy[0].network_interface[0].access_config[0].nat_ip} -p 5432 -U ${google_sql_user.postgres_user.name} -d ${google_sql_database.postgres_database.name}"
    mysql = var.enable_mysql ? "mysql -h ${google_compute_instance.sql_proxy[0].network_interface[0].access_config[0].nat_ip} -P 3306 -u ${google_sql_user.mysql_user[0].name} -p ${google_sql_database.mysql_database[0].name}" : null
    sqlserver = var.enable_sqlserver ? "sqlcmd -S ${google_compute_instance.sql_proxy[0].network_interface[0].access_config[0].nat_ip},1433 -U ${google_sql_user.sqlserver_user[0].name} -P 'password' -d ${google_sql_database.sqlserver_database[0].name}" : null
  } : null
}

# SSH命令輸出
output "ssh_commands" {
  description = "SSH連接命令"
  value = var.enable_sql_proxy ? {
    sql_proxy = "gcloud compute ssh ${google_compute_instance.sql_proxy[0].name} --zone=${google_compute_instance.sql_proxy[0].zone}"
  } : null
}

# 資源摘要輸出
output "resource_summary" {
  description = "創建的資源摘要"
  value = {
    vpc_created              = true
    subnet_created           = true
    postgres_instance_created = true
    mysql_instance_created   = var.enable_mysql
    sqlserver_instance_created = var.enable_sqlserver
    read_replica_created     = var.enable_read_replica
    sql_proxy_created        = var.enable_sql_proxy
    monitoring_enabled       = var.enable_monitoring
    logging_enabled          = var.enable_logging
    encryption_enabled       = true
    private_network_enabled   = true
  }
}

# 架構信息輸出
output "architecture_info" {
  description = "架構信息"
  value = {
    project_name     = var.project_name
    region          = var.region
    postgres_version = var.postgres_version
    mysql_version   = var.enable_mysql ? var.mysql_version : null
    sqlserver_version = var.enable_sqlserver ? var.sqlserver_version : null
    environment     = var.environment
    private_network = true
    encryption      = true
  }
}

# 成本估算輸出
output "estimated_monthly_cost" {
  description = "預估月度成本（美元）"
  value = {
    postgres_instance = "~$25-50"     # db-f1-micro實例
    mysql_instance    = var.enable_mysql ? "~$25-50" : "$0"
    sqlserver_instance = var.enable_sqlserver ? "~$100-200" : "$0"
    read_replica      = var.enable_read_replica ? "~$25-50" : "$0"
    sql_proxy         = var.enable_sql_proxy ? "~$5-10" : "$0"
    storage           = "~$5-15"      # 磁碟存儲
    backup            = "~$2-5"       # 備份存儲
    monitoring        = var.enable_monitoring ? "~$1-3" : "$0"
    logging           = var.enable_logging ? "~$1-5" : "$0"
    total_estimate    = "~$${60 + (var.enable_mysql ? 25 : 0) + (var.enable_sqlserver ? 100 : 0) + (var.enable_read_replica ? 25 : 0) + (var.enable_sql_proxy ? 5 : 0)}-$${120 + (var.enable_mysql ? 50 : 0) + (var.enable_sqlserver ? 200 : 0) + (var.enable_read_replica ? 50 : 0) + (var.enable_sql_proxy ? 10 : 0)}"
  }
}
