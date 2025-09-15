#!/bin/bash
# Compute Engine啟動腳本
# 自動安裝和配置Web服務器

set -e

# 更新系統
apt-get update
apt-get upgrade -y

# 安裝必要軟體
apt-get install -y nginx curl wget unzip

# 啟動Nginx
systemctl start nginx
systemctl enable nginx

# 創建健康檢查端點
cat > /var/www/html/health << EOF
<h1>Healthy</h1>
<p>Instance: ${project_name}</p>
<p>Environment: ${environment}</p>
<p>Timestamp: $(date)</p>
EOF

# 創建主頁
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Compute Engine Instance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #4285f4; color: white; padding: 20px; border-radius: 5px; }
        .content { margin: 20px 0; }
        .info { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Compute Engine Instance</h1>
            <p>Managed by Terraform</p>
        </div>
        
        <div class="content">
            <div class="info">
                <h3>Instance Information</h3>
                <p><strong>Project:</strong> ${project_name}</p>
                <p><strong>Environment:</strong> ${environment}</p>
                <p><strong>Zone:</strong> $(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | cut -d'/' -f4)</p>
                <p><strong>Machine Type:</strong> $(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/machine-type" -H "Metadata-Flavor: Google" | cut -d'/' -f4)</p>
                <p><strong>Internal IP:</strong> $(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip" -H "Metadata-Flavor: Google")</p>
                <p><strong>External IP:</strong> $(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip" -H "Metadata-Flavor: Google")</p>
            </div>
            
            <div class="info">
                <h3>System Information</h3>
                <p><strong>OS:</strong> $(lsb_release -d | cut -f2)</p>
                <p><strong>Kernel:</strong> $(uname -r)</p>
                <p><strong>Uptime:</strong> $(uptime -p)</p>
                <p><strong>Load Average:</strong> $(uptime | awk -F'load average:' '{print $2}')</p>
            </div>
            
            <div class="info">
                <h3>Resource Usage</h3>
                <p><strong>CPU:</strong> $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%</p>
                <p><strong>Memory:</strong> $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')</p>
                <p><strong>Disk:</strong> $(df -h / | awk 'NR==2{print $5}')</p>
            </div>
            
            <div class="info">
                <h3>Network Information</h3>
                <p><strong>Public IP:</strong> $(curl -s ifconfig.me)</p>
                <p><strong>Region:</strong> $(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | cut -d'/' -f4 | cut -d'-' -f1-2)</p>
            </div>
        </div>
        
        <div class="content">
            <h3>Available Endpoints</h3>
            <ul>
                <li><a href="/health">Health Check</a></li>
                <li><a href="/">Main Page</a></li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# 設置適當的權限
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# 配置Nginx日誌
cat > /etc/nginx/conf.d/custom.conf << EOF
server {
    listen 80;
    server_name _;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    location / {
        root /var/www/html;
        index index.html;
    }
    
    location /health {
        root /var/www/html;
        access_log off;
    }
}
EOF

# 重新載入Nginx配置
systemctl reload nginx

# 安裝監控工具
apt-get install -y htop iotop nethogs

# 創建系統監控腳本
cat > /usr/local/bin/system-monitor.sh << 'EOF'
#!/bin/bash
# 系統監控腳本

echo "=== System Monitor ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo ""

echo "=== CPU Usage ==="
top -bn1 | grep "Cpu(s)"
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Disk Usage ==="
df -h
echo ""

echo "=== Network Connections ==="
ss -tuln | head -10
echo ""

echo "=== Process List ==="
ps aux --sort=-%cpu | head -10
EOF

chmod +x /usr/local/bin/system-monitor.sh

# 創建定時任務
echo "*/5 * * * * root /usr/local/bin/system-monitor.sh >> /var/log/system-monitor.log 2>&1" >> /etc/crontab

# 安裝Cloud Logging代理
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
bash add-logging-agent-repo.sh --also-install

# 安裝Cloud Monitoring代理
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
bash add-monitoring-agent-repo.sh --also-install

# 創建完成標記
touch /var/log/startup-complete.log
echo "Startup script completed at $(date)" >> /var/log/startup-complete.log

# 記錄到系統日誌
logger "Compute Engine startup script completed successfully"
