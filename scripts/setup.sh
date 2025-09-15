#!/bin/bash
# Terraform GCP 教學專案設置腳本
# 自動化設置開發環境和前置需求

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日誌函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 未安裝"
        return 1
    fi
    return 0
}

# 檢查Terraform安裝
check_terraform() {
    log_info "檢查Terraform安裝..."
    if check_command terraform; then
        TERRAFORM_VERSION=$(terraform --version | head -n1 | cut -d' ' -f2)
        log_success "Terraform已安裝: $TERRAFORM_VERSION"
    else
        log_error "Terraform未安裝，請先安裝Terraform"
        log_info "安裝方法："
        log_info "  macOS: brew install terraform"
        log_info "  Linux: 參考 https://www.terraform.io/downloads"
        exit 1
    fi
}

# 檢查Google Cloud CLI安裝
check_gcloud() {
    log_info "檢查Google Cloud CLI安裝..."
    if check_command gcloud; then
        GCLOUD_VERSION=$(gcloud --version | head -n1 | cut -d' ' -f4)
        log_success "Google Cloud CLI已安裝: $GCLOUD_VERSION"
    else
        log_error "Google Cloud CLI未安裝，請先安裝gcloud"
        log_info "安裝方法："
        log_info "  macOS: brew install google-cloud-sdk"
        log_info "  Linux: 參考 https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
}

# 檢查kubectl安裝
check_kubectl() {
    log_info "檢查kubectl安裝..."
    if check_command kubectl; then
        KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)
        log_success "kubectl已安裝: $KUBECTL_VERSION"
    else
        log_warning "kubectl未安裝，GKE章節需要kubectl"
        log_info "安裝方法："
        log_info "  macOS: brew install kubectl"
        log_info "  Linux: 參考 https://kubernetes.io/docs/tasks/tools/"
    fi
}

# 檢查Git安裝
check_git() {
    log_info "檢查Git安裝..."
    if check_command git; then
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        log_success "Git已安裝: $GIT_VERSION"
    else
        log_warning "Git未安裝，建議安裝Git進行版本控制"
    fi
}

# 檢查GCP認證
check_gcp_auth() {
    log_info "檢查GCP認證..."
    
    # 檢查是否已登入
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
        ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
        log_success "已登入GCP帳戶: $ACTIVE_ACCOUNT"
    else
        log_warning "未登入GCP帳戶"
        log_info "請運行: gcloud auth login"
        return 1
    fi
    
    # 檢查應用默認認證
    if gcloud auth application-default print-access-token &> /dev/null; then
        log_success "應用默認認證已設置"
    else
        log_warning "應用默認認證未設置"
        log_info "請運行: gcloud auth application-default login"
        return 1
    fi
    
    return 0
}

# 檢查GCP專案設置
check_gcp_project() {
    log_info "檢查GCP專案設置..."
    
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ -n "$CURRENT_PROJECT" ]; then
        log_success "當前專案: $CURRENT_PROJECT"
        
        # 檢查專案是否存在
        if gcloud projects describe $CURRENT_PROJECT &> /dev/null; then
            log_success "專案存在且可訪問"
        else
            log_error "專案不存在或無權限訪問"
            return 1
        fi
    else
        log_error "未設置GCP專案"
        log_info "請運行: gcloud config set project YOUR_PROJECT_ID"
        return 1
    fi
    
    return 0
}

# 啟用必要API
enable_apis() {
    log_info "啟用必要的GCP API..."
    
    PROJECT_ID=$(gcloud config get-value project)
    
    # API列表
    APIs=(
        "compute.googleapis.com"
        "container.googleapis.com"
        "sqladmin.googleapis.com"
        "servicenetworking.googleapis.com"
        "cloudkms.googleapis.com"
        "monitoring.googleapis.com"
        "logging.googleapis.com"
        "storage.googleapis.com"
        "iam.googleapis.com"
        "cloudresourcemanager.googleapis.com"
    )
    
    for api in "${APIs[@]}"; do
        log_info "啟用 $api..."
        if gcloud services enable $api --project=$PROJECT_ID; then
            log_success "$api 已啟用"
        else
            log_warning "啟用 $api 失敗"
        fi
    done
}

# 檢查配額
check_quotas() {
    log_info "檢查GCP配額..."
    
    PROJECT_ID=$(gcloud config get-value project)
    
    # 檢查關鍵配額
    log_info "檢查Compute Engine配額..."
    if gcloud compute project-info describe --project=$PROJECT_ID --format="value(quotas[].metric)" | grep -q "CPUS"; then
        log_success "Compute Engine配額正常"
    else
        log_warning "Compute Engine配額可能不足"
    fi
    
    log_info "檢查IP地址配額..."
    if gcloud compute project-info describe --project=$PROJECT_ID --format="value(quotas[].metric)" | grep -q "IN_USE_ADDRESSES"; then
        log_success "IP地址配額正常"
    else
        log_warning "IP地址配額可能不足"
    fi
}

# 創建服務帳戶
create_service_account() {
    log_info "創建Terraform服務帳戶..."
    
    PROJECT_ID=$(gcloud config get-value project)
    SA_NAME="terraform-sa"
    SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
    
    # 檢查服務帳戶是否已存在
    if gcloud iam service-accounts describe $SA_EMAIL &> /dev/null; then
        log_success "服務帳戶已存在: $SA_EMAIL"
    else
        log_info "創建服務帳戶: $SA_NAME"
        if gcloud iam service-accounts create $SA_NAME \
            --description="Service account for Terraform" \
            --display-name="Terraform Service Account"; then
            log_success "服務帳戶創建成功"
        else
            log_error "服務帳戶創建失敗"
            return 1
        fi
    fi
    
    # 分配權限
    log_info "分配必要權限..."
    ROLES=(
        "roles/editor"
        "roles/iam.serviceAccountUser"
        "roles/storage.admin"
    )
    
    for role in "${ROLES[@]}"; do
        log_info "分配角色: $role"
        if gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:$SA_EMAIL" \
            --role="$role"; then
            log_success "角色分配成功: $role"
        else
            log_warning "角色分配失敗: $role"
        fi
    done
    
    # 創建密鑰文件
    KEY_FILE="terraform-sa-key.json"
    if [ ! -f "$KEY_FILE" ]; then
        log_info "創建服務帳戶密鑰文件..."
        if gcloud iam service-accounts keys create $KEY_FILE \
            --iam-account=$SA_EMAIL; then
            log_success "密鑰文件創建成功: $KEY_FILE"
            log_warning "請妥善保管密鑰文件，不要提交到版本控制"
        else
            log_error "密鑰文件創建失敗"
            return 1
        fi
    else
        log_success "密鑰文件已存在: $KEY_FILE"
    fi
}

# 創建Terraform狀態存儲Bucket
create_state_bucket() {
    log_info "創建Terraform狀態存儲Bucket..."
    
    PROJECT_ID=$(gcloud config get-value project)
    BUCKET_NAME="$PROJECT_ID-terraform-state"
    
    # 檢查Bucket是否已存在
    if gsutil ls -b gs://$BUCKET_NAME &> /dev/null; then
        log_success "狀態Bucket已存在: gs://$BUCKET_NAME"
    else
        log_info "創建狀態Bucket: gs://$BUCKET_NAME"
        if gsutil mb -p $PROJECT_ID gs://$BUCKET_NAME; then
            log_success "狀態Bucket創建成功"
            
            # 啟用版本控制
            log_info "啟用版本控制..."
            gsutil versioning set on gs://$BUCKET_NAME
            
            # 設置生命週期策略
            log_info "設置生命週期策略..."
            cat > lifecycle.json << EOF
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {"age": 30}
    }
  ]
}
EOF
            gsutil lifecycle set lifecycle.json gs://$BUCKET_NAME
            rm lifecycle.json
            
            log_success "狀態Bucket配置完成"
        else
            log_error "狀態Bucket創建失敗"
            return 1
        fi
    fi
}

# 設置環境變數
setup_environment() {
    log_info "設置環境變數..."
    
    PROJECT_ID=$(gcloud config get-value project)
    
    # 創建.env文件
    cat > .env << EOF
# GCP配置
export GOOGLE_PROJECT="$PROJECT_ID"
export GOOGLE_REGION="us-central1"
export GOOGLE_ZONE="us-central1-a"

# Terraform配置
export TF_VAR_project_id="$PROJECT_ID"
export TF_VAR_region="us-central1"
export TF_VAR_zone="us-central1-a"

# 服務帳戶密鑰
export GOOGLE_APPLICATION_CREDENTIALS="\$(pwd)/terraform-sa-key.json"
EOF
    
    log_success "環境變數文件創建: .env"
    log_info "請運行: source .env"
}

# 驗證設置
verify_setup() {
    log_info "驗證設置..."
    
    # 檢查Terraform
    if terraform --version &> /dev/null; then
        log_success "Terraform驗證通過"
    else
        log_error "Terraform驗證失敗"
        return 1
    fi
    
    # 檢查GCP認證
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
        log_success "GCP認證驗證通過"
    else
        log_error "GCP認證驗證失敗"
        return 1
    fi
    
    # 檢查專案
    if gcloud config get-value project &> /dev/null; then
        log_success "GCP專案驗證通過"
    else
        log_error "GCP專案驗證失敗"
        return 1
    fi
    
    # 檢查服務帳戶密鑰
    if [ -f "terraform-sa-key.json" ]; then
        log_success "服務帳戶密鑰驗證通過"
    else
        log_error "服務帳戶密鑰驗證失敗"
        return 1
    fi
    
    log_success "所有驗證通過！"
    return 0
}

# 顯示下一步
show_next_steps() {
    log_info "設置完成！下一步："
    echo ""
    log_info "1. 載入環境變數："
    echo "   source .env"
    echo ""
    log_info "2. 開始學習："
    echo "   cd 01-basics"
    echo "   cp terraform.tfvars.example terraform.tfvars"
    echo "   # 編輯 terraform.tfvars，填入您的專案ID"
    echo "   terraform init"
    echo "   terraform plan"
    echo "   terraform apply"
    echo ""
    log_info "3. 查看教學文檔："
    echo "   cat README.md"
    echo ""
    log_warning "重要提醒："
    echo "  - 請妥善保管 terraform-sa-key.json 文件"
    echo "  - 不要將密鑰文件提交到版本控制"
    echo "  - 定期檢查GCP費用"
    echo "  - 完成練習後及時清理資源"
}

# 主函數
main() {
    echo "=========================================="
    echo "Terraform GCP 教學專案設置腳本"
    echo "=========================================="
    echo ""
    
    # 檢查前置需求
    check_terraform
    check_gcloud
    check_kubectl
    check_git
    
    echo ""
    log_info "檢查GCP配置..."
    
    # 檢查GCP認證和專案
    if ! check_gcp_auth; then
        log_error "GCP認證檢查失敗，請先完成認證設置"
        exit 1
    fi
    
    if ! check_gcp_project; then
        log_error "GCP專案檢查失敗，請先設置專案"
        exit 1
    fi
    
    echo ""
    log_info "配置GCP環境..."
    
    # 啟用API
    enable_apis
    
    # 檢查配額
    check_quotas
    
    # 創建服務帳戶
    create_service_account
    
    # 創建狀態Bucket
    create_state_bucket
    
    # 設置環境變數
    setup_environment
    
    echo ""
    log_info "驗證設置..."
    
    # 驗證設置
    if verify_setup; then
        echo ""
        show_next_steps
        log_success "設置完成！"
    else
        log_error "設置驗證失敗，請檢查錯誤信息"
        exit 1
    fi
}

# 運行主函數
main "$@"
