# 第2章：VPC網路教學 - 成本優化版本輸出

# VPC資訊
output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.main_vpc.id
}

output "vpc_name" {
  description = "VPC名稱"
  value       = google_compute_network.main_vpc.name
}

output "vpc_self_link" {
  description = "VPC Self Link"
  value       = google_compute_network.main_vpc.self_link
}

# 子網路資訊
output "public_subnet_id" {
  description = "公共子網路ID"
  value       = google_compute_subnetwork.public_subnet.id
}

output "public_subnet_name" {
  description = "公共子網路名稱"
  value       = google_compute_subnetwork.public_subnet.name
}

output "public_subnet_cidr" {
  description = "公共子網路CIDR"
  value       = google_compute_subnetwork.public_subnet.ip_cidr_range
}

output "private_subnet_id" {
  description = "私有子網路ID"
  value       = google_compute_subnetwork.private_subnet.id
}

output "private_subnet_name" {
  description = "私有子網路名稱"
  value       = google_compute_subnetwork.private_subnet.name
}

output "private_subnet_cidr" {
  description = "私有子網路CIDR"
  value       = google_compute_subnetwork.private_subnet.ip_cidr_range
}

output "database_subnet_id" {
  description = "數據庫子網路ID"
  value       = google_compute_subnetwork.database_subnet.id
}

output "database_subnet_name" {
  description = "數據庫子網路名稱"
  value       = google_compute_subnetwork.database_subnet.name
}

output "database_subnet_cidr" {
  description = "數據庫子網路CIDR"
  value       = google_compute_subnetwork.database_subnet.ip_cidr_range
}

# 實例資訊
output "web_server_external_ip" {
  description = "Web服務器外部IP"
  value       = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}

output "web_server_internal_ip" {
  description = "Web服務器內部IP"
  value       = google_compute_instance.web_server.network_interface[0].network_ip
}

output "web_server_name" {
  description = "Web服務器名稱"
  value       = google_compute_instance.web_server.name
}

output "web_server_zone" {
  description = "Web服務器可用區"
  value       = google_compute_instance.web_server.zone
}

output "app_server_internal_ip" {
  description = "App服務器內部IP"
  value       = google_compute_instance.app_server.network_interface[0].network_ip
}

output "app_server_name" {
  description = "App服務器名稱"
  value       = google_compute_instance.app_server.name
}

output "app_server_zone" {
  description = "App服務器可用區"
  value       = google_compute_instance.app_server.zone
}

# 防火牆規則資訊
output "firewall_rules" {
  description = "防火牆規則摘要"
  value = {
    ssh = {
      id   = google_compute_firewall.allow_ssh.id
      name = google_compute_firewall.allow_ssh.name
    }
    http_https = {
      id   = google_compute_firewall.allow_http_https.id
      name = google_compute_firewall.allow_http_https.name
    }
    internal = {
      id   = google_compute_firewall.allow_internal.id
      name = google_compute_firewall.allow_internal.name
    }
    database = {
      id   = google_compute_firewall.allow_database.id
      name = google_compute_firewall.allow_database.name
    }
  }
}

# 服務帳戶資訊
output "web_service_account_email" {
  description = "Web服務器服務帳戶Email"
  value       = google_service_account.web_sa.email
}

output "app_service_account_email" {
  description = "App服務器服務帳戶Email"
  value       = google_service_account.app_sa.email
}

# SSH命令
output "ssh_web_server" {
  description = "SSH到Web服務器的命令"
  value       = "gcloud compute ssh ${google_compute_instance.web_server.name} --zone=${google_compute_instance.web_server.zone}"
}

output "ssh_app_server" {
  description = "SSH到App服務器的命令"
  value       = "gcloud compute ssh ${google_compute_instance.app_server.name} --zone=${google_compute_instance.app_server.zone}"
}

# Web URL
output "web_url" {
  description = "Web服務器URL"
  value       = "http://${google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip}"
}

# 專案資訊
output "project_info" {
  description = "專案資訊"
  value = {
    project_id   = var.project_id
    project_name = var.project_name
    region       = var.region
    zone         = var.zone
  }
}

# 資源摘要
output "resource_summary" {
  description = "創建的資源摘要"
  value = {
    vpc_created           = true
    subnets_created       = 3
    instances_created     = 2
    firewall_rules_created = 4
    service_accounts_created = 2
    total_resources       = 12
  }
}

# 成本估算 - 預算版本
output "estimated_monthly_cost" {
  description = "預估月度成本（美元）- 預算版本"
  value = {
    compute_instances = "$0"      # 2個e2-micro實例 (免費層級)
    network_egress   = "$0-1"     # 少量流量免費
    total_estimate   = "$0-1"     # 幾乎免費
    budget_friendly  = true       # 符合$5預算
  }
}

# 架構說明
output "architecture_info" {
  description = "架構說明"
  value = {
    design_type = "三層網路架構 (預算版本)"
    layers = [
      "Public Subnet (DMZ) - Web Server",
      "Private Subnet (App Layer) - App Server", 
      "Database Subnet (Data Layer) - 預留"
    ]
    features = [
      "多子網路隔離",
      "分層防火牆規則",
      "服務帳戶分離",
      "成本優化設計"
    ]
    removed_features = [
      "負載均衡器 (節省$18/月)",
      "NAT網關 (節省$45/月)",
      "多實例部署 (節省$15-30/月)"
    ]
  }
}
