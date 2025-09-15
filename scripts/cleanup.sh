#!/bin/bash
# Terraform GCP 教學專案清理腳本
# 自動清理所有創建的資源

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

# 確認函數
confirm() {
    read -p "$(echo -e ${YELLOW}$1${NC}) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# 檢查Terraform狀態
check_terraform_state() {
    log_info "檢查Terraform狀態..."
    
    if [ -f "terraform.tfstate" ] || [ -d ".terraform" ]; then
        log_warning "發現Terraform狀態文件"
        return 0
    else
        log_info "未發現Terraform狀態文件"
        return 1
    fi
}

# 清理特定目錄的資源
cleanup_directory() {
    local dir=$1
    local name=$2
    
    if [ -d "$dir" ]; then
        log_info "清理 $name 資源..."
        cd "$dir"
        
        if check_terraform_state; then
            if confirm "是否清理 $name 的資源？"; then
                log_info "銷毀 $name 資源..."
                if terraform destroy -auto-approve; then
                    log_success "$name 資源清理完成"
                else
                    log_error "$name 資源清理失敗"
                fi
            else
                log_info "跳過 $name 資源清理"
            fi
        else
            log_info "$name 目錄無需清理"
        fi
        
        cd ..
    else
        log_info "$name 目錄不存在，跳過"
    fi
}

# 清理GCP資源
cleanup_gcp_resources() {
    log_info "清理GCP資源..."
    
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        log_error "未設置GCP專案，無法清理資源"
        return 1
    fi
    
    log_info "當前專案: $PROJECT_ID"
    
    # 清理Compute Engine實例
    log_info "清理Compute Engine實例..."
    INSTANCES=$(gcloud compute instances list --format="value(name,zone)" --filter="name~'.*learning.*' OR name~'.*exercise.*' OR name~'.*terraform.*'" 2>/dev/null || true)
    if [ -n "$INSTANCES" ]; then
        echo "$INSTANCES" | while read -r name zone; do
            if [ -n "$name" ] && [ -n "$zone" ]; then
                log_info "刪除實例: $name (zone: $zone)"
                gcloud compute instances delete "$name" --zone="$zone" --quiet || log_warning "刪除實例失敗: $name"
            fi
        done
    else
        log_info "未發現需要清理的實例"
    fi
    
    # 清理VPC網路
    log_info "清理VPC網路..."
    NETWORKS=$(gcloud compute networks list --format="value(name)" --filter="name~'.*learning.*' OR name~'.*exercise.*' OR name~'.*terraform.*'" 2>/dev/null || true)
    if [ -n "$NETWORKS" ]; then
        echo "$NETWORKS" | while read -r network; do
            if [ -n "$network" ]; then
                log_info "刪除網路: $network"
                gcloud compute networks delete "$network" --quiet || log_warning "刪除網路失敗: $network"
            fi
        done
    else
        log_info "未發現需要清理的網路"
    fi
    
    # 清理防火牆規則
    log_info "清理防火牆規則..."
    FIREWALLS=$(gcloud compute firewall-rules list --format="value(name)" --filter="name~'.*learning.*' OR name~'.*exercise.*' OR name~'.*terraform.*'" 2>/dev/null || true)
    if [ -n "$FIREWALLS" ]; then
        echo "$FIREWALLS" | while read -r firewall; do
            if [ -n "$firewall" ]; then
                log_info "刪除防火牆規則: $firewall"
                gcloud compute firewall-rules delete "$firewall" --quiet || log_warning "刪除防火牆規則失敗: $firewall"
            fi
        done
    else
        log_info "未發現需要清理的防火牆規則"
    fi
    
    # 清理Cloud SQL實例
    log_info "清理Cloud SQL實例..."
    SQL_INSTANCES=$(gcloud sql instances list --format="value(name)" --filter="name~'.*learning.*' OR name~'.*exercise.*' OR name~'.*terraform.*'" 2>/dev/null || true)
    if [ -n "$SQL_INSTANCES" ]; then
        echo "$SQL_INSTANCES" | while read -r instance; do
            if [ -n "$instance" ]; then
                log_info "刪除SQL實例: $instance"
                gcloud sql instances delete "$instance" --quiet || log_warning "刪除SQL實例失敗: $instance"
            fi
        done
    else
        log_info "未發現需要清理的SQL實例"
    fi
    
    # 清理GKE集群
    log_info "清理GKE集群..."
    CLUSTERS=$(gcloud container clusters list --format="value(name,location)" --filter="name~'.*learning.*' OR name~'.*exercise.*' OR name~'.*terraform.*'" 2>/dev/null || true)
    if [ -n "$CLUSTERS" ]; then
        echo "$CLUSTANCES" | while read -r name location; do
            if [ -n "$name" ] && [ -n "$location" ]; then
                log_info "刪除GKE集群: $name (location: $location)"
                gcloud container clusters delete "$name" --location="$location" --quiet || log_warning "刪除GKE集群失敗: $name"
            fi
        done
    else
        log_info "未發現需要清理的GKE集群"
    fi
    
    # 清理Storage Buckets
    log_info "清理Storage Buckets..."
    BUCKETS=$(gsutil ls 2>/dev/null | grep -E ".*learning.*|.*exercise.*|.*terraform.*" || true)
    if [ -n "$BUCKETS" ]; then
        echo "$BUCKETS" | while read -r bucket; do
            if [ -n "$bucket" ]; then
                log_info "刪除Bucket: $bucket"
                gsutil rm -r "$bucket" || log_warning "刪除Bucket失敗: $bucket"
            fi
        done
    else
        log_info "未發現需要清理的Bucket"
    fi
    
    # 清理負載平衡器
    log_info "清理負載平衡器..."
    LBS=$(gcloud compute forwarding-rules list --format="value(name,region)" --filter="name~'.*learning.*' OR name~'.*exercise.*' OR name~'.*terraform.*'" 2>/dev/null || true)
    if [ -n "$LBS" ]; then
        echo "$LBS" | while read -r name region; do
            if [ -n "$name" ] && [ -n "$region" ]; then
                log_info "刪除負載平衡器: $name (region: $region)"
                gcloud compute forwarding-rules delete "$name" --region="$region" --quiet || log_warning "刪除負載平衡器失敗: $name"
            fi
        done
    else
        log_info "未發現需要清理的負載平衡器"
    fi
    
    # 清理靜態IP
    log_info "清理靜態IP..."
    IPS=$(gcloud compute addresses list --format="value(name,region)" --filter="name~'.*learning.*' OR name~'.*exercise.*' OR name~'.*terraform.*'" 2>/dev/null || true)
    if [ -n "$IPS" ]; then
        echo "$IPS" | while read -r name region; do
            if [ -n "$name" ] && [ -n "$region" ]; then
                log_info "刪除靜態IP: $name (region: $region)"
                gcloud compute addresses delete "$name" --region="$region" --quiet || log_warning "刪除靜態IP失敗: $name"
            fi
        done
    else
        log_info "未發現需要清理的靜態IP"
    fi
}

# 清理本地文件
cleanup_local_files() {
    log_info "清理本地文件..."
    
    # 清理Terraform狀態文件
    if confirm "是否刪除所有Terraform狀態文件？"; then
        find . -name "terraform.tfstate*" -type f -delete 2>/dev/null || true
        find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
        log_success "Terraform狀態文件已清理"
    fi
    
    # 清理服務帳戶密鑰文件
    if [ -f "terraform-sa-key.json" ]; then
        if confirm "是否刪除服務帳戶密鑰文件？"; then
            rm -f terraform-sa-key.json
            log_success "服務帳戶密鑰文件已刪除"
        fi
    fi
    
    # 清理環境變數文件
    if [ -f ".env" ]; then
        if confirm "是否刪除環境變數文件？"; then
            rm -f .env
            log_success "環境變數文件已刪除"
        fi
    fi
    
    # 清理臨時文件
    find . -name "*.tmp" -type f -delete 2>/dev/null || true
    find . -name "*.log" -type f -delete 2>/dev/null || true
    log_success "臨時文件已清理"
}

# 檢查費用
check_costs() {
    log_info "檢查GCP費用..."
    
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        log_warning "未設置GCP專案，無法檢查費用"
        return
    fi
    
    log_info "請檢查GCP控制台的費用報告："
    log_info "https://console.cloud.google.com/billing"
    log_warning "請確保所有資源都已清理，避免產生額外費用"
}

# 顯示清理摘要
show_cleanup_summary() {
    log_info "清理摘要："
    echo ""
    log_success "✓ Compute Engine實例已清理"
    log_success "✓ VPC網路已清理"
    log_success "✓ 防火牆規則已清理"
    log_success "✓ Cloud SQL實例已清理"
    log_success "✓ GKE集群已清理"
    log_success "✓ Storage Buckets已清理"
    log_success "✓ 負載平衡器已清理"
    log_success "✓ 靜態IP已清理"
    log_success "✓ 本地文件已清理"
    echo ""
    log_warning "請檢查GCP控制台確認所有資源已清理"
    log_warning "建議檢查費用報告避免產生額外費用"
}

# 主函數
main() {
    echo "=========================================="
    echo "Terraform GCP 教學專案清理腳本"
    echo "=========================================="
    echo ""
    
    log_warning "此腳本將清理所有教學專案創建的資源"
    log_warning "請確保您已完成學習，不再需要這些資源"
    echo ""
    
    if ! confirm "是否繼續清理？"; then
        log_info "清理已取消"
        exit 0
    fi
    
    echo ""
    log_info "開始清理資源..."
    
    # 清理各章節的資源
    cleanup_directory "01-basics" "基礎教學"
    cleanup_directory "02-vpc" "VPC網路"
    cleanup_directory "03-compute" "Compute Engine"
    cleanup_directory "04-gke" "GKE集群"
    cleanup_directory "05-database" "Cloud SQL"
    cleanup_directory "06-modules" "模組"
    cleanup_directory "07-production" "生產環境"
    
    # 清理練習題資源
    cleanup_directory "exercises" "練習題"
    
    echo ""
    log_info "清理GCP資源..."
    cleanup_gcp_resources
    
    echo ""
    log_info "清理本地文件..."
    cleanup_local_files
    
    echo ""
    check_costs
    
    echo ""
    show_cleanup_summary
    
    log_success "清理完成！"
}

# 運行主函數
main "$@"
