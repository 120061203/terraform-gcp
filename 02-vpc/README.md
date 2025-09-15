# 第2章：VPC網路教學

## 學習目標

完成本章後，您將能夠：
- 設計多層網路架構
- 配置VPC、子網路和路由
- 實現網路安全策略
- 設置負載平衡和NAT
- 理解網路最佳實踐

## 本章內容

### 1. 網路架構設計

本範例實現了一個三層網路架構：

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                             │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                Load Balancer                            │
│              (External IP)                             │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│              Public Subnet (DMZ)                        │
│              10.0.1.0/24                                │
│  ┌─────────────┐  ┌─────────────┐                      │
│  │ Web Server 1│  │ Web Server 2│                      │
│  │ (External IP)│  │ (External IP)│                    │
│  └─────────────┘  └─────────────┘                      │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│             Private Subnet (App Layer)                  │
│              10.0.2.0/24                                │
│  ┌─────────────┐                                       │
│  │ App Server  │                                       │
│  │ (No External IP)│                                   │
│  └─────────────┘                                       │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│            Database Subnet (Data Layer)                  │
│              10.0.3.0/24                                │
│  ┌─────────────┐                                       │
│  │ Database    │                                       │
│  │ (Future)    │                                       │
│  └─────────────┘                                       │
└─────────────────────────────────────────────────────────┘
```

### 2. 創建的資源

#### 網路資源
- **VPC網路**: 自定義VPC，不自動創建子網路
- **公共子網路**: DMZ層，放置Web服務器
- **私有子網路**: 應用層，放置應用服務器
- **數據庫子網路**: 數據層，為未來數據庫預留

#### 網路服務
- **Cloud NAT**: 為私有子網路提供出站連接
- **負載平衡器**: HTTP負載平衡，分發流量到Web服務器
- **健康檢查**: 監控Web服務器健康狀態

#### 安全資源
- **防火牆規則**: 分層安全策略
  - SSH訪問控制
  - HTTP/HTTPS公共訪問
  - 內部通信允許
  - 數據庫訪問限制
  - 默認拒絕規則

#### 計算資源
- **Web服務器**: 2個實例，在公共子網路
- **應用服務器**: 1個實例，在私有子網路
- **實例組**: 用於負載平衡

## 快速開始

### 1. 準備工作

```bash
# 確保已安裝Terraform和gcloud CLI
terraform --version
gcloud --version

# 登入GCP
gcloud auth login
gcloud auth application-default login

# 設置專案
gcloud config set project YOUR_PROJECT_ID

# 啟用必要API
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
```

### 2. 配置變數

```bash
# 複製變數範例文件
cp terraform.tfvars.example terraform.tfvars

# 編輯變數文件
nano terraform.tfvars
```

### 3. 初始化並應用

```bash
# 初始化Terraform
terraform init

# 查看計劃
terraform plan

# 應用配置
terraform apply
```

### 4. 測試網路架構

```bash
# 獲取負載平衡器IP
terraform output load_balancer_ip

# 測試負載平衡
curl http://$(terraform output -raw load_balancer_ip)

# 測試健康檢查
curl http://$(terraform output -raw load_balancer_ip)/health

# SSH到Web服務器
gcloud compute ssh $(terraform output -raw web_servers | jq -r '.server_1.name') --zone=$(terraform output -raw web_servers | jq -r '.server_1.zone')
```

## 網路架構詳解

### 1. VPC設計原則

#### 子網路分離
- **公共子網路**: 面向互聯網的資源
- **私有子網路**: 內部應用服務
- **數據庫子網路**: 數據存儲服務

#### IP地址規劃
- 使用私有IP地址範圍 (10.0.0.0/8)
- 每個子網路分配/24網段
- 預留擴展空間

### 2. 安全策略

#### 防火牆規則優先級
1. **允許SSH**: 僅從指定IP範圍
2. **允許HTTP/HTTPS**: 公共訪問
3. **允許內部通信**: 子網路間通信
4. **允許數據庫訪問**: 僅從應用層
5. **拒絕所有**: 默認拒絕規則

#### 網路分段
- 不同層級使用不同子網路
- 限制跨層級通信
- 實施最小權限原則

### 3. 負載平衡

#### HTTP負載平衡器
- 全球負載平衡
- 健康檢查監控
- 自動故障轉移

#### 後端服務
- 實例組管理
- 健康檢查配置
- 會話親和性

## 最佳實踐

### 1. 網路設計
- 使用多層架構
- 實施網路分段
- 預留擴展空間
- 文檔化IP規劃

### 2. 安全配置
- 最小權限原則
- 分層防禦策略
- 定期安全審查
- 監控異常流量

### 3. 性能優化
- 使用適當的機器類型
- 配置健康檢查
- 監控網路性能
- 優化路由配置

### 4. 成本控制
- 使用預留實例
- 監控網路使用量
- 優化負載平衡配置
- 定期清理未使用資源

## 故障排除

### 常見問題

1. **負載平衡器無法訪問**
   ```bash
   # 檢查健康檢查狀態
   gcloud compute backend-services get-health BACKEND_SERVICE_NAME --global
   
   # 檢查實例組狀態
   gcloud compute instance-groups list-instances INSTANCE_GROUP_NAME --zone=ZONE
   ```

2. **私有實例無法訪問互聯網**
   ```bash
   # 檢查NAT配置
   gcloud compute routers nats describe NAT_NAME --router=ROUTER_NAME --region=REGION
   
   # 檢查路由表
   gcloud compute routes list --filter="network:VPC_NAME"
   ```

3. **防火牆規則不生效**
   ```bash
   # 檢查防火牆規則
   gcloud compute firewall-rules list --filter="network:VPC_NAME"
   
   # 檢查實例標籤
   gcloud compute instances describe INSTANCE_NAME --zone=ZONE --format="value(tags.items)"
   ```

### 調試命令

```bash
# 檢查VPC配置
gcloud compute networks describe VPC_NAME

# 檢查子網路配置
gcloud compute networks subnets list --filter="network:VPC_NAME"

# 檢查實例網路配置
gcloud compute instances describe INSTANCE_NAME --zone=ZONE --format="value(networkInterfaces)"

# 檢查防火牆規則
gcloud compute firewall-rules list --filter="network:VPC_NAME"
```

## 進階配置

### 1. 自定義路由
```hcl
resource "google_compute_route" "custom_route" {
  name        = "custom-route"
  dest_range  = "192.168.0.0/16"
  network     = google_compute_network.main_vpc.name
  next_hop_vpn_tunnel = "vpn-tunnel-name"
}
```

### 2. VPN連接
```hcl
resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name          = "vpn-tunnel"
  peer_ip       = "PEER_IP"
  shared_secret = "SHARED_SECRET"
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gateway.name
}
```

### 3. 私有服務連接
```hcl
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main_vpc.id
}
```

## 清理資源

```bash
# 銷毀所有資源
terraform destroy

# 確認銷毀
# 輸入 yes 確認
```

## 練習題

1. **添加新的子網路**
   - 創建管理子網路 (10.0.4.0/24)
   - 添加管理服務器
   - 配置相應的防火牆規則

2. **配置VPN連接**
   - 創建VPN網關
   - 設置VPN隧道
   - 配置路由表

3. **優化負載平衡**
   - 添加SSL證書
   - 配置HTTPS重定向
   - 設置會話親和性

4. **監控和日誌**
   - 啟用VPC流日誌
   - 配置監控警報
   - 設置日誌分析

## 下一步

完成本章後，您可以：
1. 繼續學習 [第3章：Compute Engine](../03-compute/)
2. 探索 [第4章：GKE](../04-gke/)
3. 嘗試進階網路配置
4. 實施生產環境網路架構

## 參考資源

- [GCP VPC文檔](https://cloud.google.com/vpc/docs)
- [GCP負載平衡文檔](https://cloud.google.com/load-balancing/docs)
- [GCP防火牆文檔](https://cloud.google.com/vpc/docs/firewalls)
- [Terraform Google Provider文檔](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
