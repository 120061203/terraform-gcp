# VPC模組變數定義

# 基本配置
variable "vpc_name" {
  description = "VPC網路名稱"
  type        = string
}

variable "vpc_description" {
  description = "VPC網路描述"
  type        = string
  default     = "Managed VPC network"
}

variable "enable_ipv6" {
  description = "是否啟用IPv6"
  type        = bool
  default     = false
}

# 子網路配置
variable "subnets" {
  description = "子網路配置"
  type = map(object({
    name                     = string
    cidr                     = string
    region                   = string
    private_ip_google_access = optional(bool, true)
    secondary_ranges = optional(list(object({
      name = string
      cidr = string
    })), [])
  }))
  default = {}
}

# NAT配置
variable "enable_nat" {
  description = "是否啟用Cloud NAT"
  type        = bool
  default     = false
}

variable "nat_region" {
  description = "NAT區域"
  type        = string
  default     = "us-central1"
}

variable "nat_bgp_asn" {
  description = "NAT BGP ASN"
  type        = number
  default     = 64514
}

variable "nat_ip_allocation" {
  description = "NAT IP分配方式"
  type        = string
  default     = "AUTO_ONLY"
  
  validation {
    condition = contains(["AUTO_ONLY", "MANUAL_ONLY"], var.nat_ip_allocation)
    error_message = "NAT IP分配方式必須是 AUTO_ONLY 或 MANUAL_ONLY"
  }
}

variable "nat_source_subnetworks" {
  description = "NAT源子網路"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

variable "enable_nat_logs" {
  description = "是否啟用NAT日誌"
  type        = bool
  default     = false
}

variable "nat_log_filter" {
  description = "NAT日誌過濾器"
  type        = string
  default     = "ERRORS_ONLY"
}

# 防火牆規則配置
variable "firewall_rules" {
  description = "防火牆規則配置"
  type = map(object({
    name        = string
    description = optional(string, "")
    priority    = optional(number, 1000)
    source_ranges = optional(list(string), [])
    target_tags   = optional(list(string), [])
    source_tags   = optional(list(string), [])
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
  }))
  default = {}
}

# 路由配置
variable "routes" {
  description = "路由配置"
  type = map(object({
    name                = string
    dest_range         = string
    next_hop_gateway   = optional(string)
    next_hop_instance  = optional(string)
    next_hop_ip        = optional(string)
    next_hop_vpn_tunnel = optional(string)
    priority           = optional(number, 1000)
    tags               = optional(list(string), [])
  }))
  default = {}
}

# VPN配置
variable "enable_vpn_gateway" {
  description = "是否啟用VPN網關"
  type        = bool
  default     = false
}

variable "vpn_gateway_region" {
  description = "VPN網關區域"
  type        = string
  default     = "us-central1"
}

variable "vpn_tunnels" {
  description = "VPN隧道配置"
  type = map(object({
    name                   = string
    peer_ip               = string
    shared_secret         = string
    local_traffic_selector  = optional(list(string), ["0.0.0.0/0"])
    remote_traffic_selector = optional(list(string), ["0.0.0.0/0"])
  }))
  default = {}
}

# 私有服務連接配置
variable "enable_private_service_connect" {
  description = "是否啟用私有服務連接"
  type        = bool
  default     = false
}

variable "private_service_connect_prefix_length" {
  description = "私有服務連接前綴長度"
  type        = number
  default     = 16
}

# 流日誌配置
variable "enable_flow_logs" {
  description = "是否啟用VPC流日誌"
  type        = bool
  default     = false
}

variable "flow_log_aggregation_interval" {
  description = "流日誌聚合間隔"
  type        = string
  default     = "INTERVAL_5_SEC"
  
  validation {
    condition = contains([
      "INTERVAL_5_SEC", "INTERVAL_30_SEC", "INTERVAL_1_MIN", 
      "INTERVAL_5_MIN", "INTERVAL_10_MIN", "INTERVAL_15_MIN"
    ], var.flow_log_aggregation_interval)
    error_message = "流日誌聚合間隔必須是有效的值"
  }
}

variable "flow_log_sampling_rate" {
  description = "流日誌採樣率"
  type        = number
  default     = 0.5
  
  validation {
    condition = var.flow_log_sampling_rate >= 0.0 && var.flow_log_sampling_rate <= 1.0
    error_message = "流日誌採樣率必須在0.0到1.0之間"
  }
}

variable "flow_log_metadata" {
  description = "流日誌元數據"
  type        = string
  default     = "INCLUDE_ALL_METADATA"
  
  validation {
    condition = contains([
      "EXCLUDE_ALL_METADATA", "INCLUDE_ALL_METADATA"
    ], var.flow_log_metadata)
    error_message = "流日誌元數據必須是 EXCLUDE_ALL_METADATA 或 INCLUDE_ALL_METADATA"
  }
}

# 標籤配置
variable "labels" {
  description = "資源標籤"
  type        = map(string)
  default     = {}
}
