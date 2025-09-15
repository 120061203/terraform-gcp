# Compute Engine教學輸出定義

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

# 負載平衡器相關輸出
output "load_balancer_ip" {
  description = "負載平衡器外部IP地址"
  value       = google_compute_global_address.lb_ip.address
}

output "load_balancer_url" {
  description = "負載平衡器URL"
  value       = "http://${google_compute_global_address.lb_ip.address}"
}

output "health_check_url" {
  description = "健康檢查URL"
  value       = "http://${google_compute_global_address.lb_ip.address}/health"
}

# 實例組相關輸出
output "instance_group_manager" {
  description = "實例組管理器信息"
  value = {
    id   = google_compute_instance_group_manager.web_igm.id
    name = google_compute_instance_group_manager.web_igm.name
    zone = google_compute_instance_group_manager.web_igm.zone
  }
}

output "autoscaler" {
  description = "自動擴展器信息"
  value = {
    id            = google_compute_autoscaler.web_autoscaler.id
    name          = google_compute_autoscaler.web_autoscaler.name
    min_replicas  = google_compute_autoscaler.web_autoscaler.autoscaling_policy[0].min_replicas
    max_replicas  = google_compute_autoscaler.web_autoscaler.autoscaling_policy[0].max_replicas
  }
}

# 實例模板相關輸出
output "instance_template" {
  description = "實例模板信息"
  value = {
    id          = google_compute_instance_template.web_template.id
    name_prefix = google_compute_instance_template.web_template.name_prefix
    machine_type = google_compute_instance_template.web_template.machine_type
  }
}

# 健康檢查相關輸出
output "health_check" {
  description = "健康檢查信息"
  value = {
    id   = google_compute_health_check.web_health_check.id
    name = google_compute_health_check.web_health_check.name
    port = google_compute_health_check.web_health_check.http_health_check[0].port
    path = google_compute_health_check.web_health_check.http_health_check[0].request_path
  }
}

# 特殊實例相關輸出
output "special_instance" {
  description = "特殊實例信息"
  value = var.create_special_instance ? {
    id           = google_compute_instance.special_instance[0].id
    name         = google_compute_instance.special_instance[0].name
    external_ip  = google_compute_instance.special_instance[0].network_interface[0].access_config[0].nat_ip
    internal_ip  = google_compute_instance.special_instance[0].network_interface[0].network_ip
    zone         = google_compute_instance.special_instance[0].zone
    machine_type = google_compute_instance.special_instance[0].machine_type
  } : null
}

# 數據磁碟相關輸出
output "data_disk" {
  description = "數據磁碟信息"
  value = var.create_special_instance ? {
    id   = google_compute_disk.data_disk[0].id
    name = google_compute_disk.data_disk[0].name
    size = google_compute_disk.data_disk[0].size
    type = google_compute_disk.data_disk[0].type
    zone = google_compute_disk.data_disk[0].zone
  } : null
}

# 預留實例相關輸出
output "reservation" {
  description = "預留實例信息"
  value = var.create_reservation ? {
    id    = google_compute_reservation.reservation[0].id
    name  = google_compute_reservation.reservation[0].name
    count = google_compute_reservation.reservation[0].specific_reservation[0].count
    zone  = google_compute_reservation.reservation[0].zone
  } : null
}

# 服務帳戶相關輸出
output "service_account" {
  description = "服務帳戶信息"
  value = {
    email = google_service_account.compute_sa.email
    id    = google_service_account.compute_sa.id
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
    http = {
      name = google_compute_firewall.allow_http.name
      id   = google_compute_firewall.allow_http.id
    }
    custom = {
      name = google_compute_firewall.allow_custom_ports.name
      id   = google_compute_firewall.allow_custom_ports.id
    }
  }
}

# 監控相關輸出
output "monitoring" {
  description = "監控配置信息"
  value = var.enable_monitoring ? {
    alert_policy = {
      id   = google_monitoring_alert_policy.high_cpu[0].id
      name = google_monitoring_alert_policy.high_cpu[0].display_name
    }
  } : null
}

# 日誌相關輸出
output "logging" {
  description = "日誌配置信息"
  value = var.enable_logging ? {
    sink = {
      id   = google_logging_project_sink.compute_logs[0].id
      name = google_logging_project_sink.compute_logs[0].name
    }
    bucket = {
      id   = google_storage_bucket.log_bucket[0].id
      name = google_storage_bucket.log_bucket[0].name
      url  = google_storage_bucket.log_bucket[0].url
    }
  } : null
}

# 快照相關輸出
output "snapshot_policy" {
  description = "快照策略信息"
  value = var.enable_snapshots ? {
    id   = google_compute_resource_policy.snapshot_policy[0].id
    name = google_compute_resource_policy.snapshot_policy[0].name
  } : null
}

# KMS相關輸出
output "kms_key" {
  description = "KMS密鑰信息"
  value = var.enable_disk_encryption ? {
    key_ring = {
      id   = google_kms_key_ring.disk_key_ring[0].id
      name = google_kms_key_ring.disk_key_ring[0].name
    }
    crypto_key = {
      id   = google_kms_crypto_key.disk_key[0].id
      name = google_kms_crypto_key.disk_key[0].name
    }
  } : null
}

# 連接命令輸出
output "ssh_commands" {
  description = "SSH連接命令"
  value = {
    special_instance = var.create_special_instance ? "gcloud compute ssh ${google_compute_instance.special_instance[0].name} --zone=${google_compute_instance.special_instance[0].zone}" : null
  }
}

# 資源摘要輸出
output "resource_summary" {
  description = "創建的資源摘要"
  value = {
    vpc_created              = true
    subnet_created           = true
    instance_template_created = true
    instance_group_created   = true
    autoscaler_created       = true
    load_balancer_created    = true
    health_check_created     = true
    special_instance_created = var.create_special_instance
    data_disk_created        = var.create_special_instance
    reservation_created      = var.create_reservation
    monitoring_enabled       = var.enable_monitoring
    logging_enabled          = var.enable_logging
    snapshots_enabled        = var.enable_snapshots
    encryption_enabled       = var.enable_disk_encryption
  }
}

# 架構信息輸出
output "architecture_info" {
  description = "架構信息"
  value = {
    project_name     = var.project_name
    region          = var.region
    zone            = var.zone
    machine_type    = var.machine_type
    instance_count  = var.instance_count
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    subnet_cidr     = var.subnet_cidr
    environment     = var.environment
  }
}

# 成本估算輸出
output "estimated_monthly_cost" {
  description = "預估月度成本（美元）"
  value = {
    compute_instances = "~$${var.instance_count * 5}-$${var.instance_count * 10}"  # e2-micro實例
    load_balancer    = "~$18"      # HTTP負載平衡器
    data_disk        = var.create_special_instance ? "~$2-5" : "$0"
    reservation      = var.create_reservation ? "~$${var.reservation_count * 3}-$${var.reservation_count * 6}" : "$0"
    monitoring       = var.enable_monitoring ? "~$1-3" : "$0"
    logging          = var.enable_logging ? "~$1-5" : "$0"
    snapshots        = var.enable_snapshots ? "~$1-3" : "$0"
    total_estimate   = "~$${20 + (var.instance_count * 5)}-$${30 + (var.instance_count * 10)}"
  }
}
