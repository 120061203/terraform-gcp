#!/bin/bash
# Cloud SQL代理啟動腳本
# 自動安裝和配置Cloud SQL代理

set -e

# 更新系統
apt-get update
apt-get upgrade -y

# 安裝必要軟體
apt-get install -y wget curl unzip

# 下載Cloud SQL代理
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O /usr/local/bin/cloud_sql_proxy
chmod +x /usr/local/bin/cloud_sql_proxy

# 創建代理配置目錄
mkdir -p /opt/cloudsql-proxy
cd /opt/cloudsql-proxy

# 創建PostgreSQL代理啟動腳本
cat > start_postgres_proxy.sh << 'EOF'
#!/bin/bash
# PostgreSQL代理啟動腳本

PROJECT_ID="${project_id}"
INSTANCE_NAME="${postgres_instance}"
PORT=5432

echo "Starting Cloud SQL Proxy for PostgreSQL..."
echo "Project: $PROJECT_ID"
echo "Instance: $INSTANCE_NAME"
echo "Port: $PORT"

/usr/local/bin/cloud_sql_proxy \
  --instances=$PROJECT_ID:$REGION:$INSTANCE_NAME=tcp:$PORT \
  --credential_file=/etc/gcp/service-account.json \
  --log_level=info \
  --log_file=/var/log/cloudsql-proxy-postgres.log
EOF

# 創建MySQL代理啟動腳本（如果啟用）
if [ -n "${mysql_instance}" ]; then
cat > start_mysql_proxy.sh << 'EOF'
#!/bin/bash
# MySQL代理啟動腳本

PROJECT_ID="${project_id}"
INSTANCE_NAME="${mysql_instance}"
PORT=3306

echo "Starting Cloud SQL Proxy for MySQL..."
echo "Project: $PROJECT_ID"
echo "Instance: $INSTANCE_NAME"
echo "Port: $PORT"

/usr/local/bin/cloud_sql_proxy \
  --instances=$PROJECT_ID:$REGION:$INSTANCE_NAME=tcp:$PORT \
  --credential_file=/etc/gcp/service-account.json \
  --log_level=info \
  --log_file=/var/log/cloudsql-proxy-mysql.log
EOF
fi

# 創建SQL Server代理啟動腳本（如果啟用）
if [ -n "${sqlserver_instance}" ]; then
cat > start_sqlserver_proxy.sh << 'EOF'
#!/bin/bash
# SQL Server代理啟動腳本

PROJECT_ID="${project_id}"
INSTANCE_NAME="${sqlserver_instance}"
PORT=1433

echo "Starting Cloud SQL Proxy for SQL Server..."
echo "Project: $PROJECT_ID"
echo "Instance: $INSTANCE_NAME"
echo "Port: $PORT"

/usr/local/bin/cloud_sql_proxy \
  --instances=$PROJECT_ID:$REGION:$INSTANCE_NAME=tcp:$PORT \
  --credential_file=/etc/gcp/service-account.json \
  --log_level=info \
  --log_file=/var/log/cloudsql-proxy-sqlserver.log
EOF
fi

# 設置腳本權限
chmod +x /opt/cloudsql-proxy/*.sh

# 創建systemd服務文件
cat > /etc/systemd/system/cloudsql-proxy-postgres.service << EOF
[Unit]
Description=Cloud SQL Proxy for PostgreSQL
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cloudsql-proxy
ExecStart=/opt/cloudsql-proxy/start_postgres_proxy.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 創建MySQL服務文件（如果啟用）
if [ -n "${mysql_instance}" ]; then
cat > /etc/systemd/system/cloudsql-proxy-mysql.service << EOF
[Unit]
Description=Cloud SQL Proxy for MySQL
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cloudsql-proxy
ExecStart=/opt/cloudsql-proxy/start_mysql_proxy.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
fi

# 創建SQL Server服務文件（如果啟用）
if [ -n "${sqlserver_instance}" ]; then
cat > /etc/systemd/system/cloudsql-proxy-sqlserver.service << EOF
[Unit]
Description=Cloud SQL Proxy for SQL Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cloudsql-proxy
ExecStart=/opt/cloudsql-proxy/start_sqlserver_proxy.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
fi

# 重新載入systemd
systemctl daemon-reload

# 啟用並啟動PostgreSQL代理服務
systemctl enable cloudsql-proxy-postgres.service
systemctl start cloudsql-proxy-postgres.service

# 啟用並啟動MySQL代理服務（如果啟用）
if [ -n "${mysql_instance}" ]; then
  systemctl enable cloudsql-proxy-mysql.service
  systemctl start cloudsql-proxy-mysql.service
fi

# 啟用並啟動SQL Server代理服務（如果啟用）
if [ -n "${sqlserver_instance}" ]; then
  systemctl enable cloudsql-proxy-sqlserver.service
  systemctl start cloudsql-proxy-sqlserver.service
fi

# 安裝數據庫客戶端工具
apt-get install -y postgresql-client mysql-client

# 創建連接測試腳本
cat > /opt/cloudsql-proxy/test_connections.sh << 'EOF'
#!/bin/bash
# 數據庫連接測試腳本

echo "=== Database Connection Test ==="
echo "Date: $(date)"
echo ""

# 測試PostgreSQL連接
echo "Testing PostgreSQL connection..."
if pg_isready -h localhost -p 5432 -U postgres; then
  echo "✓ PostgreSQL connection successful"
else
  echo "✗ PostgreSQL connection failed"
fi
echo ""

# 測試MySQL連接（如果啟用）
if [ -n "${mysql_instance}" ]; then
  echo "Testing MySQL connection..."
  if mysqladmin ping -h localhost -P 3306 -u root --silent; then
    echo "✓ MySQL connection successful"
  else
    echo "✗ MySQL connection failed"
  fi
  echo ""
fi

# 測試SQL Server連接（如果啟用）
if [ -n "${sqlserver_instance}" ]; then
  echo "Testing SQL Server connection..."
  # 這裡可以添加SQL Server連接測試
  echo "SQL Server connection test not implemented"
  echo ""
fi

echo "=== Service Status ==="
systemctl status cloudsql-proxy-postgres --no-pager -l

if [ -n "${mysql_instance}" ]; then
  systemctl status cloudsql-proxy-mysql --no-pager -l
fi

if [ -n "${sqlserver_instance}" ]; then
  systemctl status cloudsql-proxy-sqlserver --no-pager -l
fi
EOF

chmod +x /opt/cloudsql-proxy/test_connections.sh

# 創建定時任務
echo "*/5 * * * * root /opt/cloudsql-proxy/test_connections.sh >> /var/log/database-test.log 2>&1" >> /etc/crontab

# 創建完成標記
touch /var/log/sql-proxy-setup-complete.log
echo "Cloud SQL Proxy setup completed at $(date)" >> /var/log/sql-proxy-setup-complete.log

# 記錄到系統日誌
logger "Cloud SQL Proxy setup completed successfully"

# 顯示狀態
echo "=== Cloud SQL Proxy Setup Complete ==="
echo "Services enabled:"
systemctl list-unit-files | grep cloudsql-proxy

echo ""
echo "To test connections, run:"
echo "/opt/cloudsql-proxy/test_connections.sh"

echo ""
echo "To check logs:"
echo "journalctl -u cloudsql-proxy-postgres -f"
if [ -n "${mysql_instance}" ]; then
  echo "journalctl -u cloudsql-proxy-mysql -f"
fi
if [ -n "${sqlserver_instance}" ]; then
  echo "journalctl -u cloudsql-proxy-sqlserver -f"
fi
