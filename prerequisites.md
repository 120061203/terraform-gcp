# 前置需求

## 系統需求

### 作業系統
- macOS 10.14+
- Linux (Ubuntu 18.04+, CentOS 7+)
- Windows 10+ (使用WSL2推薦)

### 硬體需求
- 至少4GB RAM
- 10GB可用磁碟空間
- 穩定的網路連線

## 軟體安裝

### 1. Terraform

#### macOS (使用Homebrew)
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

#### Linux (Ubuntu/Debian)
```bash
# 添加HashiCorp GPG密鑰
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# 添加HashiCorp倉庫
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# 安裝Terraform
sudo apt-get update && sudo apt-get install terraform
```

#### Windows
```powershell
# 使用Chocolatey
choco install terraform

# 或下載二進制文件
# 從 https://www.terraform.io/downloads 下載
```

### 2. Google Cloud CLI

#### macOS
```bash
brew install google-cloud-sdk
```

#### Linux
```bash
# 下載並安裝
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

#### Windows
```powershell
# 下載安裝程式
# 從 https://cloud.google.com/sdk/docs/install 下載
```

### 3. Git (可選但推薦)
```bash
# macOS
brew install git

# Linux
sudo apt-get install git

# Windows
# 從 https://git-scm.com/download/win 下載
```

## GCP帳戶設置

### 1. 創建GCP專案
1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 創建新專案或選擇現有專案
3. 記下專案ID

### 2. 啟用必要API
```bash
# 登入GCP
gcloud auth login

# 設置預設專案
gcloud config set project YOUR_PROJECT_ID

# 啟用必要API
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

### 3. 創建服務帳戶
```bash
# 創建服務帳戶
gcloud iam service-accounts create terraform-sa \
    --description="Service account for Terraform" \
    --display-name="Terraform Service Account"

# 分配必要權限
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"

# 創建密鑰文件
gcloud iam service-accounts keys create terraform-sa-key.json \
    --iam-account=terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### 4. 設置認證
```bash
# 方法1：使用服務帳戶密鑰
export GOOGLE_APPLICATION_CREDENTIALS="path/to/terraform-sa-key.json"

# 方法2：使用gcloud認證
gcloud auth application-default login
```

## 驗證安裝

### 檢查Terraform
```bash
terraform --version
# 應該顯示類似：Terraform v1.5.0
```

### 檢查Google Cloud CLI
```bash
gcloud --version
# 應該顯示gcloud版本信息
```

### 檢查GCP認證
```bash
gcloud auth list
# 應該顯示已認證的帳戶
```

### 檢查專案設置
```bash
gcloud config list
# 應該顯示當前專案和其他設置
```

## 常見問題

### Q: Terraform init失敗
A: 檢查網路連線和防火牆設置，確保可以訪問registry.terraform.io

### Q: GCP認證失敗
A: 確保服務帳戶有足夠權限，或重新運行 `gcloud auth application-default login`

### Q: API未啟用錯誤
A: 確保已啟用所有必要的GCP API服務

### Q: 專案ID錯誤
A: 檢查專案ID是否正確，可以在GCP控制台確認

## 下一步

完成前置需求設置後，您可以開始：
1. 閱讀 [README.md](README.md) 了解專案結構
2. 從 [01-basics](01-basics/) 開始基礎教學
3. 按照章節順序逐步學習

## 支援

如果遇到問題，請：
1. 檢查本文件中的常見問題
2. 查看Terraform和GCP官方文檔
3. 在專案中提交Issue
