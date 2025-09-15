# VPC模組輸出定義

# VPC網路輸出
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

# 子網路輸出
output "subnets" {
  description = "子網路信息"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => {
      id        = v.id
      name      = v.name
      cidr      = v.ip_cidr_range
      region    = v.region
      self_link = v.self_link
    }
  }
}

# NAT輸出
output "nat_router" {
  description = "NAT路由器信息"
  value = var.enable_nat ? {
    id   = google_compute_router.nat_router[0].id
    name = google_compute_router.nat_router[0].name
    region = google_compute_router.nat_router[0].region
  } : null
}

output "nat_gateway" {
  description = "NAT網關信息"
  value = var.enable_nat ? {
    id   = google_compute_router_nat.nat[0].id
    name = google_compute_router_nat.nat[0].name
  } : null
}

# 防火牆規則輸出
output "firewall_rules" {
  description = "防火牆規則信息"
  value = {
    for k, v in google_compute_firewall.rules : k => {
      id   = v.id
      name = v.name
    }
  }
}

# 路由輸出
output "routes" {
  description = "路由信息"
  value = {
    for k, v in google_compute_route.routes : k => {
      id   = v.id
      name = v.name
      dest_range = v.dest_range
    }
  }
}

# VPN輸出
output "vpn_gateway" {
  description = "VPN網關信息"
  value = var.enable_vpn_gateway ? {
    id   = google_compute_vpn_gateway.vpn_gateway[0].id
    name = google_compute_vpn_gateway.vpn_gateway[0].name
    region = google_compute_vpn_gateway.vpn_gateway[0].region
  } : null
}

output "vpn_tunnels" {
  description = "VPN隧道信息"
  value = {
    for k, v in google_compute_vpn_tunnel.vpn_tunnel : k => {
      id   = v.id
      name = v.name
    }
  }
}

# 私有服務連接輸出
output "private_service_connection" {
  description = "私有服務連接信息"
  value = var.enable_private_service_connect ? {
    private_ip_alloc = {
      id   = google_compute_global_address.private_ip_alloc[0].id
      name = google_compute_global_address.private_ip_alloc[0].name
      address = google_compute_global_address.private_ip_alloc[0].address
    }
    connection = {
      id = google_service_networking_connection.private_vpc_connection[0].id
    }
  } : null
}

# 網路摘要輸出
output "network_summary" {
  description = "網路架構摘要"
  value = {
    vpc_name = google_compute_network.main.name
    subnet_count = length(google_compute_subnetwork.subnets)
    firewall_rule_count = length(google_compute_firewall.rules)
    route_count = length(google_compute_route.routes)
    nat_enabled = var.enable_nat
    vpn_enabled = var.enable_vpn_gateway
    private_service_connect_enabled = var.enable_private_service_connect
    flow_logs_enabled = var.enable_flow_logs
  }
}
