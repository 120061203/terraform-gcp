# 第1章：Terraform基礎教學

## 學習目標

完成本章後，您將能夠：
- 理解Terraform的基本概念和工作流程
- 創建和管理GCP基礎資源
- 使用變數和輸出
- 理解Terraform狀態管理

## 本章內容

### 1. Terraform基礎概念

#### 什麼是Terraform？
Terraform是一個開源的基礎設施即代碼(IaC)工具，由HashiCorp開發。它允許您使用聲明式配置語言來定義和管理雲端基礎設施。

#### 核心概念
- **Provider**: 與特定雲端平台或服務的接口
- **Resource**: 要創建的基礎設施組件
- **Variable**: 可配置的參數
- **Output**: 執行後的重要信息
- **State**: 當前基礎設施的狀態記錄

### 2. 本範例創建的資源

本範例將創建以下GCP資源：

1. **VPC網路** (`google_compute_network`)
   - 自定義VPC網路
   - 不自動創建子網路

2. **子網路** (`google_compute_subnetwork`)
   - 在VPC內創建子網路
   - 啟用私有IP Google訪問

3. **防火牆規則** (`google_compute_firewall`)
   - SSH訪問 (port 22)
   - HTTP訪問 (port 80)
   - HTTPS訪問 (port 443)

4. **Compute Engine實例** (`google_compute_instance`)
   - Ubuntu 20.04 LTS
   - 自動安裝Nginx
   - 分配外部IP

5. **服務帳戶** (`google_service_account`)
   - 為實例提供身份驗證

6. **Storage Bucket** (`google_storage_bucket`)
   - 數據存儲
   - 版本控制
   - 生命週期管理

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
```

### 2. 配置變數

```bash
# 複製變數範例文件
cp terraform.tfvars.example terraform.tfvars

# 編輯變數文件，填入您的專案ID
nano terraform.tfvars
```

### 3. 初始化Terraform

```bash
# 初始化Terraform工作目錄
terraform init
```

這會：
- 下載Google Provider
- 創建`.terraform`目錄
- 初始化後端（如果配置了）

### 4. 檢查計劃

```bash
# 查看Terraform計劃
terraform plan
```

這會顯示：
- 將要創建的資源
- 資源的配置
- 預估的變更

### 5. 應用變更

```bash
# 應用Terraform配置
terraform apply
```

輸入 `yes` 確認創建資源。

### 6. 查看輸出

```bash
# 查看輸出信息
terraform output
```

## 重要命令

### Terraform基本命令

```bash
# 初始化
terraform init

# 格式化代碼
terraform fmt

# 驗證配置
terraform validate

# 查看計劃
terraform plan

# 應用變更
terraform apply

# 查看狀態
terraform show

# 查看輸出
terraform output

# 銷毀資源
terraform destroy
```

### 狀態管理

```bash
# 查看狀態列表
terraform state list

# 查看特定資源狀態
terraform state show google_compute_instance.web_server

# 刷新狀態
terraform refresh

# 導入現有資源
terraform import google_compute_instance.web_server projects/PROJECT/zones/ZONE/instances/INSTANCE
```

## 代碼解析

### Provider配置

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
```

- 配置Google Cloud Provider
- 使用變數指定專案、區域和可用區

### 資源創建

```hcl
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  description             = "Main VPC for ${var.project_name}"
}
```

- 創建VPC網路
- 使用字串插值組合變數值
- 設置資源屬性

### 資源依賴

```hcl
resource "google_compute_subnetwork" "main" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id  # 依賴VPC
}
```

- 子網路依賴VPC網路
- 使用 `google_compute_network.main.id` 引用VPC

## 最佳實踐

### 1. 變數使用
- 使用有意義的變數名稱
- 提供描述和驗證規則
- 設置合理的預設值

### 2. 資源命名
- 使用一致的命名規範
- 包含環境或專案前綴
- 使用描述性的名稱

### 3. 標籤和標記
- 為資源添加標籤
- 便於資源管理和計費

### 4. 安全考慮
- 限制SSH訪問來源
- 使用最小權限原則
- 定期更新映像

## 故障排除

### 常見問題

1. **Provider認證失敗**
   ```bash
   # 重新認證
   gcloud auth application-default login
   ```

2. **API未啟用**
   ```bash
   # 啟用必要API
   gcloud services enable compute.googleapis.com
   ```

3. **資源名稱衝突**
   - 檢查資源名稱是否唯一
   - 使用隨機後綴

4. **權限不足**
   - 檢查服務帳戶權限
   - 確保有足夠的IAM角色

### 調試技巧

```bash
# 詳細輸出
terraform apply -auto-approve -var-file="terraform.tfvars"

# 調試模式
export TF_LOG=DEBUG
terraform apply

# 查看詳細計劃
terraform plan -detailed-exitcode
```

## 清理資源

```bash
# 銷毀所有資源
terraform destroy

# 確認銷毀
# 輸入 yes 確認
```

## 下一步

完成本章後，您可以：
1. 繼續學習 [第2章：VPC網路](../02-vpc/)
2. 嘗試修改配置並重新應用
3. 探索Terraform的其他功能

## 練習題

1. 修改機器類型為 `e2-small` 並重新應用
2. 添加新的防火牆規則允許ICMP
3. 創建第二個子網路
4. 為實例添加額外的磁碟

## 參考資源

- [Terraform Google Provider文檔](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Compute Engine文檔](https://cloud.google.com/compute/docs)
- [Terraform最佳實踐](https://www.terraform.io/docs/cloud/guides/recommended-practices/)
