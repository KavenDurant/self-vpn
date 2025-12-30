#!/bin/bash

#############################################
# WireGuard VPN 一键部署脚本
# 用途: 在 Ubuntu 22.04 上自动部署 WireGuard
# 作者: Self-VPN Project
#############################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 加载环境变量
if [ ! -f .env ]; then
    echo -e "${RED}错误: .env 文件不存在${NC}"
    echo "请先复制 .env.example 到 .env 并配置服务器 IP"
    exit 1
fi

source .env

# 检查必要变量
if [ "$SERVER_IP" = "YOUR_SERVER_IP_HERE" ]; then
    echo -e "${RED}错误: 请先在 .env 中配置 SERVER_IP${NC}"
    exit 1
fi

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}WireGuard VPN 一键部署${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "服务器: ${YELLOW}$SERVER_IP${NC}"
echo -e "SSH 密钥: ${YELLOW}$SSH_KEY${NC}"
echo ""

# 确认部署
read -p "确认开始部署？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消部署"
    exit 1
fi

echo -e "\n${GREEN}[1/6] 测试 SSH 连接...${NC}"
if ! ssh -i $SSH_KEY -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new $SSH_USER@$SERVER_IP "echo 'SSH 连接成功'"; then
    echo -e "${RED}SSH 连接失败，请检查:${NC}"
    echo "1. 服务器 IP 是否正确"
    echo "2. SSH 密钥是否已添加到服务器"
    echo "3. 服务器是否已启动"
    exit 1
fi

echo -e "\n${GREEN}[2/6] 更新系统并安装 WireGuard...${NC}"
ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    # 更新系统（非交互式）
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    
    # 安装 WireGuard 和必要工具
    apt-get install -y wireguard qrencode iptables-persistent net-tools
    
    # 启用 IP 转发
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    sysctl -p
    
    echo "WireGuard 安装完成"
ENDSSH

echo -e "\n${GREEN}[3/6] 生成服务器密钥对...${NC}"
SERVER_KEYS=$(ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    cd /etc/wireguard
    umask 077
    wg genkey | tee server_private.key | wg pubkey > server_public.key
    echo "PRIVATE_KEY=$(cat server_private.key)"
    echo "PUBLIC_KEY=$(cat server_public.key)"
ENDSSH
)

eval "$SERVER_KEYS"

echo -e "服务器公钥: ${YELLOW}$PUBLIC_KEY${NC}"

echo -e "\n${GREEN}[4/6] 生成服务器配置文件...${NC}"
# 读取模板并替换变量
SERVER_CONF=$(cat config/server.conf.template | sed "s|SERVER_PRIVATE_KEY|$PRIVATE_KEY|g")

# 上传配置到服务器
echo "$SERVER_CONF" | ssh -i $SSH_KEY $SSH_USER@$SERVER_IP "cat > /etc/wireguard/wg0.conf && chmod 600 /etc/wireguard/wg0.conf"

echo -e "\n${GREEN}[5/6] 配置防火墙...${NC}"
ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << ENDSSH
    # 配置 UFW 防火墙
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    
    # 允许 SSH
    ufw allow 22/tcp
    
    # 允许 WireGuard
    ufw allow $SERVER_PORT/udp
    
    # 允许转发
    sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
    
    # 重载防火墙
    ufw reload
    
    echo "防火墙配置完成"
ENDSSH

echo -e "\n${GREEN}[6/6] 启动 WireGuard 服务...${NC}"
ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    # 启动服务
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    # 检查状态
    systemctl status wg-quick@wg0 --no-pager
    
    echo ""
    echo "WireGuard 接口状态:"
    wg show
ENDSSH

# 保存服务器公钥到本地
mkdir -p config
echo "$PUBLIC_KEY" > config/server_public.key

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "服务器公钥已保存到: ${YELLOW}config/server_public.key${NC}"
echo ""
echo -e "下一步:"
echo -e "1. 运行 ${YELLOW}./scripts/add-client.sh <设备名>${NC} 来添加客户端"
echo -e "2. 例如: ${YELLOW}./scripts/add-client.sh iphone${NC}"
echo ""
