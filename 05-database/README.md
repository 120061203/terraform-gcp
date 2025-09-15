# 第5章：Cloud SQL教學

## 學習目標

完成本章後，您將能夠：
- 創建和管理Cloud SQL實例
- 配置多種數據庫引擎（PostgreSQL、MySQL、SQL Server）
- 設置高可用性和備份策略
- 實施數據庫安全和加密
- 配置監控和日誌記錄
- 理解數據庫最佳實踐

## 本章內容

### 1. Cloud SQL概述

Google Cloud SQL是GCP的託管關聯式數據庫服務，支持：
- PostgreSQL
- MySQL
- SQL Server

#### 核心特性
- 自動備份和時間點恢復
- 自動故障轉移
- 讀取副本
- 自動擴展存儲
- 加密和合規性

### 2. 本範例創建的資源

#### 基礎設施
- **VPC網路**: 專用數據庫網路
- **子網路**: 數據庫部署網段
- **私有服務連接**: 與GCP服務的私有連接
- **Cloud NAT**: 出站網路連接
- **防火牆規則**: 網路安全策略

#### 數據庫實例
- **PostgreSQL實例**: 主要數據庫實例
- **MySQL實例**: 可選的MySQL實例
- **SQL Server實例**: 可選的SQL Server實例
- **讀取副本**: PostgreSQL讀取副本（可選）

#### 數據庫資源
- **數據庫**: 為每個實例創建的數據庫
- **用戶**: 數據庫用戶和權限
- **連接字符串**: 數據庫連接信息

#### 安全資源
- **KMS密鑰**: 數據庫加密密鑰
- **服務帳戶**: 數據庫操作身份
- **SSL證書**: 安全連接

#### 監控資源
- **監控警報**: CPU和磁碟使用率警報
- **日誌收集**: 數據庫操作日誌
- **備份策略**: 自動備份配置

#### 代理資源
- **SQL代理實例**: 用於安全連接的代理服務器

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
gcloud services enable sqladmin.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
```

### 2. 配置變數

```bash
# 複製變數範例文件
cp terraform.tfvars.example terraform.tfvars

# 編輯變數文件，設置密碼
nano terraform.tfvars
```

**重要**: 設置強密碼：
```hcl
postgres_password = "your-secure-postgres-password"
mysql_password    = "your-secure-mysql-password"
sqlserver_password = "your-secure-sqlserver-password"
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

### 4. 測試數據庫連接

```bash
# 通過Cloud SQL代理連接PostgreSQL
gcloud sql connect $(terraform output -raw postgres_instance | jq -r '.name') --user=$(terraform output -raw postgres_user | jq -r '.name') --database=$(terraform output -raw postgres_database | jq -r '.name')

# 如果啟用了SQL代理實例
terraform output ssh_commands
# SSH到代理實例
gcloud compute ssh $(terraform output -raw sql_proxy_instance | jq -r '.name') --zone=$(terraform output -raw sql_proxy_instance | jq -r '.zone')

# 在代理實例上測試連接
/opt/cloudsql-proxy/test_connections.sh
```

## 架構詳解

### 1. 數據庫架構

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                             │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│              VPC Network                                │
│  ┌─────────────────────────────────────────────────┐   │
│  │            Database Subnet                       │   │
│  │  ┌─────────────┐  ┌─────────────┐              │   │
│  │  │ PostgreSQL  │  │ MySQL       │              │   │
│  │  │ Instance    │  │ Instance    │              │   │
│  │  │ (Private)   │  │ (Private)   │              │   │
│  │  └─────────────┘  └─────────────┘              │   │
│  │  ┌─────────────┐  ┌─────────────┐              │   │
│  │  │ SQL Server  │  │ Read Replica│              │   │
│  │  │ Instance    │  │ (Optional)  │              │   │
│  │  │ (Private)   │  │ (Private)   │              │   │
│  │  └─────────────┘  └─────────────┘              │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │            SQL Proxy Instance                    │   │
│  │         (Optional, for external access)        │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 2. 安全架構

#### 網路安全
- 私有IP地址
- VPC網路隔離
- 防火牆規則
- SSL/TLS加密

#### 數據安全
- 靜態數據加密
- 傳輸中加密
- KMS密鑰管理
- 訪問控制

#### 身份安全
- 服務帳戶
- IAM角色
- 最小權限原則

### 3. 高可用性配置

#### 可用性類型
- **ZONAL**: 單可用區部署
- **REGIONAL**: 跨可用區高可用部署

#### 備份策略
- 自動備份
- 時間點恢復
- 事務日誌保留
- 備份保留策略

#### 讀取副本
- 異步複製
- 負載分散
- 災難恢復

## 最佳實踐

### 1. 數據庫設計
- 選擇適當的機器類型
- 配置自動存儲擴展
- 設置維護窗口
- 啟用監控和日誌

### 2. 安全配置
- 使用私有IP
- 啟用SSL連接
- 實施加密
- 定期更新密碼

### 3. 備份策略
- 配置自動備份
- 設置適當的保留期
- 測試恢復流程
- 監控備份狀態

### 4. 性能優化
- 選擇適當的機器類型
- 配置讀取副本
- 優化查詢
- 監控性能指標

## 進階配置

### 1. 多數據庫引擎

#### PostgreSQL
- 支持最新版本
- 豐富的擴展
- 強大的JSON支持
- 地理空間功能

#### MySQL
- 廣泛的兼容性
- 高性能
- 複製功能
- 分區支持

#### SQL Server
- 企業級功能
- 商業智能
- 高可用性
- 安全性

### 2. 高可用性配置

#### 區域高可用性
- 自動故障轉移
- 跨可用區部署
- 數據同步
- 快速恢復

#### 讀取副本
- 異步複製
- 負載分散
- 災難恢復
- 地理分布

### 3. 監控和可觀測性

#### 性能監控
- CPU使用率
- 記憶體使用率
- 磁碟I/O
- 網路流量

#### 日誌記錄
- 慢查詢日誌
- 錯誤日誌
- 審計日誌
- 連接日誌

## 故障排除

### 常見問題

1. **數據庫實例創建失敗**
   ```bash
   # 檢查API是否啟用
   gcloud services list --enabled | grep sqladmin
   
   # 檢查配額
   gcloud compute project-info describe --project=PROJECT_ID
   ```

2. **私有服務連接失敗**
   ```bash
   # 檢查服務網路連接
   gcloud services peered-dns-domains list --network=VPC_NAME
   
   # 檢查私有IP分配
   gcloud compute addresses list --global --filter="purpose=VPC_PEERING"
   ```

3. **數據庫連接失敗**
   ```bash
   # 檢查實例狀態
   gcloud sql instances describe INSTANCE_NAME
   
   # 檢查連接字符串
   gcloud sql instances describe INSTANCE_NAME --format="value(connectionName)"
   ```

4. **SSL連接問題**
   ```bash
   # 檢查SSL證書
   gcloud sql ssl-certs list --instance=INSTANCE_NAME
   
   # 下載客戶端證書
   gcloud sql ssl-certs create client-cert --instance=INSTANCE_NAME
   ```

### 調試命令

```bash
# 檢查實例狀態
gcloud sql instances list

# 檢查數據庫
gcloud sql databases list --instance=INSTANCE_NAME

# 檢查用戶
gcloud sql users list --instance=INSTANCE_NAME

# 檢查備份
gcloud sql backups list --instance=INSTANCE_NAME

# 檢查操作
gcloud sql operations list --instance=INSTANCE_NAME
```

## 性能優化

### 1. 實例性能
- 選擇適當的機器類型
- 配置SSD存儲
- 啟用自動擴展
- 監控資源使用

### 2. 查詢性能
- 使用索引
- 優化查詢
- 分析執行計劃
- 監控慢查詢

### 3. 網路性能
- 使用私有IP
- 配置適當的網路
- 監控網路延遲
- 優化連接池

## 安全最佳實踐

### 1. 網路安全
- 使用私有網路
- 配置防火牆規則
- 限制訪問來源
- 監控網路流量

### 2. 數據安全
- 啟用加密
- 使用KMS密鑰
- 定期輪換密鑰
- 監控數據訪問

### 3. 訪問控制
- 使用IAM角色
- 實施最小權限
- 定期審計權限
- 監控異常訪問

## 清理資源

```bash
# 銷毀所有資源
terraform destroy

# 確認銷毀
# 輸入 yes 確認
```

## 練習題

1. **配置多數據庫環境**
   - 啟用MySQL和SQL Server
   - 配置不同的用戶和權限
   - 測試跨數據庫操作

2. **實施高可用性**
   - 配置區域高可用性
   - 創建讀取副本
   - 測試故障轉移

3. **設置監控和警報**
   - 配置自定義監控指標
   - 設置性能警報
   - 創建監控儀表板

4. **實施備份策略**
   - 配置自動備份
   - 測試時間點恢復
   - 設置備份驗證

## 下一步

完成本章後，您可以：
1. 繼續學習 [第6章：模組化設計](../06-modules/)
2. 探索 [第7章：生產環境](../07-production/)
3. 嘗試進階數據庫配置
4. 實施生產環境數據庫架構

## 參考資源

- [GCP Cloud SQL文檔](https://cloud.google.com/sql/docs)
- [PostgreSQL文檔](https://www.postgresql.org/docs/)
- [MySQL文檔](https://dev.mysql.com/doc/)
- [SQL Server文檔](https://docs.microsoft.com/en-us/sql/)
- [Terraform Google Provider文檔](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
