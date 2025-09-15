# GCP Terraform 教學專案

## 專案概述

這是一個完整的Google Cloud Platform (GCP) Terraform教學專案，適合初學者到中級使用者學習如何使用Terraform管理GCP基礎設施。

## 學習目標

完成本教學後，您將能夠：
- 理解Terraform的基本概念和工作流程
- 使用Terraform創建和管理GCP資源
- 掌握Terraform的最佳實踐
- 設計可重複使用的Terraform模組
- 實施基礎設施即代碼(IaC)策略

## 專案結構

```
terraform-gcp/
├── README.md                    # 本文件
├── prerequisites.md             # 前置需求
├── 01-basics/                   # 基礎教學
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── 02-vpc/                      # VPC網路教學
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 03-compute/                  # Compute Engine教學
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 04-gke/                      # Google Kubernetes Engine教學
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 05-database/                 # Cloud SQL教學
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 06-modules/                  # 自定義模組
│   ├── vpc-module/
│   ├── compute-module/
│   └── database-module/
├── 07-production/               # 生產環境範例
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── modules/
├── exercises/                   # 練習題
│   ├── exercise-1.md
│   ├── exercise-2.md
│   └── solutions/
└── scripts/                     # 輔助腳本
    ├── setup.sh
    └── cleanup.sh
```

## 教學進度

### 第1章：基礎概念 (01-basics)
- Terraform安裝與配置
- Provider配置
- 基本資源創建
- State管理

### 第2章：網路基礎 (02-vpc)
- VPC創建與配置
- 子網路設計
- 防火牆規則
- 路由表配置

### 第3章：計算資源 (03-compute)
- Compute Engine實例
- 磁碟管理
- 負載平衡器
- 自動擴展組

### 第4章：容器服務 (04-gke)
- GKE集群創建
- Node Pool配置
- 服務與部署
- Ingress配置

### 第5章：資料庫服務 (05-database)
- Cloud SQL實例
- 資料庫創建
- 備份策略
- 高可用性配置

### 第6章：模組化設計 (06-modules)
- 自定義模組創建
- 模組重用
- 版本控制
- 模組測試

### 第7章：生產環境 (07-production)
- 環境分離
- 變數管理
- 安全最佳實踐
- CI/CD整合

## 快速開始

1. **安裝前置需求**
   ```bash
   # 安裝Terraform
   brew install terraform
   
   # 安裝Google Cloud CLI
   brew install google-cloud-sdk
   
   # 驗證安裝
   terraform --version
   gcloud --version
   ```

2. **配置GCP認證**
   ```bash
   # 登入GCP
   gcloud auth login
   
   # 設置專案
   gcloud config set project YOUR_PROJECT_ID
   
   # 啟用必要API
   gcloud services enable compute.googleapis.com
   gcloud services enable container.googleapis.com
   gcloud services enable sqladmin.googleapis.com
   ```

3. **開始第一個範例**
   ```bash
   cd 01-basics
   cp terraform.tfvars.example terraform.tfvars
   # 編輯terraform.tfvars，填入您的專案ID
   terraform init
   terraform plan
   terraform apply
   ```

## 重要注意事項

⚠️ **成本警告**：本教學會創建實際的GCP資源，可能產生費用。請確保：
- 使用免費試用額度
- 完成練習後及時清理資源
- 監控GCP控制台的費用

## 清理資源

每個章節都提供清理腳本：
```bash
# 清理特定章節的資源
cd 01-basics
terraform destroy

# 或使用全域清理腳本
./scripts/cleanup.sh
```

## 學習資源

- [Terraform官方文檔](https://www.terraform.io/docs/)
- [GCP Provider文檔](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform最佳實踐](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

## 貢獻

歡迎提交Issue和Pull Request來改進這個教學專案。

## 授權

MIT License
