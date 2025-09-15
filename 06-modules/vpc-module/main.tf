# VPC模組 - 可重用的VPC網路模組
# 提供標準化的VPC網路配置

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# 創建VPC網路
resource "google_compute_network" "main" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = var.vpc_description
  
  # 啟用UDP負載平衡日誌記錄
  enable_ula_internal_ipv6 = var.enable_ipv6
}

# 創建子網路
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets
  
  name          = each.value.name
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.main.id
  
  # 啟用私有IP Google訪問
  private_ip_google_access = each.value.private_ip_google_access
  
  # 次要IP範圍（用於GKE等）
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.value.name
      ip_cidr_range = secondary_ip_range.value.cidr
    }
  }
  
  # 日誌配置
  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = var.flow_log_aggregation_interval
      flow_sampling        = var.flow_log_sampling_rate
      metadata            = var.flow_log_metadata
    }
  }
}

# 創建Cloud NAT（如果啟用）
resource "google_compute_router" "nat_router" {
  count   = var.enable_nat ? 1 : 0
  name    = "${var.vpc_name}-nat-router"
  region  = var.nat_region
  network = google_compute_network.main.id
  
  bgp {
    asn = var.nat_bgp_asn
  }
}

resource "google_compute_router_nat" "nat" {
  count                              = var.enable_nat ? 1 : 0
  name                               = "${var.vpc_name}-nat"
  router                            = google_compute_router.nat_router[0].name
  region                            = var.nat_region
  nat_ip_allocate_option            = var.nat_ip_allocation
  source_subnetwork_ip_ranges_to_nat = var.nat_source_subnetworks
  
  # NAT日誌配置
  dynamic "log_config" {
    for_each = var.enable_nat_logs ? [1] : []
    content {
      enable = true
      filter = var.nat_log_filter
    }
  }
}

# 創建防火牆規則
resource "google_compute_firewall" "rules" {
  for_each = var.firewall_rules
  
  name    = each.value.name
  network = google_compute_network.main.name
  
  # 允許規則
  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
  
  # 拒絕規則
  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
  
  # 源範圍
  source_ranges = each.value.source_ranges
  
  # 目標標籤
  target_tags = each.value.target_tags
  
  # 源標籤
  source_tags = each.value.source_tags
  
  # 描述
  description = each.value.description
  
  # 優先級
  priority = each.value.priority
}

# 創建路由
resource "google_compute_route" "routes" {
  for_each = var.routes
  
  name                   = each.value.name
  dest_range            = each.value.dest_range
  network               = google_compute_network.main.name
  next_hop_gateway      = each.value.next_hop_gateway
  next_hop_instance     = each.value.next_hop_instance
  next_hop_ip           = each.value.next_hop_ip
  next_hop_vpn_tunnel   = each.value.next_hop_vpn_tunnel
  priority              = each.value.priority
  
  tags = each.value.tags
}

# 創建VPN網關（如果啟用）
resource "google_compute_vpn_gateway" "vpn_gateway" {
  count   = var.enable_vpn_gateway ? 1 : 0
  name    = "${var.vpc_name}-vpn-gateway"
  network = google_compute_network.main.id
  region  = var.vpn_gateway_region
}

# 創建VPN隧道（如果啟用）
resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  for_each = var.vpn_tunnels
  
  name          = each.value.name
  peer_ip       = each.value.peer_ip
  shared_secret = each.value.shared_secret
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gateway[0].id
  
  region = var.vpn_gateway_region
  
  local_traffic_selector  = each.value.local_traffic_selector
  remote_traffic_selector = each.value.remote_traffic_selector
  
  depends_on = [google_compute_forwarding_rule.vpn_forwarding_rules]
}

# 創建VPN轉發規則
resource "google_compute_forwarding_rule" "vpn_forwarding_rules" {
  for_each = var.enable_vpn_gateway ? {
    esp  = { name = "${var.vpc_name}-vpn-esp",  ip_protocol = "ESP" }
    udp500 = { name = "${var.vpc_name}-vpn-udp500", ip_protocol = "UDP", port_range = "500" }
    udp4500 = { name = "${var.vpc_name}-vpn-udp4500", ip_protocol = "UDP", port_range = "4500" }
  } : {}
  
  name        = each.value.name
  ip_protocol = each.value.ip_protocol
  port_range  = each.value.port_range
  target      = google_compute_vpn_gateway.vpn_gateway[0].id
  region      = var.vpn_gateway_region
}

# 創建私有服務連接（如果啟用）
resource "google_compute_global_address" "private_ip_alloc" {
  count = var.enable_private_service_connect ? 1 : 0
  
  name          = "${var.vpc_name}-private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_connect_prefix_length
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.enable_private_service_connect ? 1 : 0
  
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc[0].name]
}
