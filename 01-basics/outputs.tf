# 輸出定義文件
# 定義Terraform執行後要輸出的重要信息

# 網路相關輸出
output "vpc_id" {
  description = "VPC網路ID"
  value       = google_compute_network.main.id
}

output "vpc_name" {
  description = "VPC網路名稱"
  value       = google_compute_network.main.name
}

output "vpc_self_link" {
  description = "VPC網路自引用連結"
  value       = google_compute_network.main.self_link
}

output "subnet_id" {
  description = "子網路ID"
  value       = google_compute_subnetwork.main.id
}

output "subnet_name" {
  description = "子網路名稱"
  value       = google_compute_subnetwork.main.name
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

output "instance_zone" {
  description = "虛擬機器所在可用區"
  value       = google_compute_instance.web_server.zone
}

output "instance_machine_type" {
  description = "虛擬機器類型"
  value       = google_compute_instance.web_server.machine_type
}

# 服務帳戶相關輸出
output "service_account_email" {
  description = "服務帳戶電子郵件"
  value       = google_service_account.instance_sa.email
}

output "service_account_id" {
  description = "服務帳戶ID"
  value       = google_service_account.instance_sa.id
}

# Storage相關輸出已移除以節省費用
# output "bucket_name" {
#   description = "Storage Bucket名稱"
#   value       = google_storage_bucket.data_bucket.name
# }
# 
# output "bucket_url" {
#   description = "Storage Bucket URL"
#   value       = google_storage_bucket.data_bucket.url
# }
# 
# output "bucket_location" {
#   description = "Storage Bucket位置"
#   value       = google_storage_bucket.data_bucket.location
# }

# 防火牆規則相關輸出
output "firewall_rules" {
  description = "創建的防火牆規則列表"
  value = {
    ssh = {
      name = google_compute_firewall.allow_ssh.name
      id   = google_compute_firewall.allow_ssh.id
    }
    http = {
      name = google_compute_firewall.allow_http.name
      id   = google_compute_firewall.allow_http.id
    }
    https = {
      name = google_compute_firewall.allow_https.name
      id   = google_compute_firewall.allow_https.id
    }
  }
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

# 專案信息輸出
output "project_info" {
  description = "專案基本信息"
  value = {
    project_id   = var.project_id
    project_name = var.project_name
    region       = var.region
    zone         = var.zone
    environment  = var.environment
  }
}

# 資源摘要輸出
output "resource_summary" {
  description = "創建的資源摘要"
  value = {
    vpc_created        = true
    subnet_created     = true
    instance_created   = true
    bucket_created     = false  # 已移除以節省費用
    firewalls_created  = 3
    total_resources    = 5      # 減少1個資源
  }
}

# 成本估算輸出（僅供參考）
output "estimated_monthly_cost" {
  description = "預估月度成本（美元）"
  value = {
    compute_instance = "$0"      # e2-micro實例免費
    storage_bucket   = "$0"      # 已移除
    network_egress   = "$0-1"    # 少量流量免費
    total_estimate   = "$0-1"    # 幾乎免費
  }
}
