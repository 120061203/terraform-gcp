# 第3章：Compute Engine教學

## 學習目標

完成本章後，您將能夠：
- 創建和管理Compute Engine實例
- 配置實例組和自動擴展
- 設置負載平衡和健康檢查
- 管理磁碟和快照
- 實施監控和日誌記錄
- 理解Compute Engine最佳實踐

## 本章內容

### 1. Compute Engine概述

Google Compute Engine (GCE) 是GCP的基礎設施即服務(IaaS)產品，提供可擴展的虛擬機器。

#### 核心概念
- **實例**: 運行在GCP上的虛擬機器
- **實例模板**: 用於創建實例的模板
- **實例組**: 管理多個實例的集合
- **自動擴展**: 根據負載自動調整實例數量
- **負載平衡**: 分發流量到多個實例

### 2. 本範例創建的資源

#### 基礎設施
- **VPC網路**: 自定義網路環境
- **子網路**: 實例部署的網路段
- **防火牆規則**: 網路安全策略

#### 計算資源
- **實例模板**: 標準化的實例配置
- **實例組管理器**: 管理實例組的生命週期
- **自動擴展器**: 根據指標自動調整實例數量
- **特殊實例**: 帶有額外磁碟的實例（可選）

#### 網路服務
- **負載平衡器**: HTTP負載平衡
- **健康檢查**: 監控實例健康狀態
- **Cloud NAT**: 出站網路連接

#### 存儲資源
- **啟動磁碟**: 實例的系統磁碟
- **數據磁碟**: 額外的存儲空間（可選）
- **快照策略**: 自動備份策略（可選）

#### 安全資源
- **服務帳戶**: 實例的身份驗證
- **KMS密鑰**: 磁碟加密（可選）
- **防火牆規則**: 網路訪問控制

#### 監控資源
- **監控警報**: CPU使用率警報
- **日誌收集**: 實例日誌收集
- **健康檢查**: 實例健康監控

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
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
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

### 4. 測試部署

```bash
# 獲取負載平衡器IP
terraform output load_balancer_ip

# 測試負載平衡
curl http://$(terraform output -raw load_balancer_ip)

# 測試健康檢查
curl http://$(terraform output -raw load_balancer_ip)/health

# 檢查實例組狀態
gcloud compute instance-groups list-instances $(terraform output -raw instance_group_manager | jq -r '.name') --zone=$(terraform output -raw instance_group_manager | jq -r '.zone')
```

## 架構詳解

### 1. 實例組架構

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                             │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                Load Balancer                            │
│              (Global HTTP LB)                           │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│              Instance Group Manager                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │ Instance 1  │  │ Instance 2  │  │ Instance N  │    │
│  │ (Auto-scaled)│  │ (Auto-scaled)│  │ (Auto-scaled)│    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### 2. 自動擴展策略

#### CPU使用率擴展
- 目標CPU使用率: 60%
- 最小實例數: 1
- 最大實例數: 5
- 冷卻期: 60秒

#### 負載平衡使用率擴展
- 目標負載使用率: 80%
- 基於後端服務的負載

### 3. 健康檢查機制

#### HTTP健康檢查
- 檢查路徑: `/health`
- 檢查間隔: 5秒
- 超時時間: 5秒
- 健康閾值: 2次成功
- 不健康閾值: 3次失敗

## 最佳實踐

### 1. 實例管理
- 使用實例模板確保一致性
- 實施自動擴展以應對負載變化
- 定期更新實例映像
- 使用預留實例降低成本

### 2. 安全配置
- 使用服務帳戶進行身份驗證
- 啟用磁碟加密
- 限制SSH訪問來源
- 定期更新系統和軟體

### 3. 監控和日誌
- 設置監控警報
- 收集和分析日誌
- 監控關鍵指標
- 設置自動化響應

### 4. 成本優化
- 使用適當的機器類型
- 實施自動擴展
- 使用預留實例
- 監控資源使用情況

## 進階配置

### 1. 自定義啟動腳本

啟動腳本包含：
- 系統更新和軟體安裝
- Nginx配置
- 健康檢查端點
- 監控工具安裝
- 日誌配置

### 2. 磁碟管理

#### 啟動磁碟
- 自動刪除策略
- 加密配置
- 大小和類型配置

#### 數據磁碟
- 持久化存儲
- 掛載配置
- 備份策略

### 3. 網路配置

#### 網路介面
- 內部IP配置
- 外部IP分配
- 網路標籤

#### 防火牆規則
- SSH訪問控制
- HTTP/HTTPS訪問
- 自定義端口配置

## 故障排除

### 常見問題

1. **實例無法啟動**
   ```bash
   # 檢查實例狀態
   gcloud compute instances describe INSTANCE_NAME --zone=ZONE
   
   # 查看啟動日誌
   gcloud compute instances get-serial-port-output INSTANCE_NAME --zone=ZONE
   ```

2. **負載平衡器無法訪問**
   ```bash
   # 檢查後端服務健康狀態
   gcloud compute backend-services get-health BACKEND_SERVICE_NAME --global
   
   # 檢查實例組狀態
   gcloud compute instance-groups list-instances INSTANCE_GROUP_NAME --zone=ZONE
   ```

3. **自動擴展不工作**
   ```bash
   # 檢查自動擴展器狀態
   gcloud compute autoscalers describe AUTOSCALER_NAME --zone=ZONE
   
   # 檢查實例組狀態
   gcloud compute instance-groups list-instances INSTANCE_GROUP_NAME --zone=ZONE
   ```

### 調試命令

```bash
# 檢查實例狀態
gcloud compute instances list --filter="name:INSTANCE_NAME"

# 檢查實例組狀態
gcloud compute instance-groups list-instances INSTANCE_GROUP_NAME --zone=ZONE

# 檢查負載平衡器狀態
gcloud compute backend-services list --global

# 檢查健康檢查狀態
gcloud compute health-checks list

# 檢查自動擴展器狀態
gcloud compute autoscalers list --zone=ZONE
```

## 性能優化

### 1. 實例性能
- 選擇適當的機器類型
- 使用SSD磁碟提高I/O性能
- 配置CPU和記憶體優化

### 2. 網路性能
- 使用負載平衡器分發流量
- 配置健康檢查避免故障實例
- 優化防火牆規則

### 3. 存儲性能
- 使用SSD磁碟提高性能
- 實施磁碟加密
- 配置自動備份

## 安全最佳實踐

### 1. 身份驗證
- 使用服務帳戶
- 實施最小權限原則
- 定期輪換密鑰

### 2. 網路安全
- 限制SSH訪問
- 使用防火牆規則
- 實施網路分段

### 3. 數據保護
- 啟用磁碟加密
- 實施備份策略
- 監控數據訪問

## 清理資源

```bash
# 銷毀所有資源
terraform destroy

# 確認銷毀
# 輸入 yes 確認
```

## 練習題

1. **修改自動擴展配置**
   - 調整CPU使用率閾值
   - 修改最小/最大實例數
   - 測試擴展行為

2. **添加新的實例模板**
   - 創建不同配置的模板
   - 配置不同的啟動腳本
   - 測試模板切換

3. **配置監控警報**
   - 添加記憶體使用率警報
   - 配置磁碟使用率警報
   - 設置通知頻道

4. **實施備份策略**
   - 啟用快照策略
   - 配置定期備份
   - 測試恢復流程

## 下一步

完成本章後，您可以：
1. 繼續學習 [第4章：GKE](../04-gke/)
2. 探索 [第5章：Cloud SQL](../05-database/)
3. 嘗試進階Compute Engine配置
4. 實施生產環境部署

## 參考資源

- [GCP Compute Engine文檔](https://cloud.google.com/compute/docs)
- [GCP負載平衡文檔](https://cloud.google.com/load-balancing/docs)
- [GCP監控文檔](https://cloud.google.com/monitoring/docs)
- [Terraform Google Provider文檔](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
