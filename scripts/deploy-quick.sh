#!/bin/bash

##############################################
# WireGuard 快速部署脚本（跳过系统更新）
##############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

source .env

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}WireGuard 快速部署${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

echo -e "${GREEN}[1/5] 安装 WireGuard...${NC}"
ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y wireguard qrencode iptables-persistent
    
    # 启用 IP 转发
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    sysctl -p
    
    echo "WireGuard 安装完成"
ENDSSH

echo -e "\n${GREEN}[2/5] 生成服务器密钥对...${NC}"
SERVER_KEYS=$(ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    mkdir -p /etc/wireguard
    cd /etc/wireguard
    umask 077
    wg genkey | tee server_private.key | wg pubkey > server_public.key
    echo "PRIVATE_KEY=$(cat server_private.key)"
    echo "PUBLIC_KEY=$(cat server_public.key)"
ENDSSH
)

eval "$SERVER_KEYS"

echo -e "服务器公钥: ${YELLOW}$PUBLIC_KEY${NC}"

echo -e "\n${GREEN}[3/5] 生成服务器配置文件...${NC}"
SERVER_CONF=$(cat config/server.conf.template | sed "s|SERVER_PRIVATE_KEY|$PRIVATE_KEY|g")

echo "$SERVER_CONF" | ssh -i $SSH_KEY $SSH_USER@$SERVER_IP "cat > /etc/wireguard/wg0.conf && chmod 600 /etc/wireguard/wg0.conf"

echo -e "\n${GREEN}[4/5] 配置防火墙...${NC}"
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

echo -e "\n${GREEN}[5/5] 启动 WireGuard 服务...${NC}"
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
