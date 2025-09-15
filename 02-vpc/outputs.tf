# VPC網路教學輸出定義

# VPC網路相關輸出
output "vpc_id" {
  description = "主VPC網路ID"
  value       = google_compute_network.main_vpc.id
}

output "vpc_name" {
  description = "主VPC網路名稱"
  value       = google_compute_network.main_vpc.name
}

output "vpc_self_link" {
  description = "主VPC網路自引用連結"
  value       = google_compute_network.main_vpc.self_link
}

# 子網路相關輸出
output "public_subnet" {
  description = "公共子網路信息"
  value = {
    id        = google_compute_subnetwork.public_subnet.id
    name      = google_compute_subnetwork.public_subnet.name
    cidr      = google_compute_subnetwork.public_subnet.ip_cidr_range
    region    = google_compute_subnetwork.public_subnet.region
    self_link = google_compute_subnetwork.public_subnet.self_link
  }
}

output "private_subnet" {
  description = "私有子網路信息"
  value = {
    id        = google_compute_subnetwork.private_subnet.id
    name      = google_compute_subnetwork.private_subnet.name
    cidr      = google_compute_subnetwork.private_subnet.ip_cidr_range
    region    = google_compute_subnetwork.private_subnet.region
    self_link = google_compute_subnetwork.private_subnet.self_link
  }
}

output "database_subnet" {
  description = "數據庫子網路信息"
  value = {
    id        = google_compute_subnetwork.database_subnet.id
    name      = google_compute_subnetwork.database_subnet.name
    cidr      = google_compute_subnetwork.database_subnet.ip_cidr_range
    region    = google_compute_subnetwork.database_subnet.region
    self_link = google_compute_subnetwork.database_subnet.self_link
  }
}

# NAT相關輸出
output "nat_router" {
  description = "NAT路由器信息"
  value = {
    id   = google_compute_router.nat_router.id
    name = google_compute_router.nat_router.name
    asn  = google_compute_router.nat_router.bgp[0].asn
  }
}

output "nat_gateway" {
  description = "NAT網關信息"
  value = {
    id   = google_compute_router_nat.nat.id
    name = google_compute_router_nat.nat.name
  }
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

# 防火牆規則輸出
output "firewall_rules" {
  description = "創建的防火牆規則"
  value = {
    ssh = {
      name = google_compute_firewall.allow_ssh.name
      id   = google_compute_firewall.allow_ssh.id
    }
    http_https = {
      name = google_compute_firewall.allow_http_https.name
      id   = google_compute_firewall.allow_http_https.id
    }
    internal = {
      name = google_compute_firewall.allow_internal.name
      id   = google_compute_firewall.allow_internal.id
    }
    database = {
      name = google_compute_firewall.allow_database.name
      id   = google_compute_firewall.allow_database.id
    }
    deny_all = {
      name = google_compute_firewall.deny_all.name
      id   = google_compute_firewall.deny_all.id
    }
  }
}

# Compute Engine實例輸出
output "web_servers" {
  description = "Web服務器實例信息"
  value = {
    server_1 = {
      id           = google_compute_instance.web_server_1.id
      name         = google_compute_instance.web_server_1.name
      external_ip  = google_compute_instance.web_server_1.network_interface[0].access_config[0].nat_ip
      internal_ip  = google_compute_instance.web_server_1.network_interface[0].network_ip
      zone         = google_compute_instance.web_server_1.zone
    }
    server_2 = {
      id           = google_compute_instance.web_server_2.id
      name         = google_compute_instance.web_server_2.name
      external_ip  = google_compute_instance.web_server_2.network_interface[0].access_config[0].nat_ip
      internal_ip  = google_compute_instance.web_server_2.network_interface[0].network_ip
      zone         = google_compute_instance.web_server_2.zone
    }
  }
}

output "app_server" {
  description = "應用服務器信息"
  value = {
    id          = google_compute_instance.app_server.id
    name        = google_compute_instance.app_server.name
    internal_ip = google_compute_instance.app_server.network_interface[0].network_ip
    zone        = google_compute_instance.app_server.zone
    subnet      = google_compute_instance.app_server.network_interface[0].subnetwork
  }
}

# 服務帳戶輸出
output "service_accounts" {
  description = "創建的服務帳戶"
  value = {
    web_sa = {
      email = google_service_account.web_sa.email
      id    = google_service_account.web_sa.id
    }
    app_sa = {
      email = google_service_account.app_sa.email
      id    = google_service_account.app_sa.id
    }
  }
}

# 實例組輸出
output "instance_group" {
  description = "實例組信息"
  value = {
    id   = google_compute_instance_group.web_servers.id
    name = google_compute_instance_group.web_servers.name
    zone = google_compute_instance_group.web_servers.zone
  }
}

# 連接命令輸出
output "ssh_commands" {
  description = "SSH連接命令"
  value = {
    web_server_1 = "gcloud compute ssh ${google_compute_instance.web_server_1.name} --zone=${google_compute_instance.web_server_1.zone}"
    web_server_2 = "gcloud compute ssh ${google_compute_instance.web_server_2.name} --zone=${google_compute_instance.web_server_2.zone}"
    app_server   = "gcloud compute ssh ${google_compute_instance.app_server.name} --zone=${google_compute_instance.app_server.zone}"
  }
}

# 網路架構摘要
output "network_architecture" {
  description = "網路架構摘要"
  value = {
    vpc_name = google_compute_network.main_vpc.name
    subnets = {
      public   = var.public_subnet_cidr
      private  = var.private_subnet_cidr
      database = var.database_subnet_cidr
    }
    nat_enabled = var.enable_nat
    lb_enabled  = var.enable_load_balancer
    instances = {
      web_servers = 2
      app_servers = 1
      total       = 3
    }
  }
}

# 安全配置摘要
output "security_summary" {
  description = "安全配置摘要"
  value = {
    firewall_rules_count = 5
    ssh_allowed_cidrs   = var.allowed_ssh_cidrs
    internal_communication_enabled = true
    database_access_restricted = true
    deny_all_rule_enabled = true
  }
}

# 成本估算
output "estimated_monthly_cost" {
  description = "預估月度成本（美元）"
  value = {
    compute_instances = "~$15-30"  # 3個e2-micro實例
    load_balancer    = "~$18"      # HTTP負載平衡器
    nat_gateway      = "~$45"      # Cloud NAT
    network_egress   = "~$0-5"     # 取決於流量
    total_estimate   = "~$78-98"
  }
}
