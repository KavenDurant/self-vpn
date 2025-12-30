#!/bin/bash

#############################################
# 客户端配置生成脚本
# 用途: 为新设备生成 WireGuard 配置
#############################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 加载环境变量
source .env

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "${RED}错误: 请提供客户端名称${NC}"
    echo "用法: $0 <客户端名称>"
    echo "例如: $0 iphone"
    exit 1
fi

CLIENT_NAME=$1

# 创建客户端目录
mkdir -p clients

# 检查客户端是否已存在
if [ -f "clients/${CLIENT_NAME}.conf" ]; then
    echo -e "${YELLOW}警告: 客户端 ${CLIENT_NAME} 已存在${NC}"
    read -p "是否重新生成？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 0
    fi
fi

# 检查客户端数量
CLIENT_COUNT=$(ls -1 clients/*.conf 2>/dev/null | wc -l | tr -d ' ')
if [ $CLIENT_COUNT -ge $MAX_CLIENTS ] && [ ! -f "clients/${CLIENT_NAME}.conf" ]; then
    echo -e "${RED}错误: 已达到最大客户端数量 ($MAX_CLIENTS)${NC}"
    exit 1
fi

echo -e "${GREEN}为设备 '${CLIENT_NAME}' 生成配置...${NC}"

# 分配客户端 IP（从 10.8.0.2 开始）
CLIENT_IP="10.8.0.$((CLIENT_COUNT + 2))"

echo -e "客户端 IP: ${YELLOW}${CLIENT_IP}${NC}"

# 在服务器上生成客户端密钥对
echo -e "\n${GREEN}[1/4] 生成客户端密钥对...${NC}"
CLIENT_KEYS=$(ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << ENDSSH
    cd /etc/wireguard
    CLIENT_PRIVATE=\$(wg genkey)
    CLIENT_PUBLIC=\$(echo "\$CLIENT_PRIVATE" | wg pubkey)
    echo "CLIENT_PRIVATE_KEY=\$CLIENT_PRIVATE"
    echo "CLIENT_PUBLIC_KEY=\$CLIENT_PUBLIC"
ENDSSH
)

eval "$CLIENT_KEYS"

# 读取服务器公钥
SERVER_PUBLIC_KEY=$(cat config/server_public.key)

echo -e "\n${GREEN}[2/4] 生成客户端配置文件...${NC}"
# 使用模板生成配置
cat config/client.conf.template | \
    sed "s|CLIENT_PRIVATE_KEY|$CLIENT_PRIVATE_KEY|g" | \
    sed "s|CLIENT_IP|$CLIENT_IP|g" | \
    sed "s|SERVER_PUBLIC_KEY|$SERVER_PUBLIC_KEY|g" | \
    sed "s|SERVER_IP|$SERVER_IP|g" | \
    sed "s|SERVER_PORT|$SERVER_PORT|g" \
    > "clients/${CLIENT_NAME}.conf"

echo -e "配置文件已生成: ${YELLOW}clients/${CLIENT_NAME}.conf${NC}"

echo -e "\n${GREEN}[3/4] 添加客户端到服务器...${NC}"
# 将客户端添加到服务器配置
ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << ENDSSH
    # 添加 Peer 配置
    cat >> /etc/wireguard/wg0.conf << EOF

# Client: ${CLIENT_NAME}
[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${CLIENT_IP}/32
EOF
    
    # 重启 WireGuard
    wg syncconf wg0 <(wg-quick strip wg0)
    
    echo "客户端已添加到服务器"
ENDSSH

echo -e "\n${GREEN}[4/4] 生成二维码...${NC}"
# 生成二维码（用于移动设备）
qrencode -t ansiutf8 < "clients/${CLIENT_NAME}.conf"
qrencode -t png -o "clients/${CLIENT_NAME}.png" < "clients/${CLIENT_NAME}.conf"

echo -e "\n二维码已保存: ${YELLOW}clients/${CLIENT_NAME}.png${NC}"

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}客户端配置完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "配置文件: ${YELLOW}clients/${CLIENT_NAME}.conf${NC}"
echo -e "二维码: ${YELLOW}clients/${CLIENT_NAME}.png${NC}"
echo ""
echo -e "使用方法:"
echo -e "1. ${YELLOW}移动设备${NC}: 使用 WireGuard App 扫描上方二维码"
echo -e "2. ${YELLOW}电脑${NC}: 导入 clients/${CLIENT_NAME}.conf 到 WireGuard 客户端"
echo ""
