# 第4章：Google Kubernetes Engine (GKE) 教學

## 學習目標

完成本章後，您將能夠：
- 創建和管理GKE集群
- 配置節點池和自動擴展
- 部署Kubernetes應用
- 設置Ingress和負載平衡
- 實施監控和日誌記錄
- 理解Kubernetes最佳實踐

## 本章內容

### 1. GKE概述

Google Kubernetes Engine (GKE) 是GCP的託管Kubernetes服務，提供：
- 託管的Kubernetes控制平面
- 自動節點管理和更新
- 集成的監控和日誌
- 網路和安全功能

#### 核心概念
- **集群**: Kubernetes集群實例
- **節點池**: 管理一組相同配置的節點
- **Pod**: Kubernetes的最小部署單位
- **Service**: 提供穩定的網路端點
- **Ingress**: 管理外部訪問

### 2. 本範例創建的資源

#### 基礎設施
- **VPC網路**: 專用網路環境
- **子網路**: 包含Pod和服務IP範圍
- **Cloud NAT**: 出站網路連接
- **防火牆規則**: 網路安全策略

#### GKE集群
- **GKE集群**: 託管的Kubernetes集群
- **主節點池**: 標準工作負載節點
- **Spot節點池**: 成本優化的Spot實例（可選）
- **自動擴展**: 集群和節點池自動擴展

#### Kubernetes資源
- **命名空間**: 應用隔離
- **部署**: Nginx應用部署
- **服務**: ClusterIP服務
- **Ingress**: 外部訪問入口
- **HPA**: 水平Pod自動擴展
- **PDB**: Pod中斷預算

#### 配置資源
- **ConfigMap**: 應用配置
- **Secret**: 敏感數據存儲
- **服務帳戶**: 身份驗證

## 快速開始

### 1. 準備工作

```bash
# 確保已安裝Terraform、gcloud和kubectl
terraform --version
gcloud --version
kubectl version --client

# 登入GCP
gcloud auth login
gcloud auth application-default login

# 設置專案
gcloud config set project YOUR_PROJECT_ID

# 啟用必要API
gcloud services enable container.googleapis.com
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

### 4. 配置kubectl

```bash
# 獲取集群憑證
gcloud container clusters get-credentials $(terraform output -raw cluster_name) --region $(terraform output -raw cluster_location)

# 驗證連接
kubectl get nodes
kubectl get pods -A
```

### 5. 測試部署

```bash
# 獲取Ingress IP
terraform output ingress_ip

# 測試應用（需要配置DNS或修改hosts文件）
curl http://$(terraform output -raw ingress_ip)

# 檢查Pod狀態
kubectl get pods -n $(terraform output -raw kubernetes_resources | jq -r '.namespace.name')

# 檢查服務
kubectl get services -n $(terraform output -raw kubernetes_resources | jq -r '.namespace.name')

# 檢查Ingress
kubectl get ingress -n $(terraform output -raw kubernetes_resources | jq -r '.namespace.name')
```

## 架構詳解

### 1. GKE集群架構

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                             │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                Ingress Controller                       │
│              (Google Cloud Load Balancer)               │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│              GKE Cluster                                │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Control Plane                      │   │
│  │         (Managed by Google)                     │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Node Pool 1                        │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐          │   │
│  │  │ Node 1  │ │ Node 2  │ │ Node N  │          │   │
│  │  └─────────┘ └─────────┘ └─────────┘          │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Spot Node Pool                     │   │
│  │  ┌─────────┐ ┌─────────┐                       │   │
│  │  │Spot Node│ │Spot Node│                       │   │
│  │  └─────────┘ └─────────┘                       │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 2. 網路架構

#### IP範圍分配
- **子網路**: 10.0.1.0/24 (節點IP)
- **Pod CIDR**: 10.1.0.0/16 (Pod IP)
- **服務CIDR**: 10.2.0.0/20 (服務IP)
- **集群CIDR**: 10.3.0.0/16 (集群內部)
- **主節點CIDR**: 172.16.0.0/28 (控制平面)

#### 網路策略
- 啟用網路策略插件
- 實施Pod間通信控制
- 配置服務網格（可選）

### 3. 自動擴展策略

#### 集群自動擴展
- CPU資源限制: 1-10個CPU
- 記憶體資源限制: 1-20GB
- 自動節點管理

#### 節點池自動擴展
- 最小節點數: 1
- 最大節點數: 5
- 基於資源使用率

#### Pod自動擴展 (HPA)
- CPU使用率閾值: 50%
- 最小副本數: 1
- 最大副本數: 10

## 最佳實踐

### 1. 集群設計
- 使用私有集群提高安全性
- 配置適當的IP範圍
- 啟用網路策略
- 使用工作負載身份

### 2. 節點管理
- 使用多個節點池
- 配置自動擴展
- 啟用自動修復和更新
- 使用適當的機器類型

### 3. 應用部署
- 使用命名空間隔離
- 配置資源限制
- 實施健康檢查
- 使用ConfigMap和Secret

### 4. 監控和日誌
- 啟用集群監控
- 配置日誌收集
- 設置警報
- 監控資源使用

## 進階配置

### 1. 多節點池策略

#### 主節點池
- 標準工作負載
- 穩定的實例類型
- 自動擴展

#### Spot節點池
- 成本優化工作負載
- 可搶占實例
- 無狀態應用

### 2. 安全配置

#### 工作負載身份
- Pod到GCP服務的身份驗證
- 無需密鑰管理
- 細粒度權限控制

#### 網路策略
- Pod間通信控制
- 基於標籤的規則
- 默認拒絕策略

### 3. 監控和可觀測性

#### 集群監控
- 節點健康狀態
- Pod資源使用
- 應用性能指標

#### 日誌收集
- 應用日誌
- 系統日誌
- 審計日誌

## 故障排除

### 常見問題

1. **集群創建失敗**
   ```bash
   # 檢查API是否啟用
   gcloud services list --enabled | grep container
   
   # 檢查配額
   gcloud compute project-info describe --project=PROJECT_ID
   ```

2. **節點無法加入集群**
   ```bash
   # 檢查節點狀態
   kubectl get nodes
   
   # 檢查節點事件
   kubectl describe node NODE_NAME
   ```

3. **Pod無法啟動**
   ```bash
   # 檢查Pod狀態
   kubectl get pods -n NAMESPACE
   
   # 檢查Pod事件
   kubectl describe pod POD_NAME -n NAMESPACE
   
   # 檢查Pod日誌
   kubectl logs POD_NAME -n NAMESPACE
   ```

4. **Ingress無法訪問**
   ```bash
   # 檢查Ingress狀態
   kubectl get ingress -n NAMESPACE
   
   # 檢查Ingress事件
   kubectl describe ingress INGRESS_NAME -n NAMESPACE
   
   # 檢查負載平衡器
   gcloud compute forwarding-rules list --global
   ```

### 調試命令

```bash
# 檢查集群狀態
gcloud container clusters describe CLUSTER_NAME --region=REGION

# 檢查節點池狀態
gcloud container node-pools list --cluster=CLUSTER_NAME --region=REGION

# 檢查Kubernetes資源
kubectl get all -A

# 檢查事件
kubectl get events --sort-by=.metadata.creationTimestamp

# 檢查資源使用
kubectl top nodes
kubectl top pods -A
```

## 性能優化

### 1. 集群性能
- 選擇適當的機器類型
- 配置資源限制
- 使用本地SSD
- 優化網路配置

### 2. 應用性能
- 配置資源請求
- 使用HPA自動擴展
- 實施健康檢查
- 優化映像大小

### 3. 成本優化
- 使用Spot實例
- 配置自動擴展
- 監控資源使用
- 實施Pod中斷預算

## 安全最佳實踐

### 1. 集群安全
- 使用私有集群
- 啟用RBAC
- 配置網路策略
- 定期更新

### 2. 工作負載安全
- 使用工作負載身份
- 實施最小權限
- 掃描映像漏洞
- 加密敏感數據

### 3. 網路安全
- 配置防火牆規則
- 使用VPC網路
- 實施網路分段
- 監控網路流量

## 清理資源

```bash
# 銷毀所有資源
terraform destroy

# 確認銷毀
# 輸入 yes 確認
```

## 練習題

1. **創建多環境部署**
   - 創建dev和prod命名空間
   - 部署不同版本的應用
   - 配置環境特定的配置

2. **實施CI/CD**
   - 設置GitHub Actions
   - 自動部署到GKE
   - 實施藍綠部署

3. **配置監控**
   - 設置Prometheus和Grafana
   - 配置自定義指標
   - 創建儀表板

4. **實施服務網格**
   - 部署Istio
   - 配置流量管理
   - 實施安全策略

## 下一步

完成本章後，您可以：
1. 繼續學習 [第5章：Cloud SQL](../05-database/)
2. 探索 [第6章：模組化設計](../06-modules/)
3. 嘗試進階Kubernetes配置
4. 實施生產環境部署

## 參考資源

- [GCP GKE文檔](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes官方文檔](https://kubernetes.io/docs/)
- [GCP負載平衡文檔](https://cloud.google.com/load-balancing/docs)
- [Terraform Google Provider文檔](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
