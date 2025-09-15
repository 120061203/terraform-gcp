# VPC模組

這是一個可重用的VPC網路模組，提供標準化的VPC網路配置。

## 功能特性

- 創建自定義VPC網路
- 支持多個子網路
- 可選的Cloud NAT配置
- 靈活的防火牆規則
- 自定義路由
- VPN網關和隧道支持
- 私有服務連接
- VPC流日誌

## 使用方法

```hcl
module "vpc" {
  source = "./vpc-module"
  
  vpc_name = "my-vpc"
  vpc_description = "Production VPC"
  
  subnets = {
    public = {
      name = "public-subnet"
      cidr = "10.0.1.0/24"
      region = "us-central1"
      private_ip_google_access = true
    }
    private = {
      name = "private-subnet"
      cidr = "10.0.2.0/24"
      region = "us-central1"
      private_ip_google_access = true
    }
  }
  
  enable_nat = true
  nat_region = "us-central1"
  
  firewall_rules = {
    allow-ssh = {
      name = "allow-ssh"
      description = "Allow SSH access"
      source_ranges = ["0.0.0.0/0"]
      target_tags = ["ssh"]
      allow = [{
        protocol = "tcp"
        ports = ["22"]
      }]
    }
    allow-http = {
      name = "allow-http"
      description = "Allow HTTP access"
      source_ranges = ["0.0.0.0/0"]
      target_tags = ["web-server"]
      allow = [{
        protocol = "tcp"
        ports = ["80", "443"]
      }]
    }
  }
  
  enable_flow_logs = true
  labels = {
    environment = "production"
    project = "my-project"
  }
}
```

## 輸入變數

| 名稱 | 描述 | 類型 | 默認值 | 必需 |
|------|------|------|--------|------|
| vpc_name | VPC網路名稱 | string | - | 是 |
| vpc_description | VPC網路描述 | string | "Managed VPC network" | 否 |
| subnets | 子網路配置 | map(object) | {} | 否 |
| enable_nat | 是否啟用Cloud NAT | bool | false | 否 |
| firewall_rules | 防火牆規則配置 | map(object) | {} | 否 |
| enable_vpn_gateway | 是否啟用VPN網關 | bool | false | 否 |
| enable_private_service_connect | 是否啟用私有服務連接 | bool | false | 否 |
| enable_flow_logs | 是否啟用VPC流日誌 | bool | false | 否 |

## 輸出值

| 名稱 | 描述 |
|------|------|
| vpc_id | VPC網路ID |
| vpc_name | VPC網路名稱 |
| subnets | 子網路信息 |
| nat_router | NAT路由器信息 |
| firewall_rules | 防火牆規則信息 |
| network_summary | 網路架構摘要 |

## 範例

### 基本VPC配置

```hcl
module "basic_vpc" {
  source = "./vpc-module"
  
  vpc_name = "basic-vpc"
  
  subnets = {
    main = {
      name = "main-subnet"
      cidr = "10.0.1.0/24"
      region = "us-central1"
    }
  }
}
```

### 生產環境VPC配置

```hcl
module "production_vpc" {
  source = "./vpc-module"
  
  vpc_name = "production-vpc"
  vpc_description = "Production environment VPC"
  
  subnets = {
    public = {
      name = "public-subnet"
      cidr = "10.0.1.0/24"
      region = "us-central1"
      private_ip_google_access = true
    }
    private = {
      name = "private-subnet"
      cidr = "10.0.2.0/24"
      region = "us-central1"
      private_ip_google_access = true
    }
    database = {
      name = "database-subnet"
      cidr = "10.0.3.0/24"
      region = "us-central1"
      private_ip_google_access = true
    }
  }
  
  enable_nat = true
  nat_region = "us-central1"
  
  firewall_rules = {
    allow-ssh = {
      name = "allow-ssh"
      description = "Allow SSH from bastion"
      source_ranges = ["10.0.1.0/24"]
      target_tags = ["ssh"]
      allow = [{
        protocol = "tcp"
        ports = ["22"]
      }]
    }
    allow-internal = {
      name = "allow-internal"
      description = "Allow internal communication"
      source_ranges = ["10.0.0.0/16"]
      allow = [{
        protocol = "tcp"
        ports = ["0-65535"]
      }, {
        protocol = "udp"
        ports = ["0-65535"]
      }, {
        protocol = "icmp"
      }]
    }
  }
  
  enable_flow_logs = true
  enable_private_service_connect = true
  
  labels = {
    environment = "production"
    project = "my-project"
    managed_by = "terraform"
  }
}
```

### GKE專用VPC配置

```hcl
module "gke_vpc" {
  source = "./vpc-module"
  
  vpc_name = "gke-vpc"
  
  subnets = {
    gke-subnet = {
      name = "gke-subnet"
      cidr = "10.0.1.0/24"
      region = "us-central1"
      private_ip_google_access = true
      secondary_ranges = [
        {
          name = "pods"
          cidr = "10.1.0.0/16"
        },
        {
          name = "services"
          cidr = "10.2.0.0/20"
        }
      ]
    }
  }
  
  enable_nat = true
  enable_flow_logs = true
  
  labels = {
    environment = "production"
    purpose = "gke"
  }
}
```

## 注意事項

1. **IP範圍規劃**: 確保子網路CIDR不重疊
2. **區域配置**: 子網路必須在指定的區域內
3. **NAT配置**: NAT路由器必須在與子網路相同的區域
4. **防火牆規則**: 注意規則優先級，數字越小優先級越高
5. **VPN配置**: VPN網關和隧道需要額外的配置

## 版本要求

- Terraform >= 1.0
- Google Provider >= 4.0
