#!/bin/bash
set -e

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "此脚本需要root权限运行，请使用sudo"
    exit 1
fi

# 安装目录
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/friday-ddns"
SERVICE_DIR="/etc/systemd/system"

# 当前目录
CURRENT_DIR=$(pwd)

echo "===== 开始安装 Friday-DDNS ====="

# 第1步：编译并安装二进制文件
echo "正在编译并安装二进制文件..."
cargo install --path . --root /usr/local --force
echo "二进制文件已安装到 $INSTALL_DIR"

# 第2步：创建配置目录
echo "正在创建配置目录..."
mkdir -p $CONFIG_DIR

# 第3步：如果配置文件不存在，创建示例配置文件
if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    echo "正在创建示例配置文件..."
    cat > "$CONFIG_DIR/config.yaml" << EOL
# Namecheap DDNS 配置
domains:
  - domain: example.com
    token: your_namecheap_ddns_password
    subdomains:
      - "@"
      - "www"
    # ip: 可选，如不提供则使用访问请求的IP
EOL
    echo "示例配置文件已创建，请编辑 $CONFIG_DIR/config.yaml 填入正确信息"
else
    echo "配置文件已存在，跳过创建"
fi

# 设置配置文件权限
chmod 600 "$CONFIG_DIR/config.yaml"

# 第4步：复制服务文件
echo "正在安装 systemd 服务文件..."
cp "$CURRENT_DIR/friday-ddns.service" "$SERVICE_DIR/"
cp "$CURRENT_DIR/friday-ddns.timer" "$SERVICE_DIR/"

# 第5步：重新加载systemd配置
echo "正在重新加载 systemd 配置..."
systemctl daemon-reload

# 第6步：启用并启动服务
echo "正在启用并启动服务..."
systemctl enable friday-ddns.timer
systemctl start friday-ddns.timer

echo "===== 安装完成 ====="
echo "服务状态："
systemctl status friday-ddns.timer
echo ""
echo "配置文件位置：$CONFIG_DIR/config.yaml"
echo "请确保已正确配置域名和密钥信息"
echo ""
echo "手动更新DDNS："
echo "  sudo systemctl start friday-ddns.service"
echo ""
echo "查看日志："
echo "  sudo journalctl -u friday-ddns.service" 